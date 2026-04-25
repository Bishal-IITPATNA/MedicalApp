# GitHub Actions Troubleshooting Guide

This guide helps resolve common issues with the CI/CD pipeline.

## Quick Diagnostics

### 1. Check Workflow Status

1. Go to repository → **Actions** tab
2. Click the failed workflow run
3. Click the failed job to expand details
4. Look for red ❌ indicator showing which step failed
5. Click the step name to see full error message

### 2. View Workflow Logs

Every workflow stores logs that persist for 90 days.

```bash
# View logs using GitHub CLI (if installed)
gh run list --repo YOUR_ORG/MedicalApp
gh run view <RUN_ID> --log
```

---

## Common Errors & Solutions

### 🔴 Error: "Resource 'rg-seevak-care-prod' could not be found"

**Cause**: Azure resource group doesn't exist or wrong name

**Solution**:
```bash
# List all resource groups
az group list --query "[].name" -o table

# If missing, create resource group
az group create \
  --name rg-seevak-care-prod \
  --location eastus

# Update workflow env variable if name is different
# Edit: .github/workflows/deploy-to-azure.yml
# Change: RESOURCE_GROUP: rg-seevak-care-prod
```

---

### 🔴 Error: "No such file or directory: backend/main.py"

**Cause**: Backend file structure is incorrect

**Solution**:
```bash
# Verify backend structure
ls -la backend/
# Should show: main.py, application.py, wsgi.py, requirements.txt, app/, ...

# If files are missing, check git status
git status

# Add missing files
git add backend/
git commit -m "Add backend files"
git push origin main
```

---

### 🔴 Error: "Invalid credentials for Azure login"

**Cause**: Azure OIDC secrets are incorrect or misconfigured

**Solution**:

```bash
# 1. Verify secrets in GitHub
# Settings → Secrets and variables → Actions
# Check: AZUREAPPSERVICE_CLIENTID_*
#        AZUREAPPSERVICE_TENANTID_*
#        AZUREAPPSERVICE_SUBSCRIPTIONID_*

# 2. Verify OIDC is configured in Azure
az ad app federated-identity-credential list \
  --id <YOUR_APP_CLIENT_ID>

# 3. If missing, create federated credential
az ad app federated-identity-credential create \
  --id <YOUR_APP_CLIENT_ID> \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_ORG/MedicalApp:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 4. Verify service principal has proper permissions
az role assignment list --assignee <YOUR_APP_CLIENT_ID>

# 5. If permissions missing, grant permissions
az role assignment create \
  --assignee <YOUR_APP_CLIENT_ID> \
  --role "Contributor" \
  --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

---

### 🔴 Error: "No such file or directory: backend-deploy.zip"

**Cause**: ZIP file creation failed before deployment step

**Solution**:
1. Check step "Create deployment package" logs
2. Verify backend directory has required files
3. Check disk space available in workflow runner
4. Re-run workflow:
   - Go to **Actions** → Select workflow → **Run workflow** → **Run workflow**

---

### 🔴 Error: "Service plan 'plan-seevak-backend' not found"

**Cause**: App Service Plan doesn't exist

**Solution**:
```bash
# List existing plans
az appservice plan list --resource-group rg-seevak-care-prod

# Create plan if missing
az appservice plan create \
  --name plan-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --sku B2 \
  --is-linux

# Or update workflow to use existing plan name
```

---

### 🔴 Error: "Health check failed: Connection refused"

**Cause**: Backend app not starting or health endpoint doesn't exist

**Solution**:

```bash
# 1. Check if health endpoint exists
curl https://webapp-seevak-backend.azurewebsites.net/health

# 2. If 404, add health endpoint to Flask app
# backend/app/__init__.py
from flask import Flask

def create_app():
    app = Flask(__name__)
    
    @app.route('/health')
    def health():
        return {'status': 'ok'}, 200
    
    return app

# 3. Or disable health check in workflow
# Comment out or remove the health check step

# 4. Check app logs for startup errors
az webapp log tail \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# 5. Restart app
az webapp restart \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod
```

---

### 🔴 Error: "Python requirements not installed"

**Cause**: requirements.txt not found or has syntax errors

**Solution**:
```bash
# 1. Verify requirements.txt exists and is readable
cat backend/requirements.txt

# 2. Check for syntax errors
# Should have format: package_name==version

# 3. Test locally
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 4. If error, fix requirements.txt and push
git add backend/requirements.txt
git commit -m "Fix requirements.txt"
git push origin main
```

---

### 🔴 Error: "Flutter build failed"

**Cause**: pubspec.yaml has issues or dependency conflicts

**Solution**:
```bash
# 1. Test build locally
cd frontend
flutter clean
flutter pub get
flutter build web --release

# 2. If errors, check pubspec.yaml
cat pubspec.yaml

# 3. Fix dependency conflicts
flutter pub upgrade

# 4. Commit and push
git add frontend/pubspec.yaml frontend/pubspec.lock
git commit -m "Fix Flutter dependencies"
git push origin main
```

---

### 🔴 Error: "Token expired or invalid" (Static Web Apps)

**Cause**: Azure Static Web Apps deployment token is expired

**Solution**:
```bash
# 1. Get new deployment token
az staticwebapp secrets list \
  --name seevak-care-frontend \
  --resource-group rg-seevak-care-prod

# 2. Regenerate token in Azure Portal
# Azure Portal → Static Web Apps → seevak-care-frontend
# → Settings → Deployment Token → Regenerate

# 3. Update GitHub secret
# Settings → Secrets → Update AZURE_STATIC_WEB_APPS_API_TOKEN_*
# Paste new token

# 4. Re-run workflow
```

---

### 🔴 Error: "Out of storage space" or "Disk full"

**Cause**: Workflow runner disk is full

**Solution**:
```bash
# 1. This usually clears after workflow completes
# 2. If persistent, check artifact storage
# Settings → Actions → General → Artifact retention

# 3. Delete old workflow artifacts
# Actions → Select old run → Delete all artifacts

# 4. Clean build in workflow:
# Add to workflow before build steps
- name: Clean up
  run: |
    rm -rf backend-deploy.zip
    rm -rf frontend/build
    rm -rf backend/__pycache__
    find . -type d -name __pycache__ -exec rm -rf {} +
```

---

### 🔴 Error: Secret not found: "AZUREAPPSERVICE_CLIENTID..."

**Cause**: GitHub secret is not configured

**Solution**:
```bash
# 1. Verify secret name is EXACT (case-sensitive)
# Go to Settings → Secrets and variables → Actions
# Look for: AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21

# 2. Add secret if missing
# Click "New repository secret"
# Name: AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21
# Value: <Your Azure client ID>
# Click "Add secret"

# 3. Verify secrets via GitHub CLI
gh secret list
```

---

### 🔴 Error: "Unable to locate app location 'frontend'"

**Cause**: Frontend directory is missing or in wrong location

**Solution**:
```bash
# 1. Verify frontend directory exists
ls -la frontend/

# 2. Check it has pubspec.yaml
ls -la frontend/pubspec.yaml

# 3. If missing, check git status
git status

# 4. If directory not tracked, add to git
git add frontend/
git commit -m "Add frontend"
git push origin main

# 5. Update workflow app_location if directory name is different
# Edit: .github/workflows/deploy-to-azure.yml
# Change: app_location: "frontend"
```

---

### 🟡 Warning: "Health check timeout"

**Cause**: App is slow to start (not an error)

**Solution**:
```yaml
# 1. Increase timeout in workflow
# .github/workflows/deploy-to-azure.yml
- name: Health check
  run: |
    # Change sleep duration
    sleep 60  # Increase from 30 to 60 seconds

# 2. Check if app actually started
az webapp show \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --query state

# 3. View startup logs
az webapp log tail \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod --max-lines 50
```

---

## Debugging Steps

### Step 1: Identify the Failing Step

1. Open GitHub Actions workflow run
2. Look for ❌ red marker
3. Note the step name and error message

### Step 2: Check Logs

1. Click on the failed step
2. Read the full error output
3. Search for specific error messages below

### Step 3: Verify Prerequisites

```bash
# Check backend
ls -la backend/main.py
ls -la backend/requirements.txt
ls -la backend/app/__init__.py

# Check frontend
ls -la frontend/pubspec.yaml
ls -la frontend/lib/main.dart

# Check Azure resources
az group exists --name rg-seevak-care-prod
az webapp list --resource-group rg-seevak-care-prod
az staticwebapp list --resource-group rg-seevak-care-prod
```

### Step 4: Test Locally

```bash
# Test backend
cd backend
pip install -r requirements.txt
python main.py

# Test frontend build
cd frontend
flutter clean
flutter pub get
flutter build web --release
```

### Step 5: Enable Debug Logging

```yaml
# Add to workflow step for verbose output
- name: Enable debug logging
  env:
    ACTIONS_STEP_DEBUG: true
    AZURE_CLI_DEBUG: 1
  run: echo "Debug enabled"
```

---

## Getting Help

### 1. Check GitHub Community

- GitHub Discussions: https://github.com/orgs/community/discussions
- GitHub Issues: Search similar issues on Actions repo

### 2. Check Azure Documentation

- Azure App Service Troubleshooting: https://learn.microsoft.com/azure/app-service/
- Azure Static Web Apps Docs: https://learn.microsoft.com/azure/static-web-apps/

### 3. Check Logs and Artifacts

- All workflow runs keep logs for 90 days
- Download artifacts from failed runs
- Use `gh run download` to download locally

### 4. Re-run Failed Workflow

```bash
# Via GitHub CLI
gh run rerun <RUN_ID> --failed

# Via GitHub UI
Actions → Select run → Re-run jobs → Re-run failed jobs
```

---

## Performance Optimization

### Reduce Workflow Time

```yaml
# 1. Use cache for dependencies
- uses: actions/setup-python@v5
  with:
    cache: 'pip'  # Caches pip dependencies

# 2. Parallel jobs
backend-build-test:
  runs-on: ubuntu-latest
frontend-build-test:
  runs-on: ubuntu-latest
# These run in parallel, not sequentially

# 3. Skip unnecessary steps
- if: github.event_name == 'pull_request'
  run: echo "Only run on PRs"
```

### Reduce Artifact Size

```bash
# In workflow, exclude unnecessary files
zip -r backend-deploy.zip . \
  -x "*.git*" \
    "**/__pycache__/**" \
    "*.pyc" \
    "**/.DS_Store" \
    "venv/**" \
    "node_modules/**"
```

---

## Monitoring & Alerts

### Enable Email Notifications

Settings → Notifications → GitHub Actions

### Set Up Slack Alerts

Configure `SLACK_WEBHOOK_URL` secret (see SECRETS_CONFIGURATION.md)

### Monitor Deployments

```bash
# View recent deployments
az webapp deployment list \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# Check deployment status
az webapp deployment show \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod
```

---

## Rollback Procedures

If deployment causes issues:

```bash
# 1. Check previous deployments
az webapp deployment list \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --query "[0:5].[id, provisioningState, created]" -o table

# 2. Stop current problematic app
az webapp stop \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# 3. Rollback to previous version (if available)
# Option A: Re-deploy from previous commit
git checkout <PREVIOUS_COMMIT>
git push --force origin main  # Force push if needed

# Option B: Restore from backup (if configured)
# Requires Azure Backup configured

# 4. Monitor recovery
az webapp log tail \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod
```

---

**Last Updated**: April 2026
**Version**: 1.0

**Quick Links**:
- 📋 Setup Guide: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
- 🔐 Secrets Config: [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md)
- 🔄 Workflow File: [workflows/deploy-to-azure.yml](./workflows/deploy-to-azure.yml)
