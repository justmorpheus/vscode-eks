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

# Check if terraform_output.json exists
if [[ ! -f terraform_output.json ]]; then
    echo "Error: terraform_output.json not found. Ensure the infrastructure was deployed and the file exists."
    exit 1
fi

# Extract the region from terraform_output.json to check against AWS_REGION
DEPLOYED_REGION=$(jq -r '.region.value // empty' terraform_output.json)
if [[ -z "$DEPLOYED_REGION" ]]; then
    echo "Warning: Region information not found in terraform_output.json. Proceeding without region check."
else
    if [[ "$DEPLOYED_REGION" != "$AWS_REGION" ]]; then
        echo "Error: Mismatch between specified region ($AWS_REGION) and deployed region ($DEPLOYED_REGION)."
        echo "Please run the script with the correct region."
        exit 1
    fi
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
  cleanup
  exit 1
fi

# Step 3: Destroy Terraform-managed infrastructure
terraform -chdir=terraform/ destroy -var="region=$AWS_REGION" -auto-approve -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform destroy failed"
  cleanup
  exit 1
fi

# Step 4: Cleanup
cleanup() {
    # Remove .terraform directory and related files
    rm -rf terraform/.terraform \
           terraform/.terraform.lock.hcl \
           terraform/terraform.tfstate \
           terraform/vscode_password.txt \
           terraform/terraform.tfstate.backup \
           terraform_output.json
           
    # Revert the placeholder password in file.sh
    sed -i "s|PASSWORD=.*|PASSWORD=ReplaceWithYourStrongPassword\" \\\\|" terraform/file.sh

    echo "Cleanup completed."
}

# Always perform cleanup
cleanup

# Show final message
echo "Infrastructure destroyed successfully"
