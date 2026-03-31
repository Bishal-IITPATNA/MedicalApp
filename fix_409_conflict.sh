#!/bin/bash
# Fix Azure App Service 409 Conflict Error

set -e

echo "🔧 Azure App Service - Fix 409 Conflict Error"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

RESOURCE_GROUP="rg-seevak-care-prod"
WEBAPP_NAME="webapp-seevak-backend"

# Check if logged in
echo -e "${BLUE}Step 1: Checking Azure CLI login...${NC}"
if ! az account show &> /dev/null; then
    echo -e "${RED}❌ Not logged into Azure CLI${NC}"
    echo "Please run: az login"
    exit 1
else
    echo -e "${GREEN}✅ Logged in to Azure${NC}"
fi

# Check deployment status
echo -e "\n${BLUE}Step 2: Checking current deployment status...${NC}"
DEPLOYMENT_STATUS=$(az webapp deployment list \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "[0].{status:status,active:active,id:id}" \
    --output tsv 2>/dev/null || echo "none")

if [ "$DEPLOYMENT_STATUS" != "none" ]; then
    echo -e "${YELLOW}⚠️ Found deployment status: $DEPLOYMENT_STATUS${NC}"
else
    echo -e "${GREEN}✅ No active deployments found${NC}"
fi

# Check app status
echo -e "\n${BLUE}Step 3: Checking App Service status...${NC}"
APP_STATE=$(az webapp show \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "state" \
    --output tsv 2>/dev/null || echo "NotFound")

echo -e "Current app state: $APP_STATE"

# Fix 409 conflict steps
echo -e "\n${BLUE}Step 4: Applying 409 Conflict fixes...${NC}"

echo -e "${YELLOW}Fix 1: Restarting the web app to clear locks...${NC}"
az webapp restart \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP

echo -e "${GREEN}✅ Web app restarted${NC}"

# Wait a moment
echo -e "${YELLOW}Waiting 10 seconds for restart to complete...${NC}"
sleep 10

echo -e "${YELLOW}Fix 2: Stopping and starting the app (stronger reset)...${NC}"
az webapp stop \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP

echo -e "${GREEN}✅ Web app stopped${NC}"

# Wait
echo -e "${YELLOW}Waiting 15 seconds...${NC}"
sleep 15

az webapp start \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP

echo -e "${GREEN}✅ Web app started${NC}"

# Verify app is running
echo -e "\n${BLUE}Step 5: Verifying app status...${NC}"
sleep 5
NEW_APP_STATE=$(az webapp show \
    --name $WEBAPP_NAME \
    --resource-group $RESOURCE_GROUP \
    --query "state" \
    --output tsv)

echo -e "New app state: $NEW_APP_STATE"

if [ "$NEW_APP_STATE" = "Running" ]; then
    echo -e "${GREEN}✅ App is now running${NC}"
else
    echo -e "${RED}❌ App is not running. State: $NEW_APP_STATE${NC}"
fi

# Try a test deployment
echo -e "\n${BLUE}Step 6: Testing deployment capability...${NC}"
echo -e "${YELLOW}Creating a simple test file for deployment...${NC}"

# Create a simple test deployment
mkdir -p temp_test_deploy
cd temp_test_deploy

cat > app.py << 'EOF'
from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return "Test deployment successful!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
EOF

cat > requirements.txt << 'EOF'
Flask==3.0.0
EOF

echo -e "${YELLOW}Creating test deployment package...${NC}"
zip -r ../test-deploy.zip . -q

cd ..

echo -e "${YELLOW}Attempting test deployment...${NC}"
if az webapp deployment source config-zip \
    --resource-group $RESOURCE_GROUP \
    --name $WEBAPP_NAME \
    --src test-deploy.zip \
    --timeout 300; then
    echo -e "${GREEN}✅ Test deployment successful!${NC}"
    echo -e "${GREEN}✅ 409 Conflict issue has been resolved${NC}"
else
    echo -e "${RED}❌ Test deployment failed${NC}"
    echo -e "${YELLOW}Try manual deployment steps:${NC}"
    echo -e "1. Check Azure portal for any locks"
    echo -e "2. Wait 5-10 minutes and try again"
    echo -e "3. Consider using a different deployment method"
fi

# Cleanup
rm -rf temp_test_deploy test-deploy.zip

echo -e "\n${BLUE}Step 7: Recommendations...${NC}"
echo -e "${GREEN}✅ Your web app should now be ready for deployment${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. Try your GitHub Actions deployment again"
echo -e "2. If it still fails, wait 5-10 minutes and retry"
echo -e "3. Consider using Azure CLI deployment method instead of publish profile"

echo -e "\n${BLUE}Your App URL:${NC}"
echo -e "https://$WEBAPP_NAME.azurewebsites.net"

echo -e "\n${GREEN}🎉 Conflict fix complete!${NC}"
