# GitHub CI/CD Pipeline Setup Guide

## Overview

This guide explains how to set up and configure the GitHub Actions CI/CD pipeline for deploying the Seevak Care application to Azure. The pipeline automatically builds, tests, and deploys both the backend (Flask) and frontend (Flutter) applications.

## Workflow Features

✅ **Automated Testing**
- Python linting and unit tests for backend
- Flutter analyzer and tests for frontend
- Code coverage reporting

✅ **Continuous Integration**
- Builds backend and frontend on push to main/develop
- Runs tests on pull requests
- Code quality checks

✅ **Continuous Deployment**
- Automatic deployment to Azure App Service (backend)
- Automatic deployment to Azure Static Web Apps (frontend)
- Health checks and deployment verification

✅ **Notifications**
- Deployment success/failure notifications (optional Slack integration)
- Detailed logs and error messages

## Prerequisites

- **Azure Subscription** with:
  - Azure App Service for backend (`webapp-seevak-backend`)
  - Azure Static Web Apps for frontend
  - Resource Group: `rg-seevak-care-prod`

- **GitHub Repository** with:
  - GitHub Actions enabled
  - Admin/Owner access to configure secrets

- **Local Environment**:
  - Git
  - Python 3.11+
  - Flutter 3.41.6+

## Step 1: Azure Setup

### 1.1 Create Azure Resources (if not already created)

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<YOUR_SUBSCRIPTION_ID>"

# Create resource group
az group create \
  --name rg-seevak-care-prod \
  --location eastus

# Create App Service Plan (if needed)
az appservice plan create \
  --name plan-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --sku B2 \
  --is-linux

# Create App Service for backend
az webapp create \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --plan plan-seevak-backend \
  --runtime "PYTHON|3.11"

# Create Static Web App for frontend (if not already created)
az staticwebapp create \
  --name seevak-care-frontend \
  --resource-group rg-seevak-care-prod \
  --location eastus
```

### 1.2 Configure Azure Authentication with OIDC

Set up OpenID Connect (OIDC) for secure authentication:

```bash
# Create an Azure AD application
az ad app create --display-name "github-actions-seevak-care"

# Store the Application ID
APP_ID=$(az ad app show --display-name "github-actions-seevak-care" --query appId -o tsv)

# Create a service principal
az ad sp create --id $APP_ID

# Add federated credentials for GitHub
az ad app federated-identity-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-actions",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:YOUR_GITHUB_ORG/MedicalApp:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Step 2: Configure GitHub Secrets

Go to **Settings** → **Secrets and variables** → **Actions** and add the following secrets:

### Azure OIDC Secrets (Recommended)

```
AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21
├─ Value: <YOUR_AZURE_APP_CLIENT_ID>

AZUREAPPSERVICE_TENANTID_2DD5AD037E6E439AAD7D3BF85369D565
├─ Value: <YOUR_AZURE_TENANT_ID>

AZUREAPPSERVICE_SUBSCRIPTIONID_55D71896B10244CCA1DA74C96776A35C
├─ Value: <YOUR_AZURE_SUBSCRIPTION_ID>
```

### Azure Static Web Apps Secret

```
AZURE_STATIC_WEB_APPS_API_TOKEN_BRAVE_SMOKE_045200400
├─ Value: <YOUR_STATIC_WEB_APPS_DEPLOYMENT_TOKEN>
```

To get the Static Web Apps deployment token:
1. Navigate to your Static Web App resource in Azure Portal
2. Click **Settings** → **Deployment Token**
3. Copy the token

### GitHub Token (Auto-generated)

```
GITHUB_TOKEN
├─ Value: Auto-provided by GitHub Actions (no configuration needed)
```

### Optional: Slack Notification

If you want to enable Slack notifications:

```
SLACK_WEBHOOK_URL
├─ Value: <YOUR_SLACK_WEBHOOK_URL>
```

Get Slack webhook URL: https://api.slack.com/messaging/webhooks

## Step 3: Configure GitHub Variables (Optional)

Go to **Settings** → **Secrets and variables** → **Variables** to set optional settings:

```
SLACK_WEBHOOK_URL
├─ Value: Set this to enable Slack notifications
├─ Optional: true
```

## Step 4: Test the Pipeline

### 4.1 Manual Trigger (Recommended for First Test)

1. Go to **Actions** tab in your GitHub repository
2. Select the **"Deploy to Azure"** workflow
3. Click **"Run workflow"**
4. Select branch and environment
5. Click **"Run workflow"**

### 4.2 Automatic Trigger

Push to the `main` branch to trigger the workflow:

```bash
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### 4.3 Monitor Execution

1. Go to **Actions** tab
2. Click on the running workflow
3. Monitor each job:
   - ✅ Backend Build & Test
   - ✅ Frontend Build & Test
   - ✅ Deploy Backend to Azure
   - ✅ Deploy Frontend to Azure Static Web Apps

## Workflow Configuration

### Environment Variables

Edit `.github/workflows/deploy-to-azure.yml` to customize:

```yaml
env:
  RESOURCE_GROUP: rg-seevak-care-prod      # Azure resource group
  BACKEND_APP_NAME: webapp-seevak-backend  # Azure App Service name
  FLUTTER_VERSION: '3.41.6'                # Flutter version
  NODE_VERSION: '18'                       # Node.js version (optional)
```

### Trigger Events

The workflow runs on:

```yaml
on:
  push:
    branches:
      - main      # Production deployment
      - develop   # Staging deployment (optional)
  pull_request:
    branches:
      - main
      - develop
  workflow_dispatch:  # Manual trigger
```

To modify triggers, edit the `on:` section in the workflow file.

## Understanding the Workflow

### Job Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│ 1. Backend Build & Test (runs on all branches)                      │
│    └─ Install dependencies, lint, run tests                         │
├─────────────────────────────────────────────────────────────────────┤
│ 2. Frontend Build & Test (runs on all branches)                     │
│    └─ Install dependencies, analyze, run tests                      │
├─────────────────────────────────────────────────────────────────────┤
│ 3. Deploy Backend to Azure (only on main branch, on push)           │
│    └─ Create ZIP, stop service, deploy, health check               │
├─────────────────────────────────────────────────────────────────────┤
│ 4. Deploy Frontend to Azure Static Web Apps (only on main, on push) │
│    └─ Build Flutter web, deploy to Static Web Apps                 │
├─────────────────────────────────────────────────────────────────────┤
│ 5. Deployment Notification (success or failure)                    │
│    └─ Send notification and logs                                    │
└─────────────────────────────────────────────────────────────────────┘
```

### Key Stages Explained

#### 1. **Backend Build & Test**

Runs on: All pushes and PRs

```bash
# Installs Python dependencies
pip install -r requirements.txt

# Runs linting (Pylint)
pylint app/

# Runs unit tests with coverage
pytest --cov=app --cov-report=xml
```

#### 2. **Frontend Build & Test**

Runs on: All pushes and PRs

```bash
# Installs Flutter dependencies
flutter pub get

# Analyzes code
flutter analyze

# Runs unit tests
flutter test
```

#### 3. **Backend Deployment**

Runs on: Push to `main` branch only

```bash
# Creates deployable ZIP package
zip -r backend-deploy.zip ./backend

# Deploys to Azure App Service
az webapp deployment source config-zip

# Performs health checks
curl https://webapp-seevak-backend.azurewebsites.net/health
```

#### 4. **Frontend Deployment**

Runs on: Push to `main` branch only

```bash
# Builds production-ready Flutter web app
flutter build web --release

# Deploys to Azure Static Web Apps
Azure/static-web-apps-deploy@v1
```

## Troubleshooting

### Deployment Failed

Check the following:

1. **Azure Authentication Issues**
   ```bash
   # Verify OIDC configuration
   az ad app federated-identity-credential list --id <APP_ID>
   
   # Test authentication
   az login --service-principal -u <CLIENT_ID> -t <TENANT_ID>
   ```

2. **App Service Issues**
   ```bash
   # Check app service status
   az webapp show --name webapp-seevak-backend \
     --resource-group rg-seevak-care-prod
   
   # View logs
   az webapp log tail --name webapp-seevak-backend \
     --resource-group rg-seevak-care-prod
   ```

3. **Backend Start Issues**
   - Check `main.py` exists in backend directory
   - Verify `requirements.txt` has all dependencies
   - Check Python version compatibility (3.11+)

4. **Frontend Build Issues**
   - Clear Flutter build cache: `flutter clean`
   - Get dependencies: `flutter pub get`
   - Check pubspec.yaml for dependency conflicts

### Health Check Timeout

If health check fails:

1. Check if endpoint `/health` exists:
   ```bash
   curl https://webapp-seevak-backend.azurewebsites.net/health
   ```

2. If endpoint doesn't exist, add it or disable health check in workflow

3. Check app initialization time (may need to increase delay)

### Secrets Not Found

```bash
# List all secrets configured
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/YOUR_ORG/MedicalApp/actions/secrets
```

## Best Practices

### 1. Use Protected Branches

Protect the `main` branch to require successful CI/CD checks:

Settings → Branches → Add Rule
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date

### 2. Environment-Specific Deployments

For different environments:

```yaml
on:
  push:
    branches:
      - main      # Deploys to production
      - develop   # Deploys to staging (configure separately)
```

### 3. Monitor Deployments

Enable GitHub notifications:
Settings → Email notifications → GitHub Actions

### 4. Secure Secrets

- Rotate secrets regularly
- Use OIDC instead of shared secrets
- Use environment-specific secrets for different Azure resources

### 5. Test Locally

Before pushing to main:

```bash
# Test backend
cd backend
pip install -r requirements.txt
python main.py

# Test frontend
cd frontend
flutter run -d web-server
```

## Advanced Configuration

### Custom Health Check

To customize the health check endpoint in the workflow:

```yaml
- name: Health check
  run: |
    HEALTH_URL="https://${{ env.BACKEND_APP_NAME }}.azurewebsites.net/api/v1/status"
    # ... rest of health check logic
```

### Add Slack Notifications

Set `SLACK_WEBHOOK_URL` secret and the workflow will automatically send notifications.

### Database Migrations

To run database migrations during deployment, add before deployment:

```yaml
- name: Run database migrations
  run: |
    cd backend
    flask db upgrade
```

### Custom Environment Variables

Add to Azure App Service settings:

```bash
az webapp config appsettings set \
  --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod \
  --settings \
    ENV_VAR_NAME="value" \
    ANOTHER_VAR="another_value"
```

## Cost Optimization

- **GitHub Actions**: Free tier includes 2000 minutes/month
- **Azure App Service**: B2 tier ~$50/month (adjust as needed)
- **Azure Static Web Apps**: Free tier available with limitations

## Support & Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure App Service Documentation](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Static Web Apps Documentation](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Flutter Web Documentation](https://flutter.dev/multi-platform/web)

## Checklist for First Deployment

- [ ] Azure resources created and configured
- [ ] GitHub secrets configured (Azure credentials, Static Web Apps token)
- [ ] Repository has workflow file `.github/workflows/deploy-to-azure.yml`
- [ ] Backend has `requirements.txt` and `main.py`
- [ ] Frontend has `pubspec.yaml` and `lib/main.dart`
- [ ] Health check endpoint configured or disabled
- [ ] Manual workflow trigger test successful
- [ ] Push to main branch and verify automatic deployment
- [ ] Verify backend is running: `https://webapp-seevak-backend.azurewebsites.net`
- [ ] Verify frontend is accessible via Static Web Apps URL

---

**Last Updated**: April 2026
**Workflow Version**: 1.0
