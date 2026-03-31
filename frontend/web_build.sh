#!/bin/bash
# Build Flutter web app for Azure Static Web Apps

# Clean previous builds
flutter clean
flutter pub get

# Get Application Insights key for Flutter build
APPINSIGHTS_KEY=$(az monitor app-insights component show \
  --resource-group rg-seevak-care-prod \
  --app insights-seevak-care \
  --query instrumentationKey \
  --output tsv)

# Build for web with environment variables
flutter build web --release \
  --dart-define=API_BASE_URL=https://webapp-seevak-backend.azurewebsites.net \
  --dart-define=APPINSIGHTS_KEY=$APPINSIGHTS_KEY \
  --web-renderer html

# Copy build to Azure Static Web Apps structure
mkdir -p azure-static-web-app
cp -r build/web/* azure-static-web-app/

echo "Web build completed for Azure deployment"
