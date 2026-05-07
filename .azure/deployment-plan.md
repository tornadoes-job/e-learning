# Plan de Deploiement Azure

Status: Ready for Validation

## Objectif

Preparer le projet e-learning pour un deploiement Azure reproductible avec Terraform, Docker, GitHub et GitHub Actions.

## Architecture Cible

```text
GitHub
  | push / pull request
  v
GitHub Actions
  |-- ci.yml: lint + tests
  |-- terraform.yml: plan/apply infrastructure
  `-- build-deploy.yml: build + deploy applicatif

Azure
  |-- Azure Container Registry: images Docker
  |-- Azure Container Apps: API NestJS
  |-- Azure Storage static website: build React
  |-- Azure CDN: diffusion frontend
  |-- PostgreSQL Flexible Server: base de donnees
  |-- Azure Cache for Redis: cache
  |-- Key Vault: coffre a secrets
  `-- Log Analytics + Application Insights: logs, metriques, alertes
```

## Decisions

- Backend: NestJS conteneurise et execute sur Azure Container Apps.
- Frontend: React/Vite compile en fichiers statiques et publie dans Azure Storage `$web`, avec purge CDN.
- Infrastructure: Terraform avec backend remote Azure Storage.
- Branches: `develop` deploie vers staging, `main` deploie vers production.
- Secrets: stockes dans GitHub Environments et injectes dans Terraform/GitHub Actions.

## Etapes

1. Nettoyer le workspace des artefacts generes.
2. Corriger les Dockerfiles pour fonctionner depuis la racine du monorepo npm workspaces.
3. Corriger les workflows GitHub Actions.
4. Documenter les secrets, environments, branches et commandes.
5. Valider localement les builds et la syntaxe YAML/Terraform quand les outils sont disponibles.

## Points A Valider Avant Deployer

- Identifiant de souscription Azure.
- Nom unique du storage account Terraform state.
- Noms DNS/domaines finaux.
- Valeurs reelles des secrets applicatifs: JWT, Cloudinary, Stripe, SMTP.
- Permissions du service principal GitHub Actions.
