import 'package:shared_preferences/shared_preferences.dart';

class SaveService {
  static const _keyHighScore = 'high_score';
  static const _keyTotalGames = 'total_games';
  static const _keyTotalWins = 'total_wins';
  static const _keySoundEnabled = 'sound_enabled';
  static const _keyMusicEnabled = 'music_enabled';

  late SharedPreferences _prefs;

  // Servisi başlatmak için uygulama açılışında çağrılır
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // === SKOR ===
  Future<void> saveHighScore(int score) async {
    final current = getHighScore();
    if (score > current) await _prefs.setInt(_keyHighScore, score);
  }
  int getHighScore() => _prefs.getInt(_keyHighScore) ?? 0;

  // === İSTATİSTİK ===
  Future<void> incrementGamesPlayed() async {
    await _prefs.setInt(_keyTotalGames, getTotalGames() + 1);
  }
  int getTotalGames() => _prefs.getInt(_keyTotalGames) ?? 0;

  Future<void> incrementWins() async {
    await _prefs.setInt(_keyTotalWins, getTotalWins() + 1);
  }
  int getTotalWins() => _prefs.getInt(_keyTotalWins) ?? 0;

  // === AYARLAR ===
  Future<void> setSoundEnabled(bool v) async => _prefs.setBool(_keySoundEnabled, v);
  bool isSoundEnabled() => _prefs.getBool(_keySoundEnabled) ?? true;

  Future<void> setMusicEnabled(bool v) async => _prefs.setBool(_keyMusicEnabled, v);
  bool isMusicEnabled() => _prefs.getBool(_keyMusicEnabled) ?? true;

  // === GENEL GETTER/SETTER (İleride offline kuyruk vs. için lazım olacak) ===
  Future<void> setString(String key, String value) async => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);
  
  Future<void> setBool(String key, bool value) async => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  // === RESET ===
  Future<void> resetAll() async => _prefs.clear();
}
