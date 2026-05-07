# Production environment variables
app_name    = "elearning"
environment = "prod"
location    = "eastus"

# PostgreSQL
db_name = "elearning"
db_sku  = "B_Standard_B2s"

# Redis
redis_capacity = 1
redis_family   = "C"
redis_sku      = "Standard"

# Secrets and public URLs are injected by GitHub Actions or local TF_VAR_* variables.
