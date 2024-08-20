
# VSCode Code-server Deployment for Kubernetes Lab

This repository contains scripts to deploy VSCode server using Terraform in EC2.

> As cloud9 is deprecated, for labs and learning this script has been created.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Deployment](#deployment)
- [TL;DR](#tldr)
- [License](#license)
- [Disclaimer](#disclaimer)
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

2. **Pre-Deployment**

   > Run the pre-deploy.sh script to ensure all necessary dependencies (AWS CLI, Terraform, etc.) are installed.
   ```bash
    bash pre-deploy.sh
    ```
3. **Configure AWS CLI**

    > Ensure that your AWS CLI is configured with the necessary credentials.

    ```bash
    aws configure
    ```

## Deployment

- Run the `deploy.sh` script to deploy the infrastructure.

```bash
bash deploy.sh --region <your-region>
```

Replace `<your-region>` with your desired AWS region. If no region is provided, the script will default to `us-east-1`.

> Note: Currently supported regions are 'us-east-1' and 'us-west-2'.

- Open the IP address in the browser to access the vscode and enter the password shown in the output.


## TL;DR

1. **Install Git**: Ensure Git is installed on your system.
2. **Clone Repository**: Clone the `vscode-eks` repository.
3. **Configure AWS CLI**: Run `aws configure` to set up your AWS credentials.
4. **Run Script**: Navigate to the repository directory and run the `deploy.sh` script with the desired AWS region.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Disclaimer
- The views expressed are solely those of the speaker and do not reflect the opinions of the employer. Use at your own risk.
- The password is temporary and regenerates each time the script runs.
- Do not push this code while the VS Code server is running.
- The author is not responsible for any charges or security issues that may arise. This is shared under the MIT 0 license. 

## Credits
- Thanks to [coder team](https://github.com/coder/deploy-code-server)
- Thanks to [AWS eks-workshop-v2](https://github.com/aws-samples/eks-workshop-v2/blob/main/lab/scripts/installer.sh)


This project is maintained by the Kubernetes Village team. Contributions are welcome!

For more information, visit our [GitHub page](https://github.com/kubernetesvillage).
