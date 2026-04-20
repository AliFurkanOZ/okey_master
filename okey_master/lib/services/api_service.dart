import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../utils/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  final String _baseUrl = AppConstants.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, String>> _headers() async {
    final user = _auth.currentUser;
    final token = user != null ? await user.getIdToken() : '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Güvenli GET (Timeout: 10s)
  Future<Map<String, dynamic>> _safeGet(String path) async {
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl$path'),
        headers: await _headers(),
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      } else if (res.statusCode == 401) {
        throw ApiException('Oturum süresi doldu', statusCode: 401);
      } else {
        throw ApiException('Sunucu hatası', statusCode: res.statusCode);
      }
    } on SocketException {
      throw ApiException('İnternet bağlantısı yok');
    } on FormatException {
      throw ApiException('Geçersiz sunucu yanıtı');
    }
  }

  // Güvenli POST (Timeout default 10s)
  Future<Map<String, dynamic>> _safePost(String path, Map<String, dynamic> body, {int timeoutSec = 10, String? idempotencyKey}) async {
    try {
      final headers = await _headers();
      if (idempotencyKey != null) {
        headers['X-Idempotency-Key'] = idempotencyKey;
      }

      final res = await http.post(
        Uri.parse('$_baseUrl$path'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(Duration(seconds: timeoutSec));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        return jsonDecode(res.body);
      } else {
        throw ApiException('İşlem başarısız', statusCode: res.statusCode);
      }
    } on SocketException {
      throw ApiException('İnternet bağlantısı yok');
    }
  }

  // === ENDPOINT'LER ===

  Future<Map<String, dynamic>> register(String username) async {
    return _safePost('/auth/register', {'username': username});
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _safeGet('/auth/profile');
  }

  Future<Map<String, dynamic>> createGame(String mode) async {
    return _safePost('/games', {'mode': mode});
  }

  // Oyun bitirme işlemi uzun sürebilir, Prisma tarafı 15s bekler, biz 20s timeout veriyoruz.
  Future<Map<String, dynamic>> finishGame(String gameId, Map<String, dynamic> data) async {
    final idempotencyKey = data['idempotencyKey'] ?? const Uuid().v4();
    data['idempotencyKey'] = idempotencyKey;
    
    return _safePost(
      '/games/$gameId/finish', 
      data, 
      timeoutSec: 20, 
      idempotencyKey: idempotencyKey
    );
  }

  Future<List<dynamic>> getLeaderboard(String period) async {
    final res = await _safeGet('/leaderboard/$period');
    return res as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMyStats() async {
    return _safeGet('/stats/me');
  }
}
