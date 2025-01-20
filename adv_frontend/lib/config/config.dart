class Config {
  static const String baseUrl = 'PUBLIC_IP_ADDRESS';
  static const String apiUrl = 'http://$baseUrl';

  // Platform-specific configurations
  static String getPlatformUrl() {
    return apiUrl;
  }

  // Add any additional configuration values here
  static const String apiVersion = 'v1';
  static const Duration timeout = Duration(seconds: 30);
}
