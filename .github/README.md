# GitHub CI/CD Pipeline Documentation

## 📋 Overview

This directory contains the complete GitHub Actions CI/CD pipeline configuration for the Seevak Care Medical Application. The pipeline automatically builds, tests, and deploys both the Flask backend and Flutter frontend to Azure.

## 📁 Files in This Directory

### Core Documentation

| File | Purpose |
|------|---------|
| **CICD_SETUP_GUIDE.md** | Complete setup instructions for configuring the CI/CD pipeline from scratch |
| **SECRETS_CONFIGURATION.md** | Detailed guide for configuring GitHub secrets and environment variables |
| **TROUBLESHOOTING.md** | Common issues, error messages, and solutions |
| **QUICK_REFERENCE.md** | Quick commands and cheat sheet for common tasks |

### Workflow Files

| File | Purpose |
|------|---------|
| **workflows/deploy-to-azure.yml** | Main GitHub Actions workflow configuration |
| **workflows/main_webapp-seevak-backend.yml** | Original backend deployment workflow (kept for reference) |
| **workflows/azure-static-web-apps-brave-smoke-045200400.yml** | Original frontend deployment workflow (kept for reference) |
| **workflows/azure-deploy.yml** | Original combined deployment workflow (kept for reference) |

---

## 🎯 What This CI/CD Pipeline Does

### On Every Push to Main Branch

```
┌──────────────────────────────────────────────────────────────┐
│ 1. BACKEND BUILD & TEST                                      │
│    ✓ Install Python dependencies                             │
│    ✓ Run pylint linting checks                              │
│    ✓ Run pytest unit tests with coverage                    │
│    ✓ Upload coverage reports                                │
└──────────────────────────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────────────────────────┐
│ 2. FRONTEND BUILD & TEST                                     │
│    ✓ Setup Flutter                                           │
│    ✓ Get dependencies (flutter pub get)                     │
│    ✓ Run flutter analyzer                                    │
│    ✓ Run flutter tests                                       │
└──────────────────────────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────────────────────────┐
│ 3. DEPLOY BACKEND                                            │
│    ✓ Create deployment ZIP package                           │
│    ✓ Login to Azure                                          │
│    ✓ Stop App Service                                        │
│    ✓ Deploy to Azure App Service                            │
│    ✓ Start App Service                                       │
│    ✓ Verify with health check                               │
└──────────────────────────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────────────────────────┐
│ 4. DEPLOY FRONTEND                                           │
│    ✓ Build Flutter web release                              │
│    ✓ Deploy to Azure Static Web Apps                        │
└──────────────────────────────────────────────────────────────┘
         ↓
┌──────────────────────────────────────────────────────────────┐
│ 5. NOTIFY                                                    │
│    ✓ Send success/failure notification                       │
│    ✓ Optional: Send Slack notification                       │
└──────────────────────────────────────────────────────────────┘
```

### On Pull Requests

- ✅ Runs backend build & test
- ✅ Runs frontend build & test
- ❌ Skips deployment
- Shows test results as PR checks

---

## 🚀 Quick Start

### 1. First Time Setup (5 minutes)

```bash
# Follow the setup guide
cat CICD_SETUP_GUIDE.md

# Configure GitHub secrets (see SECRETS_CONFIGURATION.md)
# 1. Get Azure credentials
# 2. Add to GitHub Settings → Secrets

# That's it! Ready to deploy
```

### 2. Test the Pipeline (10 minutes)

```bash
# Option A: Automatic (just push to main)
git push origin main

# Option B: Manual trigger
# Go to GitHub → Actions → Deploy to Azure → Run workflow

# Monitor the deployment
# Actions tab → Watch workflow execution
```

### 3. Verify Deployment

```bash
# Check backend is running
curl https://webapp-seevak-backend.azurewebsites.net/health

# Frontend: Check Azure Static Web Apps URL
# (available in Azure Portal)
```

---

## 📚 Documentation Guide

### 👤 For Setup & Installation
Start with: **CICD_SETUP_GUIDE.md**
- Complete step-by-step instructions
- Prerequisites checklist
- Azure resource creation
- Secret configuration

### 🔐 For Secrets Management
Start with: **SECRETS_CONFIGURATION.md**
- Required secrets list
- How to get each secret value
- Configuration steps
- Security best practices

### 🐛 For Troubleshooting
Start with: **TROUBLESHOOTING.md**
- Common errors & solutions
- Debugging procedures
- Performance optimization
- Rollback procedures

### ⚡ For Quick Reference
Start with: **QUICK_REFERENCE.md**
- Common commands
- Manual deployment steps
- Testing locally
- Cheat sheet format

---

## 🔧 Configuration

### Trigger Events

The workflow is triggered by:

1. **Push to `main` branch** → Full build + test + deploy
2. **Push to `develop` branch** → Full build + test + deploy (optional staging)
3. **Pull Request to `main`** → Build + test (no deployment)
4. **Manual Trigger** → Run workflow from GitHub UI

### Customization

Edit `workflows/deploy-to-azure.yml` to customize:

```yaml
# Environment variables (at top of file)
env:
  RESOURCE_GROUP: rg-seevak-care-prod          # Your Azure resource group
  BACKEND_APP_NAME: webapp-seevak-backend      # Your App Service name
  FLUTTER_VERSION: '3.41.6'                    # Flutter version
```

### Build Commands

- **Backend**: `python main.py` (configured in App Service)
- **Frontend**: `flutter build web --release`
- **Health Check**: `curl https://webapp-seevak-backend.azurewebsites.net/health`

---

## 🔑 Required Secrets

Before deployment, configure these in GitHub Settings → Secrets:

| Secret | Purpose | Where to Get |
|--------|---------|-------------|
| `AZUREAPPSERVICE_CLIENTID_*` | Azure AD App ID | Azure Portal → Azure AD |
| `AZUREAPPSERVICE_TENANTID_*` | Azure Tenant ID | Azure Portal → Azure AD |
| `AZUREAPPSERVICE_SUBSCRIPTIONID_*` | Azure Subscription ID | Azure Portal → Subscriptions |
| `AZURE_STATIC_WEB_APPS_API_TOKEN_*` | Static Web Apps Token | Azure Portal → Static Web Apps |
| `SLACK_WEBHOOK_URL` | Slack notifications (optional) | Slack Workspace → Apps |

See **SECRETS_CONFIGURATION.md** for detailed instructions.

---

## 📊 Workflow Status & Monitoring

### View Workflow Runs
```bash
# GitHub UI
https://github.com/YOUR_ORG/MedicalApp/actions

# Command line
gh run list
gh run view <RUN_ID> --log
```

### View Deployment Logs
```bash
# Backend logs
az webapp log tail --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod

# Frontend: Check Azure Static Web Apps
```

### Health Check
```bash
# Backend health
curl https://webapp-seevak-backend.azurewebsites.net/health

# Status page
az webapp show --name webapp-seevak-backend \
  --resource-group rg-seevak-care-prod --query state
```

---

## 🐛 Common Issues

| Issue | Solution |
|-------|----------|
| **Secrets not found** | Check secret names match exactly (case-sensitive) |
| **Azure login fails** | Verify OIDC is configured in Azure AD |
| **Backend won't start** | Check `main.py` exists and `requirements.txt` is valid |
| **Frontend build fails** | Run `flutter clean` and verify dependencies |
| **Health check timeout** | App may be slow to start; increase delay or disable check |

For more issues, see **TROUBLESHOOTING.md**.

---

## 🔄 How to Deploy

### Method 1: Automatic (Recommended)
```bash
# Make changes
git add .
git commit -m "Your changes"

# Push to main → Deployment starts automatically
git push origin main

# Monitor in GitHub Actions tab
```

### Method 2: Manual Trigger
1. Go to **Actions** tab
2. Select **"Deploy to Azure"**
3. Click **"Run workflow"**
4. Choose branch and settings
5. Click **"Run workflow"**

### Method 3: Deploy Only Backend/Frontend
Edit workflow to skip steps, or use manual Azure CLI deployment (see **QUICK_REFERENCE.md**).

---

## 🧪 Testing Locally

Before pushing to main, test locally:

```bash
# Test backend
cd backend
pip install -r requirements.txt
pylint app/ --disable=all --enable=E,F
pytest -v
python main.py

# Test frontend
cd frontend
flutter pub get
flutter analyze
flutter test
flutter build web --release
```

---

## 📈 Performance

- **Build Time**: ~5-10 minutes total
- **Backend Build**: ~2-3 minutes
- **Frontend Build**: ~3-5 minutes
- **Deployment**: ~3-5 minutes
- **Health Check**: ~2-3 minutes

### Speed Up Deployment

1. ✅ Use GitHub cache for dependencies (already enabled)
2. ✅ Run jobs in parallel (already enabled)
3. ✅ Skip tests on simple documentation updates
4. ✅ Use smaller Azure VM size if appropriate

---

## 🔒 Security

### Best Practices Implemented

- ✅ OIDC authentication (no shared secrets)
- ✅ Secrets masked in logs
- ✅ Secrets expire/rotate regularly
- ✅ Limited IAM permissions
- ✅ Encrypted in transit

### Your Responsibilities

1. **Keep secrets private**: Never commit secrets to git
2. **Rotate regularly**: Update secrets every 90 days
3. **Use HTTPS**: All communications encrypted
4. **Review access**: Check who has admin access
5. **Enable 2FA**: On GitHub and Azure accounts

---

## 📝 Maintenance

### Regular Tasks

| Frequency | Task | Command |
|-----------|------|---------|
| Weekly | Monitor workflow runs | `gh run list` |
| Monthly | Review logs and errors | GitHub Actions → Analytics |
| Quarterly | Rotate secrets | Azure Portal → Credentials |
| Quarterly | Update dependencies | `pip install -U` / `flutter pub upgrade` |
| Yearly | Review and update workflow | Check documentation for updates |

### Update Workflow

To update to the latest workflow version:

1. Check latest GitHub Actions best practices
2. Update `workflows/deploy-to-azure.yml`
3. Test on develop branch first
4. Merge to main for production use

---

## 🆘 Need Help?

### Documentation

1. **Setup Help**: See **CICD_SETUP_GUIDE.md**
2. **Configuration Help**: See **SECRETS_CONFIGURATION.md**
3. **Error Messages**: See **TROUBLESHOOTING.md**
4. **Quick Commands**: See **QUICK_REFERENCE.md**

### External Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure App Service Docs](https://learn.microsoft.com/en-us/azure/app-service/)
- [Azure Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/)
- [Flutter Web Documentation](https://flutter.dev/multi-platform/web)

### Getting Support

1. Check existing GitHub Issues
2. Search GitHub Discussions
3. Contact Azure Support (if Azure issue)
4. Contact team lead with:
   - Workflow run URL
   - Error message
   - Steps to reproduce

---

## 📋 Deployment Checklist

Before first deployment:

- [ ] Azure resources created (App Service, Static Web Apps)
- [ ] GitHub secrets configured (all 4 required)
- [ ] Backend has `requirements.txt` and `main.py`
- [ ] Frontend has `pubspec.yaml` and `lib/main.dart`
- [ ] Workflow file exists at `.github/workflows/deploy-to-azure.yml`
- [ ] Documentation reviewed
- [ ] Tested locally
- [ ] Manual workflow trigger successful
- [ ] Push to main and verify automatic deployment
- [ ] Backend health check passes
- [ ] Frontend displays correctly
- [ ] Slack notifications working (if configured)

---

## 📦 Deployment Artifacts

### Backend Deployment
- Format: ZIP file with backend directory contents
- Size: ~50-100 MB (depending on dependencies)
- Retention: 90 days (in GitHub Actions artifacts)

### Frontend Deployment
- Format: Flutter web build output (HTML/JS/CSS)
- Size: ~50-150 MB (depending on assets)
- Retention: Permanent (on Static Web Apps)

---

## 🎓 Learning Resources

### GitHub Actions

- [Official Tutorial](https://docs.github.com/en/actions/quickstart)
- [Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Best Practices](https://docs.github.com/en/actions/guides)

### Azure Deployment

- [App Service Deployment](https://learn.microsoft.com/en-us/azure/app-service/deploy-continuous-deployment)
- [Static Web Apps](https://learn.microsoft.com/en-us/azure/static-web-apps/overview)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/reference-index)

### Flask & Flutter

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Flutter Web Guide](https://flutter.dev/multi-platform/web)

---

## 📞 Support Contacts

- **GitHub Actions Issues**: GitHub Support
- **Azure Issues**: Azure Support Portal
- **Application Issues**: Your team lead
- **Deployment Issues**: DevOps team

---

## 📜 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | April 2026 | Initial CI/CD pipeline setup |

---

## 📄 License

This CI/CD pipeline is part of the Seevak Care project.

---

**Created**: April 2026
**Last Updated**: April 2026
**Maintained By**: DevOps Team

---

## 🎉 Next Steps

1. **Read Setup Guide**: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
2. **Configure Secrets**: [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md)
3. **Run First Deployment**: Push to main or use manual trigger
4. **Monitor Results**: Check GitHub Actions tab
5. **Bookmark Quick Reference**: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

Happy deploying! 🚀
