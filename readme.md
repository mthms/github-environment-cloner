
# Clone GitHub Environment Variables Script

[![GitHub stars](https://img.shields.io/github/stars/<your-username>/<repository-name>?style=social)](https://github.com/<your-username>/<repository-name>/stargazers)

**`clone-github-environment-variables.sh`** is a lightweight bash script designed to **duplicate GitHub environment variables** from one environment to another within the same repository. This script is perfect for developers and DevOps engineers looking to streamline environment setup, synchronize configurations, or manage multiple environments efficiently.

---

## 🚀 Features

- **Effortless Cloning**: Automatically duplicates all environment variables from a source environment to a target environment.
- **Validation**: Ensures variable names are valid and skips empty values to avoid errors.
- **Customizable**: Works with any GitHub repository by simply specifying the source and target environments.
- **Efficient**: Leverages GitHub CLI (`gh`) and `jq` for seamless processing.

---

## 🛠️ Prerequisites

Before using the script, ensure the following tools are installed:
1. **GitHub CLI (`gh`)**: [Installation Guide](https://cli.github.com/)
2. **`jq` JSON Processor**: [Installation Guide](https://stedolan.github.io/jq/)

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
   ```bash
   ./clone-github-environment-variables.sh <source_env> <target_env> <repo>
   ```
   - **`<source_env>`**: Name of the environment to clone from (e.g., `staging`).
   - **`<target_env>`**: Name of the environment to clone to (e.g., `production`).
   - **`<repo>`**: GitHub repository in `owner/repo` format (e.g., `your-username/your-repo`).

   **Example**:
   ```bash
   ./clone-github-environment-variables.sh integration production your-username/your-repo
   ```

4. **Verify the Changes**:
   Check the target environment in your GitHub repository to ensure variables have been cloned successfully.

---

## 💡 Use Cases

- **Environment Replication**: Clone environment variables from staging to production to ensure consistent deployments.
- **Configuration Synchronization**: Quickly sync variables across multiple GitHub environments.
- **DevOps Automation**: Save time by automating the environment setup process.

---

## 🌟 Benefits of Using This Script

- **Boost Productivity**: Eliminate manual effort and reduce human error during environment configuration.
- **Scalable**: Manage multiple environments efficiently within large repositories.
- **SEO Keywords Included**: Clone, duplicate, GitHub, environment variables, automate, synchronize.

---

## ❓ Troubleshooting

- **Error: `gh` command not found**: Ensure GitHub CLI is installed and authenticated with your account.
- **Empty or Missing Variables**: The script skips variables with empty values. Verify the source environment's variables.
- **Permission Denied**: Ensure you have write access to the target environment in the repository.

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

## 🏷️ Tags

`GitHub` `environment variables` `clone` `automation` `DevOps` `synchronize` `bash script`
