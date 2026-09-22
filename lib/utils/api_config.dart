/// Runtime API configuration.
///
/// Override at build/run time:
/// `flutter run --dart-define=API_BASE_URL=https://optilens.example.com`
/// `flutter run --dart-define=ERP_BASE_URL=https://erp.example.com --dart-define=ERP_API_TOKEN=...`
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://optilens.jethings.com',
  );

  static const String erpBaseUrl = String.fromEnvironment(
    'ERP_BASE_URL',
    defaultValue: 'https://erp.jethings.com',
  );

  /// Frappe resource API token. Never commit a real value; pass it via dart-define.
  static const String erpApiToken = String.fromEnvironment('ERP_API_TOKEN');

  static const String apiMethodPath = '$baseUrl/api/method/';
  static const String mobileAppApiPath = '${apiMethodPath}mobile_app.api.';
}
