#!/bin/bash

# E-Learning Platform - Azure Quick Setup Script
# Usage: bash setup-azure.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

echo "🚀 E-Learning Platform - Azure Setup Script"
echo "=========================================="

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v az >/dev/null 2>&1 || { echo "❌ Azure CLI is required"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform is required"; exit 1; }

# Get subscription ID
echo ""
echo "📱 Available subscriptions:"
az account list --output table --query '[].{Name:name, ID:id, Default:isDefault}'

read -p "Enter your subscription ID: " SUBSCRIPTION_ID

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"
echo "✅ Subscription set to: $SUBSCRIPTION_ID"

# Create Service Principal
echo ""
echo "🔐 Creating Service Principal..."
read -p "Enter Service Principal name (e.g., github-actions-elearning): " SP_NAME

SP_JSON=$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role "Contributor" \
  --scopes "/subscriptions/$SUBSCRIPTION_ID" \
  -o json)

echo "✅ Service Principal created!"
echo ""
echo "Add this to GitHub Secrets as AZURE_CREDENTIALS:"
echo "$SP_JSON"
echo ""

# Create Terraform state resources
echo ""
echo "💾 Creating Terraform state resources..."

read -p "Enter resource group name for state (default: rg-terraform-state): " STATE_RG
STATE_RG=${STATE_RG:-rg-terraform-state}

read -p "Enter storage account name for state (default: stterraformstate): " STATE_SA
STATE_SA=${STATE_SA:-stterraformstate}

az group create --name "$STATE_RG" --location "France Central"
echo "✅ Resource group created: $STATE_RG"

az storage account create \
  --resource-group "$STATE_RG" \
  --name "$STATE_SA" \
  --sku Standard_LRS
echo "✅ Storage account created: $STATE_SA"

az storage container create \
  --name tfstate \
  --account-name "$STATE_SA"
echo "✅ Storage container created: tfstate"

# Copy terraform variables
echo ""
echo "📝 Setting up Terraform variables..."
if [ ! -f terraform/terraform.tfvars ]; then
  cp terraform/terraform.tfvars.example terraform/terraform.tfvars
  echo "✅ Created terraform/terraform.tfvars"
else
  echo "⚠️  terraform/terraform.tfvars already exists, skipping"
fi

# Initialize Terraform
echo ""
echo "🔄 Initializing Terraform..."
cd terraform
terraform init \
  -backend-config="resource_group_name=$STATE_RG" \
  -backend-config="storage_account_name=$STATE_SA" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=staging.tfstate"
echo "✅ Terraform initialized!"

echo ""
echo "=========================================="
echo "✅ Setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Edit terraform/terraform.tfvars with your values"
echo "2. Add GitHub Secrets (see output above)"
echo "3. Run: terraform plan -var-file='envs/staging.tfvars'"
echo "4. Run: terraform apply -var-file='envs/staging.tfvars'"
echo ""
echo "Or push to GitHub to trigger CI/CD workflows!"
