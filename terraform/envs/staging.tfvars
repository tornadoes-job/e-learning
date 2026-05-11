# Staging environment variables
app_name    = "elearning"
environment = "staging"
location    = "eastus"
db_location = ""

# PostgreSQL
db_name = "elearning"
db_sku  = "B_Standard_B1ms"

# Redis
redis_capacity = 0
redis_family   = "C"
redis_sku      = "Basic"

# Secrets and public URLs are injected by GitHub Actions or local TF_VAR_* variables.
