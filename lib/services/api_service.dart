import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:3000/api";

  // 1. Kayıt Metodu
  static Future<int> registerPlayer(String nickname) async {
    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": nickname}),
      );
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  // 2. ESKİ DÜELLO METODU (Ekranın hata vermemesi için yeni sisteme bağladık)
  static Future<void> updateDuelScore(String nickname) async {
    // Kazanan için otomatik 'true' gönderiyoruz (50 puan için)
    await sendResult(nickname: nickname, isWin: true, type: "duel");
  }

  // 3. ESKİ HAFIZA METODU (Ekranın hata vermemesi için yeni sisteme bağladık)
  static Future<void> updateMemoryScore(String nickname, String diff, int duration) async {
    // Rekor süreyi saniye cinsinden gönderiyoruz
    await sendResult(nickname: nickname, isWin: true, duration: duration, type: "memory_$diff");
  }

  // 4. YENİ ANA VERİ GÖNDERME METODU (Sunucuyla konuşan asıl kısım)
  static Future<void> sendResult({
    required String nickname, 
    required bool isWin, 
    int? duration, 
    required String type
  }) async {
    try {
      await http.post(
        Uri.parse("$baseUrl/games/result"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": nickname,
          "isWin": isWin,
          "duration": duration, // Hafıza için saniye
          "gameType": type      // "duel" veya "memory"
        }),
      );
    } catch (e) {
      print("Veri gönderilemedi: $e");
    }
  }

  // 5. LİDERLİK TABLOSU
  static Future<List<dynamic>> getLeaderboard(String type) async {
    try {
      final res = await http.get(Uri.parse("$baseUrl/leaderboard?type=$type"));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("Liderlik çekilemedi: $e");
    }
    return [];
  }
}