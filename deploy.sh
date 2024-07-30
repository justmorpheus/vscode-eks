#!/bin/bash

# Parse command line arguments for region
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --region) AWS_REGION="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Set default region if not provided
AWS_REGION="${AWS_REGION:-us-east-1}"

# Warning to configure AWS credentials
echo "WARNING: Please ensure that your AWS credentials are configured before proceeding."
echo "Run 'aws configure' to set up your AWS credentials."
read -p "Press Enter to continue after configuring your AWS credentials..."

# Check if the user is inside the vscode-eks directory
if [[ ! "$(basename $PWD)" == "vscode-eks" ]]; then
    echo "If vscode-eks not present, run git clone ttps://github.com/kubernetesvillage/vscode-eks"
    echo "Please navigate to the vscode-eks directory before running this script."
    exit 1
fi

# Function to install Terraform and AWS CLI on Debian-based systems
install_terraform_awscli_debian() {
  sudo apt update -y
  sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
  if [ $? -ne 0 ]; then
    echo "Failed to update apt repositories or install gnupg/software-properties-common"
    exit 1
  fi
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
  gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update
  sudo apt-get install terraform -y
  if [ $? -ne 0 ]; then
    echo "Failed to install Terraform"
    exit 1
  fi
  sudo apt install awscli -y
  if [ $? -ne 0 ]; then
    echo "Failed to install AWS CLI"
    exit 1
  fi
}

# Function to install Terraform and AWS CLI on yum-based systems
install_terraform_awscli_yum() {
  sudo yum install -y yum-utils
  if [ $? -ne 0 ]; then
    echo "Failed to install yum-utils"
    exit 1
  fi
  sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
  sudo yum -y install terraform
  if [ $? -ne 0 ]; then
    echo "Failed to install Terraform"
    exit 1
  fi
  sudo yum install -y awscli
  if [ $? -ne 0 ]; then
    echo "Failed to install AWS CLI"
    exit 1
  fi
}

# Function to check and install Terraform and AWS CLI if not already installed
check_and_install_terraform_awscli() {
  if ! command -v terraform &> /dev/null
  then
    echo "Terraform not found, installing..."
    if [ -f /etc/debian_version ]; then
      echo "Detected Debian-based system"
      install_terraform_awscli_debian
    elif [ -f /etc/redhat-release ]; then
      echo "Detected RedHat-based system"
      install_terraform_awscli_yum
    elif [ -f /etc/system-release ] && grep -q "Amazon Linux" /etc/system-release; then
      echo "Detected Amazon Linux system"
      install_terraform_awscli_yum
    else
      echo "Unsupported operating system"
      exit 1
    fi
  else
    echo "Terraform is already installed"
  fi

  if ! command -v aws &> /dev/null
  then
    echo "AWS CLI not found, installing..."
    if [ -f /etc/debian_version ]; then
      echo "Detected Debian-based system"
      install_terraform_awscli_debian
    elif [ -f /etc/redhat-release ]; then
      echo "Detected RedHat-based system"
      install_terraform_awscli_yum
    elif [ -f /etc/system-release ] && grep -q "Amazon Linux" /etc/system-release; then
      echo "Detected Amazon Linux system"
      install_terraform_awscli_yum
    else
      echo "Unsupported operating system"
      exit 1
    fi
  else
    echo "AWS CLI is already installed"
  fi
}

# Run the check and install function
check_and_install_terraform_awscli

# Default region setting
echo "Using AWS region: $AWS_REGION"

# Step 1: Set AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="${AWS_REGION}"

# Step 6: Replace the placeholder password in file.sh
sed -i "s|PASSWORD=.*|PASSWORD=$PASSWORD\" \\\\|" terraform/file.sh

# Step 2: Initialize Terraform
terraform -chdir=terraform/ init -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed"
  exit 1
fi

# Step 3: Apply Terraform configuration
terraform -chdir=terraform/ apply -auto-approve -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform apply failed"
  exit 1
fi

# Step 4: Save Terraform output to a file
terraform -chdir=terraform/ output -json > terraform_output.json

# Step 5: Generate a random password and save it to a file
PASSWORD="password_$(openssl rand -hex 12)"
echo "Generated password: $PASSWORD"
echo $PASSWORD > terraform/vscode_password.txt


# Show final message
echo "Your vscode password is $(cat terraform/vscode_password.txt)"

echo "Deployment Complete"
