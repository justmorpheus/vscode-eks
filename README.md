
# VSCode Code-server Deployment for Kubernetes Lab

This repository contains scripts to deploy infrastructure for a VSCode server on AWS EKS using Terraform.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Deployment](#deployment)
- [TL;DR](#tldr)
- [License](#license)
- [Credits](#credits)

## Prerequisites

Before running the `deploy.sh` script, ensure that the following tools are installed on your system:

- Git
- AWS CLI
- Terraform

### Install Git

#### Ubuntu/Debian

```bash
sudo apt update
sudo apt install -y git
```

#### Amazon Linux 2

```bash
sudo yum install -y git
```

#### CentOS/RHEL

```bash
sudo yum install -y git
```

### Install AWS CLI and Terraform

These tools will be installed automatically by the `deploy.sh` script if they are not already installed on your system.

## Setup

1. **Clone the Repository**

    ```bash
    git clone https://github.com/kubernetesvillage/vscode-eks.git
    cd vscode-eks
    ```

2. **Configure AWS CLI**

    Ensure that your AWS CLI is configured with the necessary credentials.

    ```bash
    aws configure
    ```

## Deployment

Run the `deploy.sh` script to deploy the infrastructure.

```bash
./deploy.sh --region <your-region>
```

Replace `<your-region>` with your desired AWS region. If no region is provided, the script will default to `us-east-1`.

## TL;DR

1. **Install Git**: Ensure Git is installed on your system.
2. **Clone Repository**: Clone the `vscode-eks` repository.
3. **Configure AWS CLI**: Run `aws configure` to set up your AWS credentials.
4. **Run Script**: Navigate to the repository directory and run the `deploy.sh` script with the desired AWS region.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Credits
- Thanks to [coder team](https://github.com/coder/deploy-code-server)


This project is maintained by the Kubernetes Village team. Contributions are welcome!

For more information, visit our [GitHub page](https://github.com/kubernetesvillage).
