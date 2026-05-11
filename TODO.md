# TODO — Déploiement e-learning (end-to-end)

- [x] Vérifier cohérence Terraform vs workflow build-deploy
- [x] Supprimer étape de purge CDN dans `.github/workflows/build-deploy.yml` (Terraform CDN désactivé)
- [x] Vérifier backend expose bien le préfixe `/api` (pour valider `VITE_API_URL`)

- [x] Vérifier dans `frontend`/`backend` le mapping routes (axios baseURL + endpoints)

- [x] Mettre à jour la documentation README_DEPLOYMENT / FILES_CHECKLIST avec la valeur attendue de `VITE_API_URL`

- [ ] Option avancée: récupérer `backend_app_url` Terraform dans le workflow pour éviter secrets manuels
- [ ] Test final: push sur `develop` => vérifier logs GitHub Actions + URL `frontend_static_website_url`

