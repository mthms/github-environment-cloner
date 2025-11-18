#!/bin/bash

# Clone Environment Variables and Secrets Script
# Author: Mohamed Sharaf
# License: MIT License
# For more details, visit: https://opensource.org/licenses/MIT
#
# You are free to use, modify, and share this script, provided the original
# author is credited and this notice is included in all copies.

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
  if ! command -v python3 >/dev/null 2>&1; then
    warnings+=("python3 (required for cloning secrets)")
  else
    # Check if PyNaCl is available (only if python3 exists)
    if ! python3 -c "import nacl" >/dev/null 2>&1; then
      warnings+=("PyNaCl library (required for cloning secrets - install with: pip3 install pynacl)")
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
      break
      ;;
  esac
done

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
  secrets=$(gh api --paginate repos/$REPO/environments/$SOURCE_ENV/secrets 2>/dev/null | jq -s '[.[] | .secrets[]]')
  
  if [[ -z "$secrets" || "$secrets" == "[]" ]]; then
    echo "No secrets found in $SOURCE_ENV environment."
    return
  fi
  
  secret_count=$(echo "$secrets" | jq 'length')
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
      echo "Note: Cloning with empty value (you can update it later in GitHub UI)"
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
      
      # Check if Python is available
      if command -v python3 >/dev/null 2>&1; then
        # Try to encrypt using Python with PyNaCl
        # Use a temp file to pass the secret value safely (avoids shell escaping issues)
        local secret_temp=$(mktemp)
        echo -n "$secret_value" > "$secret_temp"
        
        encrypted_value=$(python3 <<EOF
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
          
          if [[ $? -eq 0 ]]; then
            echo "✓ Added secret $name to $TARGET_ENV environment."
          else
            echo "✗ Error: Failed to add secret $name. Response: $response"
          fi
        else
          echo "✗ Error: PyNaCl library not available. Install it with: pip3 install pynacl"
          echo "  Or set the secret manually in GitHub UI."
        fi
      else
        echo "✗ Error: Python3 not found. Cannot encrypt secret."
        echo "  Please install Python3 and PyNaCl (pip3 install pynacl) to clone secrets automatically."
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
fi

echo ""
echo "=========================================="
echo "Cloning completed!"
echo "=========================================="
