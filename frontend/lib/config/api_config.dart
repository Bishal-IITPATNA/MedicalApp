class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://webapp-seevak-backend.azurewebsites.net/api'
  );
  
  // Azure Static Web Apps configuration
  static const String staticWebAppUrl = 'https://seevak-care.azurestaticapps.net';
  
  // Azure Application Insights
  static const String appInsightsKey = String.fromEnvironment('APPINSIGHTS_KEY');
}
