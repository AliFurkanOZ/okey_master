class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://172.17.9.87:3000/api', // Android emülatör → localhost
  );
}
