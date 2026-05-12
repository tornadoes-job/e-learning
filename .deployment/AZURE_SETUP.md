# E-Learning Platform - Azure Deployment Guide

## 📋 Architecture

```
Frontend (React + Vite)
    ↓
Azure Static Web Apps / Storage + CDN
    ↓
Backend (NestJS)
    ↓
Azure Container Apps
    ↓
PostgreSQL + Redis + Cloudinary
```

## 🚀 Pré-requis

1. **Compte Azure** avec subscription active
2. **GitHub** repository avec ce code
3. **Azure CLI** : `az --version`
4. **Terraform** : `terraform --version`

## 🛠️ Setup Terraform State (une seule fois)

```bash
# 1. Login to Azure
az login

# 2. Create resource group for terraform state
az group create --name rg-terraform-state --location "France Central"

# 3. Create storage account
az storage account create \
  --resource-group rg-terraform-state \
  --name stterraformstate \
  --sku Standard_LRS

# 4. Create storage container
az storage container create \
  --name tfstate \
  --account-name stterraformstate

# 5. Get storage key (for later)
az storage account keys list \
  --resource-group rg-terraform-state \
  --account-name stterraformstate
```

## 🔐 Setup Service Principal pour GitHub Actions

```bash
# Create Service Principal
az ad sp create-for-rbac \
  --name "github-actions-elearning" \
  --role "Contributor" \
  --scopes "/subscriptions/{subscription-id}" \
  -o json
```

Copie le JSON complet et ajoute-le comme GitHub Secret `AZURE_CREDENTIALS`.

## 📝 Configuration GitHub Secrets

Dans Settings → Secrets and variables → Actions, ajoute:

```
AZURE_CREDENTIALS        → Service Principal JSON
AZURE_SUBSCRIPTION_ID    → ton subscription ID
ACR_LOGIN_SERVER         → e.g., myacr.azurecr.io
ACR_USERNAME             → username
ACR_PASSWORD             → password
RESOURCE_GROUP           → e.g., rg-elearning-prod
TF_STATE_RG              → rg-terraform-state
TF_STATE_SA              → stterraformstate
```

## 🖐️ Déploiement Manuel (Terraform)

```bash
# 1. Navigate to terraform directory
cd terraform

# 2. Initialize terraform
terraform init

# 3. Create terraform.tfvars with your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your subscription, passwords, etc.

# 4. Plan changes
terraform plan -var-file="envs/staging.tfvars"

# 5. Apply changes
terraform apply -var-file="envs/staging.tfvars"

# 6. Get outputs
terraform output
```

## 🐳 Dockerfiles

- `backend/Dockerfile.prod` → Image NestJS optimisée
- `frontend/Dockerfile.prod` → Image Nginx + frontend statique

## 🔄 CI/CD Workflows

### 1. `terraform.yml`
- Plan et applique les changements Terraform
- Trigger sur push vers `main` ou `develop`

### 2. `build-deploy.yml`
- Lint, test, build backend et frontend
- Build et push Docker images vers ACR
- Deploy vers Container Apps

### 3. `ci.yml`
- Tests et linting simples sans déploiement

## 📊 Architecture Azure créée

- **Resource Group** : `rg-elearning-{env}`
- **Container Registry** : `acr-{env}`
- **PostgreSQL Flexible** : `ps-elearning-{env}`
- **Redis Cache** : `redis-elearning-{env}`
- **Container Apps** : `ca-elearning-backend-{env}`
- **Storage Account** : `st-elearning-{env}` (frontend)
- **CDN** : `cdn-elearning-{env}`
- **Key Vault** : `kv-elearning-{env}`
- **Log Analytics** : `law-elearning-{env}`

## 🔒 Gestion des secrets

Tous les secrets sont gérés via:
- **GitHub Secrets** pour CI/CD
- **Key Vault** en production
- **Variables d'environnement** dans Container Apps

## 📈 Monitoring

- Logs → Log Analytics Workspace
- Alerts → Application Insights (optionnel)
- Health checks → Container Apps

## 💰 Coûts estimés (par mois)

- PostgreSQL B1ms: ~$15
- Redis Cache Basic: ~$15
- Container Apps: ~$20-50
- Storage: ~$1-5
- CDN: ~$0.15/GB

**Total: ~$51-85/mois**

## 🆘 Troubleshooting

### Terraform apply fails
```bash
terraform destroy
terraform apply
```

### Container App won't start
```bash
az containerapp logs show \
  --name ca-elearning-backend-prod \
  --resource-group rg-elearning-prod
```

### Images not in ACR
```bash
az acr repository list --resource-group {rg} --name {acr}
```

## 📖 Documentation

- [Azure Container Apps](https://docs.microsoft.com/en-us/azure/container-apps/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions](https://docs.github.com/en/actions)
