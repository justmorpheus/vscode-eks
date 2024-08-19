#!/bin/bash

echo "====================================================================="
echo "    VSCode Pre-deployment Script By peachycloudsecurity                  "
echo "====================================================================="
echo ""
echo "Initializing the setup of required dependencies."
echo ""
echo ""




# Function to install Terraform and AWS CLI on Debian-based systems
install_terraform_awscli_debian() {
  sudo apt update -y
  sudo apt-get update && sudo apt-get install -y gnupg software-properties-common jq less 
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
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws
  if [ $? -ne 0 ]; then
    echo "Failed to install AWS CLI and other dependencies"
    exit 1
  fi
}

# Function to install Terraform and AWS CLI on yum-based systems
install_terraform_awscli_yum() {
  sudo yum install -y yum-utils jq less
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
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip
  sudo ./aws/install
  rm -rf awscliv2.zip aws
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

# Show final message
echo "Pre-deployment complete. Please configure your AWS CLI with 'aws configure' if not done already."
echo "After configuring AWS CLI, run 'deploy.sh' to proceed with deployment."
