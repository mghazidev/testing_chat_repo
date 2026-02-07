class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://chat.softexsolution.com',
  );

  static const String apiVersion = 'v1';
  static String get apiBase => '$baseUrl/api/$apiVersion';

  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'https://chat.softexsolution.com',
  );
}
