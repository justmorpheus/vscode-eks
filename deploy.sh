#!/bin/bash

echo "====================================================================="
echo "    VSCode Deployment Script By peachycloudsecurity                  "
echo "====================================================================="
echo "Usage: ./deploy.sh [--region <region>]"
echo ""
echo "If no region is selected, the script will default to 'us-east-1'."
echo "Supported regions are 'us-east-1' and 'us-west-2'."
echo "Note: AWS CLI should be configured before running this script."
echo "====================================================================="
echo ""

echo "Vscode deployment in progress.."
echo ""

# Display the disclaimer and prompt the user to accept it
echo "====================================================================="
echo "Disclaimer: The views expressed are solely those of the speaker and do not reflect the opinions of the employer. Use at your own risk."
echo "Note: The password is temporary and regenerates each time the script runs."
echo "Warning: Do not push this code while the VS Code server is running."
echo "Liability: The author is not responsible for any charges or security issues that may arise. This is shared under the MIT 0 license. "
echo "====================================================================="
echo ""


# Prompt the user to confirm if they want to accept the disclaimer and continue
read -p "Do you accept the disclaimer and want to continue with the deployment? (Y/N): " confirm
case $confirm in
    [Yy]* ) 
        echo "Disclaimer accepted. Continuing with the deployment...";;
    [Nn]* ) 
        echo "Deployment aborted."
        exit 0;;
    * ) 
        echo "Invalid input. Please enter Y or N."
        exit 1;;
esac


# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS CLI is not configured. Please configure the AWS CLI with valid credentials and try again."
    exit 1
else
    echo "AWS CLI is configured. Please ensure you have admin privileges to deploy the infrastructure."
fi

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

# Ensure the selected region is either us-east-1 or us-west-2
if [[ "$AWS_REGION" != "us-east-1" && "$AWS_REGION" != "us-west-2" ]]; then
    echo "Error: Unsupported region. Only us-east-1 and us-west-2 are supported."
    exit 1
fi

# Select AMI based on region
if [[ "$AWS_REGION" == "us-west-2" ]]; then
    AMI="ami-0323ead22d6752894"
else
    AMI="ami-01fccab91b456acc2"
fi

# Check if the user is inside the vscode-eks directory
if [[ ! "$(basename $PWD)" == "vscode-eks" ]]; then
    echo "If vscode-eks not present, run git clone https://github.com/kubernetesvillage/vscode-eks"
    echo "Please navigate to the vscode-eks directory before running this script."
    exit 1
fi

# Default region setting
echo "Using AWS region: $AWS_REGION"

# Step 1: Set AWS account ID and region
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION="${AWS_REGION}"

# Step 2: Generate a random password and save it to a file
PASSWORD="password_$(openssl rand -hex 12)"
echo "Generated password: $PASSWORD"
echo $PASSWORD > terraform/vscode_password.txt

# Step 3: Replace the placeholder AMI and password in file.sh
sed -i "s|AMI=.*|AMI=$AMI|g" terraform/file.sh
sed -i "s|PASSWORD=.*|PASSWORD=$PASSWORD\" \\\\|" terraform/file.sh

# Step 4: Initialize Terraform
terraform -chdir=terraform/ init -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform initialization failed"
  exit 1
fi

# Step 5: Apply Terraform configuration with the specified region and AMI
terraform -chdir=terraform/ apply -var="region=$AWS_REGION" -var="ami=$AMI" -auto-approve -lock=false
if [ $? -ne 0 ]; then
  echo "Terraform apply failed"
  exit 1
fi

# Step 6: Save Terraform output to a file
terraform -chdir=terraform/ output -json > terraform_output.json

# Show final message
echo "Your vscode password is $(cat terraform/vscode_password.txt)"
echo "Deployment Complete"
