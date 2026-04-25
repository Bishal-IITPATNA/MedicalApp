# CI/CD Quick Reference Guide

Quick commands and steps for common CI/CD tasks.

## 🚀 Quick Start

### First Time Setup
```bash
# 1. Configure GitHub secrets (see SECRETS_CONFIGURATION.md)
# 2. Test workflow manually
# 3. Push to main to trigger automatic deployment

# To manually trigger workflow:
# GitHub: Actions → Deploy to Azure → Run workflow
```

### Verify Setup
```bash
# Check backend is ready
cd backend && pip install -r requirements.txt && python main.py

# Check frontend is ready
cd frontend && flutter pub get && flutter build web --release

# Check secrets are configured
# GitHub: Settings → Secrets and variables → Actions
```

---

## 📊 Workflow Status

### View Workflow Runs
```bash
# Open GitHub Actions
# https://github.com/YOUR_ORG/MedicalApp/actions

# Or use GitHub CLI
gh run list
gh run list --status failure  # Show failed runs
gh run list --branch main     # Show main branch runs
```

### Monitor Current Run
```bash
# View specific run
gh run view <RUN_ID>

# Watch run in real-time
gh run view <RUN_ID> --log

# Follow all logs
gh run view <RUN_ID> --log --tail
```

### Check Deployment Status
```bash
# Backend App Service
az webapp show \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --query "state"

# Frontend Static Web App
az staticwebapp show \
  --name seevak-care-frontend \
  --resource-group rg-seevak-care-prod
```

---

## 🔧 Manual Deployment

### Trigger Workflow Manually

**Via GitHub UI:**
1. Go to Actions tab
2. Select "Deploy to Azure" workflow
3. Click "Run workflow"
4. Choose branch and options
5. Click "Run workflow"

**Via GitHub CLI:**
```bash
gh workflow run deploy-to-azure.yml
gh workflow run deploy-to-azure.yml -f environment=production
```

### Deploy Backend Manually
```bash
az login

cd backend

# Create deployment package
zip -r ../backend-deploy.zip . \
  -x "*.git*" "**/__pycache__/**" "*.pyc" "**/.*"

# Deploy to Azure
az webapp deployment source config-zip \
  --resource-group rg-seevak-care-prod \
  --name webapp-seevak-backend \
  --src ../backend-deploy.zip

# Check deployment
az webapp deployment list --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod
```

### Deploy Frontend Manually
```bash
cd frontend

# Build Flutter web
flutter build web --release

# Deploy to Static Web Apps
# This requires Azure Static Web Apps CLI or GitHub Actions
# Easiest: Just push to main branch - workflow will deploy automatically
```

---

## 📝 Testing Before Push

### Test Backend Locally
```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run linting
pylint app/ --disable=all --enable=E,F

# Run tests
pytest -v --cov=app

# Test app startup
python main.py

# Access API
curl http://localhost:5000/health
```

### Test Frontend Locally
```bash
cd frontend

# Get dependencies
flutter pub get

# Analyze code
flutter analyze

# Run tests
flutter test

# Build for web
flutter build web --release

# Or run in dev mode
flutter run -d web-server --web-port=8080
```

---

## 🔍 Viewing Logs

### View GitHub Actions Logs
```bash
# Latest run
gh run view --log

# Specific run
gh run view <RUN_ID> --log

# Download logs locally
gh run download <RUN_ID>
```

### View Azure App Service Logs
```bash
# Stream live logs
az webapp log tail \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# View last 50 lines
az webapp log tail \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --max-lines 50

# Download logs
az webapp log download \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --log-file ./logs.zip
```

### View Static Web Apps Logs
```bash
# Check deployment history
az staticwebapp deployment list \
  --name seevak-care-frontend \
  --resource-group rg-seevak-care-prod
```

---

## 🐛 Debugging

### Check if Secrets Are Configured
```bash
# Via GitHub CLI
gh secret list

# In GitHub UI
Settings → Secrets and variables → Actions
```

### Test Azure Authentication
```bash
# Test OIDC token
az login --service-principal \
  -u $AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21 \
  -t $AZUREAPPSERVICE_TENANTID_2DD5AD037E6E439AAD7D3BF85369D565

# List accessible resources
az group list
az webapp list --resource-group rg-seevak-care-prod
```

### Check Deployment Status
```bash
# Backend
curl https://webapp-seevak-backend.azurewebsites.net/health

# Check app service state
az webapp show \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --query "state"
```

### Re-run Failed Job
```bash
# Via GitHub CLI
gh run rerun <RUN_ID> --failed

# Via GitHub UI
Actions → Select Run → Re-run jobs → Re-run failed jobs
```

---

## 🔐 Managing Secrets

### Add Secret
```bash
# Via GitHub CLI
gh secret set AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21 \
  --body "your-client-id"

# Via GitHub UI
Settings → Secrets and variables → Actions → New repository secret
```

### Update Secret
```bash
# Delete and recreate (secrets can't be updated, only replaced)
gh secret delete AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21
gh secret set AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21 \
  --body "new-client-id"
```

### List Secrets
```bash
# View all configured secrets (names only, not values)
gh secret list
```

### Remove Secret
```bash
gh secret delete SECRET_NAME
```

---

## 🚨 Rollback & Recovery

### Stop Deployment
```bash
# Cancel running workflow
gh run cancel <RUN_ID>

# Stop app service
az webapp stop \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod
```

### Restart Services
```bash
# Restart backend
az webapp restart \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# Restart frontend (if applicable)
az staticwebapp restart \
  --name seevak-care-frontend \
  --resource-group rg-seevak-care-prod
```

### Rollback to Previous Version
```bash
# 1. Find previous commit
git log --oneline | head -10

# 2. Checkout previous commit
git checkout <PREVIOUS_COMMIT_HASH>

# 3. Force push to main
git push --force origin main

# 4. Monitor deployment via GitHub Actions
gh run list --branch main
```

---

## 📈 Performance & Optimization

### Check Workflow Duration
```bash
# View recent runs with timing
gh run list --limit 10

# Detailed timing info
gh run view <RUN_ID> --json jobs \
  --jq '.jobs[] | .name, .startedAt, .conclusion'
```

### View Artifact Size
```bash
# GitHub Actions artifacts expire after 90 days
# View in: Actions → Run → Artifacts

# Or via CLI
gh run download <RUN_ID>
du -sh ./
```

### Optimize Workflow
- Use caching for dependencies
- Parallelize jobs (backend + frontend test in parallel)
- Skip tests on simple updates
- Clean artifacts regularly

---

## 🎯 Common Scenarios

### Scenario: Deploy Only Backend
1. Make backend changes
2. Push to main
3. Workflow runs full pipeline
4. Only backend deployment executes if needs_dependencies pass

### Scenario: Deploy Only Frontend
1. Make frontend changes
2. Push to main
3. Workflow runs full pipeline
4. Only frontend deployment executes if needs_dependencies pass

### Scenario: Skip Deployment (Tests Only)
1. Push to branch other than `main`
2. Tests run, deployment skipped
3. Create PR to `main` for review

### Scenario: Emergency Hotfix
1. Create hotfix branch: `git checkout -b hotfix/issue-name`
2. Fix the issue
3. Test locally
4. Push to trigger PR tests
5. Merge to `main` after approval
6. Deployment happens automatically

### Scenario: Deploy to Staging First
1. Create `develop` branch (already in workflow)
2. Push changes to `develop`
3. Workflow deploys to staging environment
4. Test thoroughly
5. Merge to `main` for production deployment

---

## 📋 Pre-Deployment Checklist

Before pushing to main:

- [ ] Code compiles without errors
- [ ] All unit tests pass locally
- [ ] No linting errors (pylint, flutter analyze)
- [ ] Updated dependencies (requirements.txt, pubspec.yaml)
- [ ] No secrets in code
- [ ] Updated documentation if needed
- [ ] Tested in development environment
- [ ] Code reviewed by team

### Quick Pre-Push Check
```bash
# Backend
cd backend
pip install -r requirements.txt
pylint app/ --disable=all --enable=E,F || true
pytest -v || true

# Frontend
cd frontend
flutter analyze || true
flutter test || true
flutter build web --release || true
```

---

## 🔗 Useful Links

- **GitHub Actions**: https://github.com/YOUR_ORG/MedicalApp/actions
- **GitHub Secrets**: https://github.com/YOUR_ORG/MedicalApp/settings/secrets/actions
- **Azure Portal**: https://portal.azure.com
- **GitHub CLI Docs**: https://cli.github.com/manual
- **Azure CLI Docs**: https://learn.microsoft.com/cli/azure

---

## 📞 Support

If workflow fails:

1. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
2. View workflow logs in GitHub Actions
3. Check Azure App Service logs: `az webapp log tail ...`
4. Run manual tests locally
5. Contact team lead with:
   - Workflow run URL
   - Error message
   - Recent changes made

---

**Last Updated**: April 2026
**Version**: 1.0

**Quick References:**
- 📚 Setup: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
- 🐛 Troubleshoot: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
- 🔐 Secrets: [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md)
- 🔄 Workflow: [workflows/deploy-to-azure.yml](./workflows/deploy-to-azure.yml)
