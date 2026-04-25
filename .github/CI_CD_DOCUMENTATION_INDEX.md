# GitHub CI/CD Documentation Index

Complete reference guide to all CI/CD documentation and files.

## 📚 Documentation Files (Start Here!)

### 1. 🎯 **README.md** (START HERE)
Main overview document that explains the entire CI/CD pipeline.
- What the pipeline does
- Quick start guide
- File directory structure
- Common issues quick reference

**👉 Start here if you're new to the CI/CD pipeline**

---

## 📖 Detailed Guides

### 2. 🚀 **CICD_SETUP_GUIDE.md** (Setup Instructions)
Complete step-by-step guide for setting up the CI/CD pipeline from scratch.

**Contents:**
- Prerequisites checklist
- Azure resource creation
- GitHub secrets configuration
- Step-by-step setup walkthrough
- Workflow explanation
- Customization options
- Best practices

**👉 Use this when setting up for the first time**

---

### 3. 🔐 **SECRETS_CONFIGURATION.md** (Secret Management)
Detailed reference for all required GitHub Actions secrets.

**Contents:**
- List of all required secrets
- Where to get each secret value
- How to add secrets to GitHub
- Verification checklist
- Common secret issues
- Security best practices
- Rotating secrets

**👉 Use this when configuring or troubleshooting secrets**

---

### 4. 🐛 **TROUBLESHOOTING.md** (Error Resolution)
Comprehensive guide for resolving common CI/CD errors.

**Contents:**
- Common errors with solutions
- Debugging procedures
- Performance optimization
- Monitoring and alerts
- Rollback procedures
- Getting help

**Common Issues Covered:**
- Azure resource not found
- Python/Flutter build failures
- Authentication errors
- Deployment timeouts
- Health check failures
- Secret configuration issues

**👉 Use this when something breaks**

---

### 5. ⚡ **QUICK_REFERENCE.md** (Cheat Sheet)
Quick command reference and common tasks.

**Contents:**
- Workflow status commands
- Manual deployment steps
- Testing commands
- Log viewing commands
- Debugging commands
- Secrets management commands
- Rollback procedures
- Common scenarios
- Pre-deployment checklist

**Format:** Copy-paste ready commands

**👉 Use this for quick command reference**

---

## 🔄 Workflow Files

### 6. 📋 **workflows/deploy-to-azure.yml** (MAIN WORKFLOW)
The primary GitHub Actions workflow configuration file.

**What it does:**
- Builds and tests backend (Python/Flask)
- Builds and tests frontend (Flutter web)
- Deploys backend to Azure App Service
- Deploys frontend to Azure Static Web Apps
- Sends notifications on success/failure

**When it runs:**
- On push to `main` branch → Full deployment
- On push to `develop` branch → Optional staging deployment
- On PR to `main` → Tests only (no deployment)
- Manual trigger via GitHub UI

**How to customize:**
- Edit environment variables at top
- Add/remove steps
- Modify triggers in `on:` section
- Adjust timeouts
- Change build commands

**👉 Edit this to customize the workflow**

---

### 7. 📋 **workflows/main_webapp-seevak-backend.yml** (Legacy)
Original backend deployment workflow - kept for reference.

**Status:** Superseded by deploy-to-azure.yml (but kept as backup)

---

### 8. 📋 **workflows/azure-static-web-apps-brave-smoke-045200400.yml** (Legacy)
Original frontend deployment workflow - kept for reference.

**Status:** Superseded by deploy-to-azure.yml (but kept as backup)

---

### 9. 📋 **workflows/azure-deploy.yml** (Legacy)
Original combined deployment workflow - kept for reference.

**Status:** Superseded by deploy-to-azure.yml (but kept as backup)

---

## 🛠️ Helper Scripts

### 10. 📝 **test-locally.sh** (Local Testing - Linux/Mac)
Bash script to test the CI/CD workflow locally before pushing.

**How to use:**
```bash
chmod +x .github/test-locally.sh
.github/test-locally.sh [options]
```

**Options:**
- `--skip-tests` - Skip running tests
- `--skip-build` - Skip building
- `--skip-lint` - Skip linting
- `--verbose` - Verbose output
- `--help` - Show help

**What it does:**
1. Verifies all prerequisites
2. Runs backend tests
3. Runs frontend tests
4. Tests deployment package creation
5. Reports results

**👉 Run this before pushing to main**

---

### 11. 📝 **test-locally.ps1** (Local Testing - Windows)
PowerShell script to test the CI/CD workflow locally on Windows.

**How to use:**
```powershell
powershell -ExecutionPolicy Bypass -File .github\test-locally.ps1 [options]
```

**Options:**
- `--skip-tests` - Skip running tests
- `--skip-build` - Skip building
- `--skip-lint` - Skip linting
- `--verbose` - Verbose output
- `--help` - Show help

**What it does:**
1. Verifies all prerequisites (Python, Flutter, etc.)
2. Installs dependencies
3. Runs backend tests
4. Runs frontend tests
5. Tests deployment package
6. Reports summary

**👉 Run this on Windows before pushing to main**

---

## 📊 File Structure

```
.github/
├── README.md                                    ← START HERE
├── CICD_SETUP_GUIDE.md                         ← Setup instructions
├── SECRETS_CONFIGURATION.md                    ← Secret management
├── TROUBLESHOOTING.md                          ← Error resolution
├── QUICK_REFERENCE.md                          ← Command cheat sheet
├── CI_CD_DOCUMENTATION_INDEX.md                ← This file
├── test-locally.sh                             ← Local testing (Linux/Mac)
├── test-locally.ps1                            ← Local testing (Windows)
└── workflows/
    ├── deploy-to-azure.yml                     ← MAIN WORKFLOW
    ├── main_webapp-seevak-backend.yml          ← Legacy backend
    ├── azure-static-web-apps-*.yml             ← Legacy frontend
    └── azure-deploy.yml                        ← Legacy combined
```

---

## 🎓 Learning Paths

### Path 1: First Time Setup (30 minutes)
1. Read: **README.md** (5 min)
2. Read: **CICD_SETUP_GUIDE.md** (15 min)
3. Complete: All setup steps (10 min)

### Path 2: Troubleshooting Deployment (10 minutes)
1. Check: **TROUBLESHOOTING.md** common issues
2. View: Workflow logs
3. Run: `test-locally.sh` or `test-locally.ps1`

### Path 3: Daily Operations (5 minutes)
1. Reference: **QUICK_REFERENCE.md**
2. Copy: Relevant command
3. Execute: In terminal

### Path 4: Understanding the Workflow (15 minutes)
1. Read: **README.md** - Workflow Overview section
2. Read: **CICD_SETUP_GUIDE.md** - Understanding the Workflow section
3. Review: **workflows/deploy-to-azure.yml** comments

---

## 🔍 Finding Information

### I want to...

#### **Set up the pipeline for the first time**
→ Read [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)

#### **Configure GitHub secrets**
→ Read [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md)

#### **Fix a deployment error**
→ Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

#### **Deploy manually**
→ Read [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Manual Deployment section

#### **Test my changes locally**
→ Run `test-locally.sh` (Mac/Linux) or `test-locally.ps1` (Windows)

#### **View deployment logs**
→ Read [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Viewing Logs section

#### **Understand the workflow**
→ Read [README.md](./README.md) - Workflow Flow section

#### **Customize the workflow**
→ Edit [workflows/deploy-to-azure.yml](./workflows/deploy-to-azure.yml) and read comments

#### **Rollback a deployment**
→ Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Rollback Procedures section

#### **Optimize deployment speed**
→ Read [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Performance Optimization section

#### **Monitor deployments**
→ Read [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Workflow Status section

#### **Run pre-deployment checks**
→ Run [test-locally.sh](./test-locally.sh) or [test-locally.ps1](./test-locally.ps1)

---

## 📋 Checklist: Complete Setup

- [ ] Read [README.md](./README.md)
- [ ] Follow [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
- [ ] Configure GitHub secrets using [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md)
- [ ] Run local tests: `test-locally.sh` or `test-locally.ps1`
- [ ] Push to main branch
- [ ] Monitor workflow in GitHub Actions
- [ ] Verify deployment success
- [ ] Bookmark [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- [ ] Bookmark [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 🔗 Quick Links

| Document | Purpose | Read Time |
|----------|---------|-----------|
| [README.md](./README.md) | Overview & quick start | 5 min |
| [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md) | Complete setup guide | 15 min |
| [SECRETS_CONFIGURATION.md](./SECRETS_CONFIGURATION.md) | Secret configuration | 10 min |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | Error resolution | 20 min |
| [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | Command cheat sheet | 5 min |
| [workflows/deploy-to-azure.yml](./workflows/deploy-to-azure.yml) | Workflow configuration | 10 min |

---

## 🆘 Getting Help

### Quick Help
1. Check [README.md](./README.md) - Common Issues section
2. Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Your specific error
3. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Relevant commands

### Detailed Help
1. Read full [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
2. Review [workflows/deploy-to-azure.yml](./workflows/deploy-to-azure.yml) comments
3. Check GitHub Actions logs

### If You're Still Stuck
1. Check GitHub Actions logs
2. Run `test-locally.sh` or `test-locally.ps1`
3. Review [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) - Debugging Steps section
4. Contact team lead with:
   - Error message
   - Workflow run URL
   - Recent changes

---

## 📝 Document Versions

| Document | Version | Last Updated | Status |
|----------|---------|--------------|--------|
| README.md | 1.0 | April 2026 | Current |
| CICD_SETUP_GUIDE.md | 1.0 | April 2026 | Current |
| SECRETS_CONFIGURATION.md | 1.0 | April 2026 | Current |
| TROUBLESHOOTING.md | 1.0 | April 2026 | Current |
| QUICK_REFERENCE.md | 1.0 | April 2026 | Current |
| deploy-to-azure.yml | 1.0 | April 2026 | Current |

---

## 🎯 Recommendations

### For New Team Members
1. Start with: [README.md](./README.md)
2. Then read: [CICD_SETUP_GUIDE.md](./CICD_SETUP_GUIDE.md)
3. Try: Running `test-locally.sh` or `test-locally.ps1`
4. Bookmark: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)

### For Daily Development
1. Keep open: [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
2. Before push: Run local tests
3. After deployment: Monitor in GitHub Actions

### For Troubleshooting
1. First: Check [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)
2. Then: Run local tests
3. Finally: Check GitHub Actions logs

---

## 📚 External Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure App Service Docs](https://learn.microsoft.com/azure/app-service/)
- [Azure Static Web Apps](https://learn.microsoft.com/azure/static-web-apps/)
- [Flutter Web Documentation](https://flutter.dev/multi-platform/web)
- [Flask Documentation](https://flask.palletsprojects.com/)

---

**Created**: April 2026
**Last Updated**: April 2026
**Maintained By**: DevOps Team

---

## 📖 How to Use This Index

1. **Find what you need** in the "I want to..." section above
2. **Click the link** to go to the relevant document
3. **Read** the specific section you need
4. **Refer back** to [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) for commands

**Everything you need is documented. Start with [README.md](./README.md)!**
