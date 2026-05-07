# Configuration pour le déploiement Azure
# Tous les secrets sensibles doivent être stockés dans GitHub Secrets

# Secrets GitHub à configurer:
# AZURE_CREDENTIALS: Service Principal JSON credentials
# AZURE_SUBSCRIPTION_ID: Subscription ID
# ACR_LOGIN_SERVER: Container registry login server (e.g., myregistry.azurecr.io)
# ACR_USERNAME: Container registry username
# ACR_PASSWORD: Container registry password
# RESOURCE_GROUP: Azure resource group name
# TF_STATE_RG: Terraform state resource group
# TF_STATE_SA: Terraform state storage account
# AZURE_STATIC_WEB_APPS_TOKEN: Static Web Apps deployment token

# Environments GitHub à créer:
# - staging: pour le déploiement sur l'environnement de staging
# - production: pour le déploiement sur la production

# Variables d'environnement pour Container Apps (via Azure CLI ou Terraform):
# DATABASE_URL
# REDIS_URL
# JWT_SECRET
# JWT_REFRESH_SECRET
# STRIPE_SECRET_KEY
# CLOUDINARY_CLOUD_NAME
# CLOUDINARY_API_KEY
# CLOUDINARY_API_SECRET
# FRONTEND_URL

# Service Principal creation:
# az ad sp create-for-rbac --name "elearning-deployment" --role "Contributor" --scopes "/subscriptions/{subscription-id}" -o json

# Terraform backend setup:
# 1. Create resource group: az group create --name rg-terraform-state --location eastus
# 2. Create storage account: az storage account create --resource-group rg-terraform-state --name stterraformstate --sku Standard_LRS
# 3. Create container: az storage container create --name tfstate --account-name stterraformstate
