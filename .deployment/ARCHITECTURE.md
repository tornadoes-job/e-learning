# Architecture du déploiement Azure pour E-Learning Platform

## 🏗️ Architecture globale

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Actions CI/CD                       │
│  - Lint & Test → Build Docker → Push ACR → Deploy Container Apps  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                      Azure Infrastructure                          │
│                                                                    │
│  ┌──────────────────────┐        ┌──────────────────────┐       │
│  │   Static Web Apps    │        │   Container Apps     │       │
│  │   (Frontend React)   │        │  (Backend NestJS)    │       │
│  └──────────────────────┘        └──────────────────────┘       │
│           ↓                                 ↓                     │
│  ┌──────────────────────┐        ┌──────────────────────┐       │
│  │   Storage Account    │        │  PostgreSQL Flexible │       │
│  │   (Static files)     │        │     (Database)       │       │
│  └──────────────────────┘        └──────────────────────┘       │
│           ↓                                 ↓                     │
│  ┌──────────────────────┐        ┌──────────────────────┐       │
│  │   CDN Profile        │        │    Redis Cache       │       │
│  │   (Caching)          │        │   (Session Cache)    │       │
│  └──────────────────────┘        └──────────────────────┘       │
│                                           ↓                       │
│                                  ┌──────────────────────┐       │
│                                  │   Key Vault          │       │
│                                  │   (Secrets)          │       │
│                                  └──────────────────────┘       │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │        Container Registry (ACR - Images Docker)          │   │
│  │  - e-learning-backend:latest                             │   │
│  │  - e-learning-frontend:latest                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │    Log Analytics Workspace (Monitoring & Logs)           │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Composants Azure

### 1. **Frontend**
- **Azure Static Web Apps** ou **Storage Account + CDN**
- Héberge l'application React compilée
- Servie par Nginx
- Cache mis en place via CDN

### 2. **Backend**
- **Container Apps**
- Conteneur Docker NestJS
- Auto-scaling (1-5 replicas)
- Network isolation

### 3. **Database**
- **PostgreSQL Flexible Server**
- Version 15
- Backups automatiques (7 jours)
- Firewall permettant les services Azure

### 4. **Cache**
- **Azure Redis Cache**
- Pour les sessions utilisateurs
- Pour le cache API

### 5. **Storage**
- **Storage Account** (frontend files)
- **Blob storage** pour les fichiers statiques

### 6. **Sécurité**
- **Key Vault** pour les secrets
- **Network Security Groups** pour l'isolation
- **SSL/TLS** pour tous les endpoints

### 7. **Monitoring**
- **Log Analytics Workspace**
- **Application Insights** (optionnel)
- Health checks automatiques

## 🔄 Flow de déploiement

### Développement (develop branch):
```
Push → GitHub Actions
  ├─ Lint & Test
  ├─ Build Docker Images
  ├─ Push to ACR (staging)
  └─ Deploy to Staging Container Apps
```

### Production (main branch):
```
Push → GitHub Actions
  ├─ Lint & Test
  ├─ Build Docker Images
  ├─ Push to ACR (prod)
  ├─ Deploy to Production Container Apps
  └─ Deploy Frontend to Static Web Apps
```

## 🔐 Secrets Management

Tous les secrets sont stockés dans **Azure Key Vault** et injectés via:
- Variables d'environnement Container Apps
- GitHub Secrets pour CI/CD

**Secrets requis:**
- `JWT_SECRET`
- `JWT_REFRESH_SECRET`
- `DATABASE_URL`
- `REDIS_URL`
- `STRIPE_SECRET_KEY`
- `CLOUDINARY_CLOUD_NAME`
- `CLOUDINARY_API_KEY`
- `CLOUDINARY_API_SECRET`
- `FRONTEND_URL`

## 📊 Coûts mensuels estimés

| Service | SKU | ~Cost/month |
|---------|-----|------------|
| PostgreSQL | B_Standard_B1ms | $15 |
| Redis Cache | Basic, 0GB | $15 |
| Container Apps | 0.5 CPU, 1GB RAM | $25-50 |
| Storage Account | Standard LRS | $1-5 |
| CDN | Standard_Microsoft | $0.15/GB |
| Key Vault | Standard | $0.72 |
| **Total** | | **$57-86** |

## 🚀 Scaling Strategy

### Développement (dev):
- Container Apps: 1 replica min, 2 max
- PostgreSQL: B_Standard_B1ms
- Redis: Basic

### Production (prod):
- Container Apps: 2 replicas min, 5 max
- PostgreSQL: B_Standard_B2s
- Redis: Standard 1GB

## 📈 Monitoring & Alertes

**Métriques suivies:**
- CPU usage
- Memory usage
- Network I/O
- Request count
- Error rate
- Response time
- Database connections
- Cache hit ratio

## 🆘 Disaster Recovery

- **Backups**: Automatique 7 jours pour DB
- **Réplication**: Geo-redundant à envisager pour prod
- **Failover**: Container Apps gère les replicas
- **RTO**: ~5 minutes
- **RPO**: ~1 heure

## 🔒 Sécurité

- **Network**: Private endpoints envisagés
- **Authentication**: Managed Identity pour Container Apps
- **Secrets**: Azure Key Vault avec access policies
- **SSL/TLS**: Obligatoire (HTTPS)
- **Firewall**: NSG à configurer
- **Compliance**: GDPR-ready avec chiffrement

## 📚 Fichiers Terraform importants

- `main.tf` : Ressources principales
- `variables.tf` : Declarations des variables
- `outputs.tf` : Sorties (URLs, credentials)
- `network.tf` : Networking (VNet, Subnets)
- `envs/staging.tfvars` : Config staging
- `envs/prod.tfvars` : Config production
