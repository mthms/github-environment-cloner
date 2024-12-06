#!/bin/bash

# Clone Environment Variables Script
# Author: Mohamed Sharaf
# License: MIT License
# For more details, visit: https://opensource.org/licenses/MIT
#
# You are free to use, modify, and share this script, provided the original
# author is credited and this notice is included in all copies.

# Check dependencies
command -v gh >/dev/null 2>&1 || { echo "gh CLI is not installed. Aborting."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is not installed. Aborting."; exit 1; }

# Usage instructions
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo "Usage: $0 <source_env> <target_env> <repo>"
  echo "Example: $0 integration prod-clone Breadfast/QA_Automation_Framework"
  exit 0
fi

# Script parameters
SOURCE_ENV="${1:?Source environment required}"
TARGET_ENV="${2:?Target environment required}"
REPO="${3:?Repository required}"

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
