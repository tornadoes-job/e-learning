# Configuration pour le déploiement Azure
# Tous les secrets sensibles doivent être stockés dans GitHub Secrets

# Secrets GitHub à configurer:
AZURE_CREDENTIALS: Service Principal JSON credentials
AZURE_SUBSCRIPTION_ID: a540ae0c-d9d1-449b-9503-ec3d2f189381
TF_STATE_RG: rg-terraform-state
TF_STATE_SA: stterraformstate
DB_ADMIN_USERNAME: elearningadmin
DB_ADMIN_PASSWORD: <your-secure-password>
JWT_SECRET: <your-jwt-secret>
JWT_REFRESH_SECRET: <your-jwt-refresh-secret>
STRIPE_SECRET_KEY: sk_test_xxx
CLOUDINARY_CLOUD_NAME: <your-cloud-name>
CLOUDINARY_API_KEY: <your-api-key>
CLOUDINARY_API_SECRET: <your-api-secret>
FRONTEND_URL: https://st elearningprod.z13.web.core.windows.net

# Variables d'environnement pour Container Apps (via Azure CLI ou Terraform):
DATABASE_URL
REDIS_URL
JWT_SECRET
JWT_REFRESH_SECRET
STRIPE_SECRET_KEY
CLOUDINARY_CLOUD_NAME
CLOUDINARY_API_KEY
CLOUDINARY_API_SECRET
FRONTEND_URL

# Service Principal creation:
az ad sp create-for-rbac --name "elearning-deployment" --role "Contributor" --scopes "/subscriptions/a540ae0c-d9d1-449b-9503-ec3d2f189381" -o json

# Terraform backend setup:
az group create --name rg-terraform-state --location "France Central"
az storage account create --resource-group rg-terraform-state --name stterraformstate --sku Standard_LRS
az storage container create --name tfstate --account-name stterraformstate
