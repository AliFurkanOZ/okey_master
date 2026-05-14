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
  static Future<Map<String, dynamic>> registerPlayer(String nickname) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/auth/register"),
        headers: await _headers(),
        body: jsonEncode({"username": nickname}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'status': response.statusCode, 'username': data['username']};
      } else {
        return {'status': response.statusCode, 'username': null};
      }
    } catch (e) {
      return {'status': 500, 'username': null};
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
      final headers = await _headers();
      final body = jsonEncode({
        "username": nickname,
        "isWin": isWin,
        "duration": duration,
        "gameType": type
      });
      
      print("[ApiService.sendResult] İstek gönderiliyor: $_baseUrl/games/result");
      print("[ApiService.sendResult] Body: $body");
      print("[ApiService.sendResult] Token: ${headers['Authorization']?.substring(0, 30)}...");
      
      final response = await http.post(
        Uri.parse("$_baseUrl/games/result"),
        headers: headers,
        body: body,
      ).timeout(const Duration(seconds: 10));
      
      print("[ApiService.sendResult] STATUS: ${response.statusCode}");
      print("[ApiService.sendResult] BODY: ${response.body}");
      
      if (response.statusCode >= 300) {
         throw ApiException("Sunucu Hatası: ${response.body}", statusCode: response.statusCode);
      }
    } catch (e) {
      print("[ApiService.sendResult] !!! HATA !!! $e");
      throw ApiException("İnternet bağlantısı yok veya sunucuya ulaşılamadı: $e");
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