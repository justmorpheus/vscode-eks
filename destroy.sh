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

# Check if the user is inside the vscode-eks directory
if [[ ! "$(basename $PWD)" == "vscode-eks" ]]; then
    echo "Please navigate to the vscode-eks directory before running this script."
    exit 1
fi

# Default region setting
echo "Using AWS region: $AWS_REGION"

# Step 1: Set AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="${AWS_REGION}"

# Step 2: Initialize Terraform (in case it's not initialized)
terraform -chdir=terraform/ init -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed"
  exit 1
fi

# Step 3: Destroy Terraform-managed infrastructure
terraform -chdir=terraform/ destroy -auto-approve -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform destroy failed"
  exit 1
fi

# Step 4: Remove .terraform directory and .terraform.lock.hcl file
rm -rf terraform/.terraform \
       terraform/.terraform.lock.hcl \
       terraform/terraform.tfstate \
       terraform/vscode_password.txt \
       terraform/terraform.tfstate.backup \
       terraform_output.json
       

# Revert the placeholder password in file.sh
sed -i "s|PASSWORD=.*|PASSWORD=ReplaceWithYourStrongPassword\" \\\\|" terraform/file.sh



# Show final message
echo "Infrastructure destroyed successfully"
