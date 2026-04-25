# GitHub Actions Secrets & Environment Configuration

This file documents all required GitHub Actions secrets and variables. Use this as a checklist for setup.

## Required Secrets (⚠️ MUST CONFIGURE)

### Azure OIDC Authentication Secrets

These secrets enable secure, keyless authentication with Azure using OpenID Connect (OIDC).

```
Secret Name: AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21
Description: Azure AD Application Client ID
Value: <Get from Azure Portal>
How to get:
  1. Azure Portal → Azure Active Directory → App registrations
  2. Find the GitHub Actions application
  3. Copy "Application (client) ID"
  4. Add to GitHub Secrets with exact name above
```

```
Secret Name: AZUREAPPSERVICE_TENANTID_2DD5AD037E6E439AAD7D3BF85369D565
Description: Azure AD Tenant ID
Value: <Get from Azure Portal>
How to get:
  1. Azure Portal → Azure Active Directory → Overview
  2. Copy "Tenant ID"
  3. Add to GitHub Secrets with exact name above
```

```
Secret Name: AZUREAPPSERVICE_SUBSCRIPTIONID_55D71896B10244CCA1DA74C96776A35C
Description: Azure Subscription ID
Value: <Get from Azure Portal>
How to get:
  1. Azure Portal → Subscriptions
  2. Select your subscription
  3. Copy "Subscription ID"
  4. Add to GitHub Secrets with exact name above
```

### Azure Static Web Apps Deployment Token

```
Secret Name: AZURE_STATIC_WEB_APPS_API_TOKEN_BRAVE_SMOKE_045200400
Description: Deployment token for Azure Static Web Apps
Value: <Get from Azure Portal>
How to get:
  1. Azure Portal → Static Web Apps → seevak-care-frontend
  2. Click "Settings" → "Deployment Token"
  3. Copy the token
  4. Add to GitHub Secrets with exact name above
```

## Optional Secrets (For Additional Features)

### Slack Notifications

```
Secret Name: SLACK_WEBHOOK_URL
Description: Webhook URL for sending Slack notifications on deployment
Value: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
How to get:
  1. Slack Workspace → Settings & Administration
  2. Apps & integrations → Build → Create New App
  3. Incoming Webhooks → Add New Webhook to Workspace
  4. Copy the webhook URL
  5. Add to GitHub Secrets (OPTIONAL)
```

## GitHub Variables (Optional)

Variables are less sensitive than secrets and can be used for configuration.

```
Variable Name: SLACK_WEBHOOK_URL
Description: Enable Slack notifications if set
Scope: Repository
Type: String (optional)
```

## GitHub Token (Auto-generated)

✅ **GITHUB_TOKEN** - Automatically provided by GitHub Actions
- No configuration needed
- Used for GitHub integrations (PR comments, etc.)
- Automatically expires after workflow completion

## Setup Instructions

### Step 1: Get to Secrets Configuration

1. Go to your GitHub repository
2. Click **Settings** (top navigation)
3. In left sidebar, click **Secrets and variables** → **Actions**

### Step 2: Add Azure OIDC Secrets

For each Azure secret listed above:
1. Click **New repository secret**
2. Enter exact secret name
3. Paste the value from Azure
4. Click **Add secret**

### Step 3: Add Static Web Apps Token

1. Click **New repository secret**
2. Name: `AZURE_STATIC_WEB_APPS_API_TOKEN_BRAVE_SMOKE_045200400`
3. Value: Your deployment token from Static Web Apps
4. Click **Add secret**

### Step 4 (Optional): Add Slack Webhook

1. Click **New repository secret**
2. Name: `SLACK_WEBHOOK_URL`
3. Value: Your Slack webhook URL
4. Click **Add secret**

## Verification Checklist

After adding all secrets, verify they're configured:

- [ ] `AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21` - Added ✓
- [ ] `AZUREAPPSERVICE_TENANTID_2DD5AD037E6E439AAD7D3BF85369D565` - Added ✓
- [ ] `AZUREAPPSERVICE_SUBSCRIPTIONID_55D71896B10244CCA1DA74C96776A35C` - Added ✓
- [ ] `AZURE_STATIC_WEB_APPS_API_TOKEN_BRAVE_SMOKE_045200400` - Added ✓
- [ ] `SLACK_WEBHOOK_URL` (optional) - Added ✓

## Common Issues

### ❌ Secret Not Found Error

If workflow fails with "secret not found":

1. **Verify exact secret name** - GitHub secret names are case-sensitive
2. **Check for typos** - Even a single character difference will cause failure
3. **Confirm secret exists** - Go to Settings → Secrets to verify
4. **Re-add the secret** - Delete and recreate the secret

### ❌ Authentication Failed

If Azure login fails:

1. **Verify OIDC setup** - Ensure federated credentials are created
2. **Check subscription ID** - Make sure subscription still exists
3. **Verify tenant ID** - Confirm Azure AD tenant hasn't changed
4. **Test locally**:
   ```bash
   az login --service-principal \
     -u $AZURE_CLIENT_ID \
     -t $AZURE_TENANT_ID
   ```

### ❌ Deployment Token Expired

If Static Web Apps deployment fails:

1. Go to Azure Portal
2. Navigate to Static Web Apps resource
3. Click **Settings** → **Deployment Token**
4. Click **Regenerate** to get a new token
5. Update the GitHub secret with the new token

## Security Best Practices

✅ **DO:**
- Use OIDC authentication (no shared secrets needed)
- Rotate secrets regularly
- Use separate secrets for different environments
- Enable secret scanning in repository settings
- Use masked values in logs

❌ **DON'T:**
- Commit secrets to version control
- Share secrets via email or chat
- Use the same secret across multiple services
- Log secrets in workflow output
- Use placeholder values in actual deployments

## Testing Secrets

To verify secrets are accessible in workflow (without exposing values):

```yaml
- name: Verify secrets are configured
  run: |
    if [ -z "${{ secrets.AZUREAPPSERVICE_CLIENTID_78440EA0F40F4DD097867124C2D67F21 }}" ]; then
      echo "❌ AZUREAPPSERVICE_CLIENTID not configured"
      exit 1
    fi
    echo "✅ All required secrets are configured"
```

## Environment-Specific Secrets

For different environments (staging, production):

1. Create environments in GitHub:
   Settings → Environments → New environment
   - `production`
   - `staging`

2. Add environment-specific secrets:
   - Each environment can have its own secrets
   - Workflow can reference them: `${{ secrets.SECRET_NAME }}`

3. Configure deployment protection rules:
   - Require approval before deployment
   - Restrict to specific branches

## Rotating Secrets

To rotate a secret safely:

1. Generate new value from Azure Portal
2. Update the GitHub secret (Settings → Secrets)
3. Next workflow run will use new secret
4. Monitor for deployment success
5. Delete old credential from Azure if applicable

---

**Last Updated**: April 2026
**Secret Version**: 1.0

**Need Help?**
- GitHub Actions Docs: https://docs.github.com/actions
- Azure CLI Docs: https://learn.microsoft.com/cli/azure
- Contact: [Your team contact info]
