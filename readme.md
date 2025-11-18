
# Clone GitHub Environment Variables and Secrets Script

**`clone-github-environment-variables.sh`** is a lightweight bash script designed to **duplicate GitHub environment variables and secrets** from one environment to another within the same repository. This script is perfect for developers and DevOps engineers looking to streamline environment setup, synchronize configurations, or manage multiple environments efficiently.

---

## 🚀 Features

- **Effortless Cloning**: Automatically duplicates all environment variables from a source environment to a target environment.
- **Secrets Support**: Clone environment secrets with multiple options (interactive, file-based, or empty values).
- **Template Generation**: Generate JSON templates with secret names for easy filling and automation.
- **Validation**: Ensures variable and secret names are valid and skips empty values to avoid errors.
- **Customizable**: Works with any GitHub repository by simply specifying the source and target environments.
- **Efficient**: Leverages GitHub CLI (`gh`), `jq`, and Python3 with PyNaCl for seamless processing.
- **Security**: Includes `.gitignore` to prevent accidentally committing secret files.

---

## 🛠️ Prerequisites

### Required Dependencies
Before using the script, ensure the following tools are installed:
1. **GitHub CLI (`gh`)**: [Installation Guide](https://cli.github.com/)
2. **`jq` JSON Processor**: [Installation Guide](https://stedolan.github.io/jq/)

### Optional Dependencies (for Secrets Cloning)
To clone secrets, you'll also need:
3. **Python 3**: Usually pre-installed on macOS/Linux. [Installation Guide](https://www.python.org/downloads/)
4. **PyNaCl Library**: Install with `pip3 install pynacl`

> **Note**: The script will check all dependencies at startup and provide helpful error messages if anything is missing. Variables can be cloned without Python3/PyNaCl, but secrets cloning requires these dependencies.

---

## 📖 How to Use

1. **Clone or Download the Repository**:
   ```bash
   git clone https://github.com/mthms/github-environment-cloner.git
   cd github-environment-cloner
   ```

2. **Make the Script Executable**:
   ```bash
   chmod +x clone-github-environment-variables.sh
   ```

3. **Run the Script**:
   Provide the source environment, target environment, and repository as arguments.

### Basic Usage (Variables Only)

Clone only environment variables (secrets are not cloned):
```bash
./clone-github-environment-variables.sh <source_env> <target_env> <repo>
```

**Parameters**:
- **`<source_env>`**: Name of the environment to clone from (e.g., `integration`, `staging`).
- **`<target_env>`**: Name of the environment to clone to (e.g., `production`).
- **`<repo>`**: GitHub repository in `owner/repo` format (e.g., `your-username/your-repo`).

**Example**:
```bash
./clone-github-environment-variables.sh integration production your-username/your-repo
```

### Command-Line Options

The script supports several options for cloning secrets:

| Option | Description |
|--------|-------------|
| `--with-secrets` | Clone secrets interactively (prompts for each secret value) |
| `--secrets-file FILE` | Clone secrets from a JSON file containing secret values |
| `--list-secrets-only` | Only list secret names without cloning them |
| `--generate-secrets-template FILE` | Generate a JSON template file with all secret names (empty values) |
| `--clone-secrets-empty` | Clone secrets with empty values (creates structure only) |
| `-h, --help` | Show help message with all options |

### Usage Examples

#### 1. Clone Variables Only (Default)
```bash
./clone-github-environment-variables.sh integration production owner/repo
```

#### 2. Clone Variables and Secrets (Interactive)
The script will prompt you to enter each secret value (input is hidden):
```bash
./clone-github-environment-variables.sh integration production owner/repo --with-secrets
```

#### 3. Generate Secrets Template
Create a JSON template file with all secret names from the source environment:
```bash
./clone-github-environment-variables.sh integration production owner/repo --generate-secrets-template secrets-template.json
```

This creates a file like:
```json
{
  "DATABASE_PASSWORD": "",
  "API_KEY": "",
  "JWT_SECRET": ""
}
```

Then fill in the values and use:
```bash
./clone-github-environment-variables.sh integration production owner/repo --secrets-file secrets-template.json
```

#### 4. Clone Secrets from JSON File
```bash
./clone-github-environment-variables.sh integration production owner/repo --secrets-file secrets.json
```

**Secrets File Format** (`secrets.json`):
```json
{
  "DATABASE_PASSWORD": "my-secret-password",
  "API_KEY": "sk-1234567890",
  "JWT_SECRET": "my-jwt-secret"
}
```

#### 5. List Secret Names Only
See what secrets exist in the source environment without cloning:
```bash
./clone-github-environment-variables.sh integration production owner/repo --list-secrets-only
```

#### 6. Clone Secrets with Empty Values
Create the secret structure in the target environment with empty values (you can update them later in GitHub UI):
```bash
./clone-github-environment-variables.sh integration production owner/repo --clone-secrets-empty
```

> **Note**: GitHub may reject empty secrets. If this happens, you'll see an error and can update the values manually in the GitHub UI.

### Important Notes

- **Variables are always cloned** regardless of which secret options you use.
- **Secret values cannot be read from GitHub** (they're write-only), so you must provide the values via interactive prompts or a JSON file.
- **JSON files are ignored by git** (see `.gitignore`) to prevent accidentally committing secrets.

---

## 💡 Use Cases

- **Environment Replication**: Clone environment variables and secrets from staging to production to ensure consistent deployments.
- **Configuration Synchronization**: Quickly sync variables and secrets across multiple GitHub environments.
- **DevOps Automation**: Save time by automating the environment setup process.
- **Template-Based Setup**: Generate templates for new environments and fill them programmatically.
- **Environment Migration**: Easily migrate configurations when setting up new environments or repositories.

---

## 🌟 Benefits of Using This Script

- **Boost Productivity**: Eliminate manual effort and reduce human error during environment configuration.
- **Scalable**: Manage multiple environments efficiently within large repositories.
- **SEO Keywords Included**: Clone, duplicate, GitHub, environment variables, automate, synchronize.

---

## ❓ Troubleshooting

### Dependency Issues
- **Error: `gh` command not found**: Ensure GitHub CLI is installed and authenticated with your account. Run `gh auth login` if needed.
- **Error: `jq` is not installed**: Install jq using your package manager (e.g., `brew install jq` on macOS, `apt-get install jq` on Ubuntu).
- **Warning: PyNaCl not available**: Install it with `pip3 install pynacl`. This is only needed for cloning secrets.

### Runtime Issues
- **Empty or Missing Variables**: The script skips variables with empty values. Verify the source environment's variables.
- **Permission Denied**: Ensure you have write access to the target environment in the repository.
- **Secret Cloning Fails**: 
  - Make sure Python3 and PyNaCl are installed if using `--with-secrets` or `--secrets-file`.
  - Verify the target environment exists before cloning.
  - Check that you have proper permissions to create secrets in the target environment.
- **Empty Secrets Rejected**: GitHub may reject empty secrets. Use `--with-secrets` or `--secrets-file` to provide actual values.

### Security Best Practices
- **Never commit secret files**: The `.gitignore` file is configured to ignore all JSON files. Never override this for files containing secrets.
- **Use secure methods**: Prefer interactive prompts (`--with-secrets`) over files when possible, or ensure secret files are properly secured.
- **Clean up temporary files**: If you create secret template files, delete them after use or ensure they're in `.gitignore`.

---

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue to suggest improvements.

---

## 📧 Support

For questions or support, feel free to reach out to [Mohamed Sharaf](mailto:mohamed.sharaf1@proton.me).

---

## 🔒 Security

This repository includes a `.gitignore` file that ignores all JSON files to prevent accidentally committing secrets. Always:

- Review files before committing
- Never commit files containing actual secret values
- Use interactive mode (`--with-secrets`) when possible
- Delete or securely store secret template files after use

## 🏷️ Tags

`GitHub` `environment variables` `secrets` `clone` `automation` `DevOps` `synchronize` `bash script` `CI/CD`
