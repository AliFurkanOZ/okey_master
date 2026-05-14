class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://hip-bats-join.loca.lt/api', // Android emülatör → localhost
  );
}
