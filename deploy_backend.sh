#!/bin/bash

# Seevak Care Backend Deployment Script for Azure App Service
# This script creates a properly structured ZIP file and deploys it to Azure

set -e  # Exit on any error

# Configuration
RESOURCE_GROUP="rg-seevak-care-prod"
APP_NAME="webapp-seevak-backend"
BACKEND_DIR="backend"

echo "🚀 Starting Seevak Care Backend Deployment..."

# Check if we're in the right directory
if [ ! -d "$BACKEND_DIR" ]; then
    echo "❌ Error: backend directory not found. Please run this script from the project root."
    exit 1
fi

# Check required files
if [ ! -f "$BACKEND_DIR/main.py" ]; then
    echo "❌ Error: main.py not found in backend directory."
    exit 1
fi

if [ ! -f "$BACKEND_DIR/requirements.txt" ]; then
    echo "❌ Error: requirements.txt not found in backend directory."
    exit 1
fi

# Create deployment ZIP with proper structure
echo "📦 Creating deployment package..."
cd "$BACKEND_DIR"

# Create ZIP file with backend contents at root level
zip -r ../backend-deploy.zip . -x "*.git*" "**/__pycache__/**" "*.pyc" "**/.*" "**/.DS_Store"

cd ..

# Verify ZIP contents
echo "📂 ZIP package contents:"
unzip -l backend-deploy.zip | head -20

# Deploy to Azure App Service
echo "🌐 Deploying to Azure App Service: $APP_NAME..."

# Stop the app service to prevent conflicts
echo "⏸️  Stopping app service..."
az webapp stop --name "$APP_NAME" --resource-group "$RESOURCE_GROUP" || true

# Set startup command
echo "⚙️  Configuring startup command..."
az webapp config set \
  --name "$APP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --startup-file "python main.py" || true

# Deploy the ZIP file
echo "📤 Uploading application code..."
az webapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$APP_NAME" \
  --src backend-deploy.zip

# Start the app service
echo "▶️  Starting app service..."
az webapp start --name "$APP_NAME" --resource-group "$RESOURCE_GROUP"

# Cleanup
rm backend-deploy.zip

echo "✅ Deployment completed successfully!"
echo "🌍 Your app should be available at: https://$APP_NAME.azurewebsites.net"
echo "🔍 Check logs with: az webapp log tail --name $APP_NAME --resource-group $RESOURCE_GROUP"

# Wait a moment and test the health endpoint
echo "⏳ Waiting for app to start..."
sleep 10

echo "🏥 Testing health endpoint..."
curl -s "https://$APP_NAME.azurewebsites.net/health" || echo "Health check failed - app may still be starting"

echo "🎉 Deployment script finished!"
