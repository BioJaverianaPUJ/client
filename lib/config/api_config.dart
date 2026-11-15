abstract final class ApiConfig {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://biojaveriana.downloadablefox.dev/api/v1',
  );

  static const timeout = Duration(seconds: 20);
}
