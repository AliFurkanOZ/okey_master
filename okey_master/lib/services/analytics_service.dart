import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Oyun başladığında çağrılacak
  Future<void> logGameStart(String gameMode) async {
    await _analytics.logEvent(name: 'game_started', parameters: {'game_mode': gameMode});
  }

  // Oyun bittiğinde çağrılacak (Kazandı mı, skoru ne vs.)
  Future<void> logGameEnd({required bool won, required int score, required int turns}) async {
    await _analytics.logEvent(name: 'game_ended', parameters: {
      'result': won ? 'win' : 'lose',
      'score': score,
      'turns_played': turns,
    });
  }

  // Kullanıcı reklam izlediğinde çağrılacak
  Future<void> logAdWatched(String adType) async {
    await _analytics.logEvent(name: 'ad_watched', parameters: {'ad_type': adType});
  }

  // Hangi ekranda ne kadar gezdiğini görmek için
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
