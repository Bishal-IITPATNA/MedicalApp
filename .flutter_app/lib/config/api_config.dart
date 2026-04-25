/// API Configuration for Seevak Care Medical App
/// Handles environment-based API endpoints and Azure service configurations

class ApiConfig {
  /// Base API URL for backend services
  /// Uses environment variable API_BASE_URL with fallback for development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000', // Development fallback - no /api suffix
  );

  /// Production API URL for Azure App Service
  static const String productionApiUrl = 'https://webapp-seevak-backend.azurewebsites.net/api';

  /// Azure Static Web Apps URL
  static const String staticWebAppUrl = 'https://seevak-care.azurestaticapps.net';

  /// Azure Application Insights Instrumentation Key
  /// Used for client-side telemetry and performance monitoring
  static const String appInsightsKey = String.fromEnvironment(
    'APPINSIGHTS_KEY',
    defaultValue: '', // Empty for development
  );

  /// Determine if running in production
  static bool get isProduction => baseUrl.contains('azurewebsites.net');

  /// Determine if running in development
  static bool get isDevelopment => !isProduction;

  /// API endpoints
  static const String authEndpoint = '/auth';
  static const String patientEndpoint = '/patients';
  static const String doctorEndpoint = '/doctors';
  static const String appointmentEndpoint = '/appointments';
  static const String prescriptionEndpoint = '/prescriptions';
  static const String medicalStoreEndpoint = '/medical-stores';
  static const String labEndpoint = '/labs';
  static const String notificationEndpoint = '/notifications';
  static const String paymentEndpoint = '/payments';

  /// Get full API URL for specific endpoint
  static String getApiUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// API timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Headers for API requests
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (appInsightsKey.isNotEmpty) 'X-AppInsights-Key': appInsightsKey,
  };

  /// Debug information (only available in debug mode)
  static Map<String, dynamic> get debugInfo => {
    'baseUrl': baseUrl,
    'isProduction': isProduction,
    'isDevelopment': isDevelopment,
    'appInsightsConfigured': appInsightsKey.isNotEmpty,
    'staticWebAppUrl': staticWebAppUrl,
  };
}
