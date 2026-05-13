import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static String get _baseUrl => AppConstants.apiBaseUrl;

  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Kayıt Metodu
  static Future<int> registerPlayer(String nickname) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/register"),
        headers: await _headers(),
        body: jsonEncode({"username": nickname}),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode;
    } catch (e) {
      return 500;
    }
  }

  // 2. ESKİ DÜELLO METODU
  static Future<void> updateDuelScore(String nickname) async {
    await sendResult(nickname: nickname, isWin: true, type: "duel");
  }

  // 3. ESKİ HAFIZA METODU
  static Future<void> updateMemoryScore(String nickname, String diff, int duration) async {
    await sendResult(nickname: nickname, isWin: true, duration: duration, type: "memory_$diff");
  }

  // 4. YENİ ANA VERİ GÖNDERME METODU
  static Future<void> sendResult({
    required String nickname, 
    required bool isWin, 
    int? duration, 
    required String type
  }) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/games/result"),
        headers: await _headers(),
        body: jsonEncode({
          "username": nickname,
          "isWin": isWin,
          "duration": duration,
          "gameType": type
        }),
      ).timeout(const Duration(seconds: 10));
      
      print("SERVER RESULT STATUS: ${response.statusCode}");
      print("SERVER RESULT BODY: ${response.body}");
      
      if (response.statusCode >= 300) {
         throw ApiException("Sunucu Hatası", statusCode: response.statusCode);
      }
    } catch (e) {
      print("!!! Veri gönderilemedi !!! HATA: $e");
      throw ApiException("İnternet bağlantısı yok veya sunucuya ulaşılamadı.");
    }
  }

  // 5. LİDERLİK TABLOSU
  static Future<List<dynamic>> getLeaderboard(String type) async {
    try {
      final res = await http.get(
        Uri.parse("$_baseUrl/leaderboard?type=$type"),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (e) {
      print("Liderlik çekilemedi: $e");
    }
    return [];
  }
}