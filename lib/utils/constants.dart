class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emülatör için 10.0.2.2:3000, Web/iOS için localhost:3000
  );
}
