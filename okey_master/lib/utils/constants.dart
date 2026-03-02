// lib/utils/constants.dart
class AppConstants {
  // Ortama göre değişir. Hardcode yazmıyoruz!
  // Çalıştırma: flutter run --dart-define=API_URL=https://okey-master-api.railway.app/api
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api', // geliştirme ortamı
  );
  static const int turnDurationSeconds = 30;
  static const int totalTiles = 106;
  static const int handSize = 14;
  static const int firstPlayMinPoints = 30;
}
