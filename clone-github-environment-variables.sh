#!/bin/bash

# Clone Environment Variables and Secrets Script
# Author: Mohamed Sharaf
# License: MIT License
# For more details, visit: https://opensource.org/licenses/MIT
#
# You are free to use, modify, and share this script, provided the original
# author is credited and this notice is included in all copies.

# Function to find Python executable (check venv first, then system)
find_python() {
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local venv_python="$script_dir/venv/bin/python3"
  
  # Check if venv exists and has Python
  if [[ -f "$venv_python" ]]; then
    echo "$venv_python"
    return 0
  fi
  
  # Fall back to system Python
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
    return 0
  fi
  
  return 1
}

# Function to check dependencies
check_dependencies() {
  local missing_deps=()
  local warnings=()
  
  # Required dependencies
  if ! command -v gh >/dev/null 2>&1; then
    missing_deps+=("gh (GitHub CLI)")
  fi
  
  if ! command -v jq >/dev/null 2>&1; then
    missing_deps+=("jq (JSON processor)")
  fi
  
  # Optional but recommended for secrets cloning
  PYTHON_CMD=$(find_python)
  if [[ -z "$PYTHON_CMD" ]]; then
    warnings+=("python3 (required for cloning secrets)")
  else
    # Check if PyNaCl is available
    if ! "$PYTHON_CMD" -c "import nacl" >/dev/null 2>&1; then
      local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      if [[ -d "$script_dir/venv" ]]; then
        warnings+=("PyNaCl library not found in virtual environment. Run: ./setup.sh")
      else
        warnings+=("PyNaCl library (required for cloning secrets - run: ./setup.sh or install with: pip3 install pynacl)")
      fi
    fi
  fi
  
  # Report missing required dependencies
  if [[ ${#missing_deps[@]} -gt 0 ]]; then
    echo "Error: Missing required dependencies:"
    for dep in "${missing_deps[@]}"; do
      echo "  - $dep"
    done
    echo ""
    echo "Installation instructions:"
    echo "  - GitHub CLI: https://cli.github.com/"
    echo "  - jq: https://stedolan.github.io/jq/download/"
    exit 1
  fi
  
  # Report optional dependencies as warnings
  if [[ ${#warnings[@]} -gt 0 ]]; then
    echo "Warning: Optional dependencies not found (needed for cloning secrets):"
    for warning in "${warnings[@]}"; do
      echo "  - $warning"
    done
    echo ""
  fi
}

# Check all dependencies
check_dependencies

# Function to display usage
show_usage() {
  echo "Usage: $0 <source_env> <target_env> <repo> [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --with-secrets                  Clone secrets (will prompt for values interactively)"
  echo "  --secrets-file FILE             Path to JSON file containing secret values"
  echo "  --list-secrets-only             Only list secret names without cloning them"
  echo "  --generate-secrets-template FILE Generate JSON template file with secret names (empty values)"
  echo "  --clone-secrets-empty            Clone secrets with empty values"
  echo "  -h, --help                      Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 integration production owner/repo"
  echo "  $0 integration production owner/repo --with-secrets"
  echo "  $0 integration production owner/repo --secrets-file secrets.json"
  echo "  $0 integration production owner/repo --list-secrets-only"
  echo "  $0 integration production owner/repo --generate-secrets-template secrets-template.json"
  echo "  $0 integration production owner/repo --clone-secrets-empty"
  echo ""
  echo "Secrets File Format (JSON):"
  echo '  {'
  echo '    "SECRET_NAME_1": "secret_value_1",'
  echo '    "SECRET_NAME_2": "secret_value_2"'
  echo '  }'
}

# Parse arguments
CLONE_SECRETS=false
SECRETS_FILE=""
LIST_SECRETS_ONLY=false
GENERATE_TEMPLATE=false
TEMPLATE_FILE=""
CLONE_SECRETS_EMPTY=false

# First, extract positional arguments (they can be anywhere)
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_usage
      exit 0
      ;;
    --with-secrets)
      CLONE_SECRETS=true
      shift
      ;;
    --secrets-file)
      SECRETS_FILE="$2"
      CLONE_SECRETS=true
      shift 2
      ;;
    --list-secrets-only)
      LIST_SECRETS_ONLY=true
      CLONE_SECRETS=true
      shift
      ;;
    --generate-secrets-template)
      GENERATE_TEMPLATE=true
      TEMPLATE_FILE="$2"
      CLONE_SECRETS=true
      shift 2
      ;;
    --clone-secrets-empty)
      CLONE_SECRETS_EMPTY=true
      CLONE_SECRETS=true
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      show_usage
      exit 1
      ;;
    *)
      # Collect positional arguments
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

# Set positional arguments
set -- "${POSITIONAL_ARGS[@]}"

# Script parameters
SOURCE_ENV="${1:?Source environment required}"
TARGET_ENV="${2:?Target environment required}"
REPO="${3:?Repository required}"

# Function to read secret value securely
read_secret() {
  local secret_name=$1
  echo -n "Enter value for secret '$secret_name' (input will be hidden): " >&2
  read -s secret_value
  echo >&2
  echo "$secret_value"
}

# Function to clone secrets
clone_secrets() {
  echo ""
  echo "=========================================="
  echo "Cloning Secrets from $SOURCE_ENV to $TARGET_ENV"
  echo "=========================================="
  
  # Fetch all secrets from source environment
  echo "Fetching secrets from $SOURCE_ENV environment..."
  secrets_response=$(gh api --paginate repos/$REPO/environments/$SOURCE_ENV/secrets 2>&1)
  api_fetch_status=$?
  
  if [[ $api_fetch_status -ne 0 ]]; then
    echo "✗ Error: Failed to fetch secrets from $SOURCE_ENV environment."
    echo "  Response: $secrets_response"
    echo "  Make sure the environment exists and you have proper permissions."
    return 1
  fi
  
  secrets=$(echo "$secrets_response" | jq -s '[.[] | .secrets[]]' 2>/dev/null)
  
  if [[ -z "$secrets" || "$secrets" == "[]" || "$secrets" == "null" ]]; then
    echo "No secrets found in $SOURCE_ENV environment."
    if [[ "$CLONE_SECRETS_EMPTY" == true ]]; then
      echo "Nothing to clone with --clone-secrets-empty option."
    fi
    return
  fi
  
  secret_count=$(echo "$secrets" | jq 'length' 2>/dev/null)
  if [[ -z "$secret_count" || "$secret_count" == "0" ]]; then
    echo "No secrets found in $SOURCE_ENV environment."
    if [[ "$CLONE_SECRETS_EMPTY" == true ]]; then
      echo "Nothing to clone with --clone-secrets-empty option."
    fi
    return
  fi
  
  echo "Found $secret_count secret(s) in $SOURCE_ENV environment."
  echo ""
  
  # If generate template mode, create JSON template and exit
  if [[ "$GENERATE_TEMPLATE" == true ]]; then
    if [[ -z "$TEMPLATE_FILE" ]]; then
      echo "Error: Template file path is required with --generate-secrets-template"
      return 1
    fi
    
    echo "Generating secrets template file: $TEMPLATE_FILE"
    
    # Create JSON object with all secret names and empty string values
    template_json=$(echo "$secrets" | jq -r 'reduce .[] as $secret ({}; . + {($secret.name): ""})')
    
    # Write to file with pretty formatting
    echo "$template_json" | jq '.' > "$TEMPLATE_FILE"
    
    if [[ $? -eq 0 ]]; then
      echo "✓ Template file created successfully: $TEMPLATE_FILE"
      echo "  Please fill in the secret values and use --secrets-file to clone them."
    else
      echo "✗ Error: Failed to create template file"
      return 1
    fi
    return 0
  fi
  
  # If list-only mode, just display and exit
  if [[ "$LIST_SECRETS_ONLY" == true ]]; then
    echo "Secret names in $SOURCE_ENV:"
    echo "$secrets" | jq -r '.[].name' | while IFS= read -r name; do
      echo "  - $name"
    done
    echo ""
    echo "Note: Secret values cannot be read from GitHub. Use --with-secrets or --secrets-file to clone them."
    return
  fi
  
  # Load secrets from file if provided (using temp file to avoid subshell issues)
  local secrets_temp_file=""
  if [[ -n "$SECRETS_FILE" ]]; then
    if [[ ! -f "$SECRETS_FILE" ]]; then
      echo "Error: Secrets file '$SECRETS_FILE' not found."
      return 1
    fi
    echo "Loading secrets from file: $SECRETS_FILE"
    secrets_temp_file=$(mktemp)
    jq -r 'to_entries[] | "\(.key)|\(.value)"' "$SECRETS_FILE" > "$secrets_temp_file"
  fi
  
  # Process each secret
  echo "$secrets" | jq -c '.[]' | while IFS= read -r secret; do
    name=$(echo "$secret" | jq -r '.name')
    
    echo "----------------------------------"
    echo "Processing secret: $name"
    
    # Get secret value
    local secret_value=""
    if [[ "$CLONE_SECRETS_EMPTY" == true ]]; then
      # Use empty value
      secret_value=""
      echo "Note: Cloning secret '$name' with empty value (you can update it later in GitHub UI)"
    elif [[ -n "$SECRETS_FILE" && -n "$secrets_temp_file" ]]; then
      # Use value from file
      secret_value=$(grep "^${name}|" "$secrets_temp_file" 2>/dev/null | cut -d'|' -f2-)
      if [[ -z "$secret_value" ]]; then
        echo "Warning: Secret '$name' not found in secrets file. Skipping."
        continue
      fi
    else
      # Prompt interactively
      secret_value=$(read_secret "$name")
      if [[ -z "$secret_value" && "$CLONE_SECRETS_EMPTY" != true ]]; then
        echo "Skipping secret '$name' due to empty value."
        continue
      fi
    fi
    
    # Validate the secret name
    if [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
      echo "Adding secret: $name"
      
      # Skip encryption if value is empty and we're cloning with empty values
      # Note: GitHub may not accept empty secrets, but we'll try
      if [[ -z "$secret_value" && "$CLONE_SECRETS_EMPTY" == true ]]; then
        echo "Warning: GitHub may not accept empty secrets. Attempting to set empty value..."
        # We still need to encrypt an empty string to make the API call
        secret_value=""
      fi
      
      # Get the public key for encryption
      public_key_response=$(gh api repos/$REPO/environments/$TARGET_ENV/secrets/public-key 2>/dev/null)
      if [[ $? -ne 0 ]]; then
        echo "Error: Failed to get public key for $TARGET_ENV. Make sure the environment exists and you have proper permissions."
        continue
      fi
      
      public_key=$(echo "$public_key_response" | jq -r '.key')
      key_id=$(echo "$public_key_response" | jq -r '.key_id')
      
      # Encrypt the secret using libsodium sealed box (required by GitHub API)
      # Try using Python with PyNaCl if available, otherwise provide instructions
      encrypted_value=""
      
      # Get Python command (venv or system)
      PYTHON_CMD=$(find_python)
      
      # Check if Python is available
      if [[ -n "$PYTHON_CMD" ]]; then
        # Try to encrypt using Python with PyNaCl
        # Use a temp file to pass the secret value safely (avoids shell escaping issues)
        local secret_temp=$(mktemp)
        echo -n "$secret_value" > "$secret_temp"
        
        encrypted_value=$("$PYTHON_CMD" <<EOF
import sys
import base64
try:
    from nacl.public import PublicKey, SealedBox
    from nacl.encoding import Base64Encoder
    
    public_key_b64 = "$public_key"
    
    # Read secret value from file to avoid shell escaping issues
    with open("$secret_temp", "rb") as f:
        secret_value = f.read().decode('utf-8')
    
    # Decode the public key
    public_key_bytes = base64.b64decode(public_key_b64)
    public_key_obj = PublicKey(public_key_bytes)
    
    # Create sealed box and encrypt
    box = SealedBox(public_key_obj)
    encrypted = box.encrypt(secret_value.encode('utf-8'), encoder=Base64Encoder)
    
    print(encrypted.decode('utf-8'))
except ImportError:
    print("", file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print("", file=sys.stderr)
    sys.exit(1)
EOF
)
        
        local encrypt_status=$?
        # Cleanup temp file
        rm -f "$secret_temp"
        
        if [[ -n "$encrypted_value" && $encrypt_status -eq 0 ]]; then
          # Successfully encrypted, now create the secret via API
          response=$(gh api repos/$REPO/environments/$TARGET_ENV/secrets/$name \
            --method PUT \
            -H "Accept: application/vnd.github+json" \
            -f "encrypted_value=$encrypted_value" \
            -f "key_id=$key_id" 2>&1)
          
          api_status=$?
          if [[ $api_status -eq 0 ]]; then
            echo "✓ Added secret $name to $TARGET_ENV environment."
          else
            echo "✗ Error: Failed to add secret $name"
            if [[ -n "$response" ]]; then
              echo "  API Response: $response"
            fi
            if [[ "$CLONE_SECRETS_EMPTY" == true ]]; then
              echo "  Note: GitHub may reject empty secrets. Try using --with-secrets or --secrets-file instead."
            fi
          fi
        else
          local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
          if [[ -d "$script_dir/venv" ]]; then
            echo "✗ Error: PyNaCl library not found in virtual environment."
            echo "  Run: ./setup.sh to install dependencies"
            echo "  Or set the secret manually in GitHub UI."
          else
            echo "✗ Error: PyNaCl library not available."
            echo "  Run: ./setup.sh to create a virtual environment and install dependencies"
            echo "  Or install with: pip3 install pynacl"
            echo "  Or set the secret manually in GitHub UI."
          fi
        fi
      else
        echo "✗ Error: Python3 not found. Cannot encrypt secret."
        echo "  Please install Python3 and run: ./setup.sh to set up dependencies"
        echo "  Or set the secret '$name' manually in GitHub UI."
      fi
    else
      echo "Skipping invalid secret name: $name"
    fi
    echo "----------------------------------"
  done
  
  # Cleanup temp file
  [[ -n "$secrets_temp_file" && -f "$secrets_temp_file" ]] && rm -f "$secrets_temp_file"
}

echo "=========================================="
echo "Cloning Variables from $SOURCE_ENV to $TARGET_ENV"
echo "=========================================="
echo ""

# Fetch all variables from all pages and merge into a single JSON array
variables=$(gh api --paginate repos/$REPO/environments/$SOURCE_ENV/variables | jq -s '[.[] | .variables[]]')

# Process each variable
echo "$variables" | jq -c '.[]' | while IFS= read -r var; do
  name=$(echo "$var" | jq -r '.name')
  value=$(echo "$var" | jq -r '.value')

  # Ensure the value is treated as a string
  value=$(printf '%s' "$value") 

  # Debug: Print the variable name only
  echo "----------------------------------"
  echo "Processing variable: name='$name'"

  # Ensure the value is non-empty
  if [[ -z "$value" ]]; then
    echo "Skipping variable '$name' due to empty value."
    continue
  fi

  # Validate the variable name
  if [[ "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo "Adding variable: $name"
    gh api repos/$REPO/environments/$TARGET_ENV/variables \
      --method POST \
      -H "Accept: application/vnd.github+json" \
      -f "name=$name" \
      -f "value=$value" > /dev/null
    echo "Added variable $name to $TARGET_ENV environment."
  else
    echo "Skipping invalid variable name: $name"
  fi
  echo "----------------------------------"
done

# Clone secrets if requested
if [[ "$CLONE_SECRETS" == true ]]; then
  clone_secrets
else
  echo ""
  echo "Note: Secrets were not cloned. Use --with-secrets, --secrets-file, --clone-secrets-empty, or --generate-secrets-template to clone secrets."
  echo "Debug: CLONE_SECRETS='$CLONE_SECRETS', CLONE_SECRETS_EMPTY='$CLONE_SECRETS_EMPTY'"
fi

echo ""
echo "=========================================="
echo "Cloning completed!"
echo "=========================================="
