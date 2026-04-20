import 'dart:convert';
import 'save_service.dart';
import 'api_service.dart';
import 'connectivity_service.dart';

class SyncQueueService {
  static const _queueKey = 'pending_game_results';
  static const _dlqKey = 'dead_letter_queue'; // Düzeltilemeyen hatalar (Dead Letter Queue)
  static const _maxRetries = 5;

  final SaveService _save;
  final ApiService _api;
  final ConnectivityService _connectivity;

  SyncQueueService(this._save, this._api, this._connectivity) {
    // İnternet durumunu dinle, gelince kuyruğu otomatik işlemeye başla
    _connectivity.onConnectivityChanged.listen((isOnline) {
      if (isOnline) processQueue();
    });
  }

  /// Skoru kuyruğa ekle (Offline biten oyun)
  Future<void> enqueue(String gameId, Map<String, dynamic> data) async {
    final queue = _getPendingQueue();
    queue.add({
      'gameId': gameId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'retryCount': 0,
    });
    await _save.setString(_queueKey, jsonEncode(queue));
  }

  /// İnternet gelince kuyruktakileri API'ye gönder (Poison Pill Korumalı)
  Future<void> processQueue() async {
    if (!(await _connectivity.isOnline)) return;
    final queue = _getPendingQueue();
    if (queue.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      final retryCount = (item['retryCount'] as int?) ?? 0;

      try {
        await _api.finishGame(item['gameId'], item['data']);
        // Başarılı olursa listeye (remaining) eklenmiyor, yani kuyruktan düşüyor.
      } on ApiException catch (e) {
        if (e.statusCode != null && e.statusCode! >= 400 && e.statusCode! < 500) {
          // 4xx Hatası (Client Hatası): Veri bozuk veya geçersiz. Tekrar denemek anlamsız.
          _logToDeadLetterQueue(item, e.message);
        } else if (retryCount >= _maxRetries) {
          // Çok fazla denendi
          _logToDeadLetterQueue(item, 'Max retries exceeded');
        } else {
          // 5xx (Sunucu) veya timeout hatası: Daha sonra tekrar dene
          remaining.add({
            ...item,
            'retryCount': retryCount + 1,
            'lastAttempt': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        // Ağ hatası vb.
        if (retryCount >= _maxRetries) {
          _logToDeadLetterQueue(item, e.toString());
        } else {
          remaining.add({...item, 'retryCount': retryCount + 1});
        }
      }
    }
    
    // Geriye kalanları tekrar kaydet
    await _save.setString(_queueKey, jsonEncode(remaining));
  }

  /// Düzeltilemez hataları loglamak için
  void _logToDeadLetterQueue(Map<String, dynamic> item, String reason) {
    final dlq = _getDLQ();
    dlq.add({
      ...item,
      'failReason': reason,
      'failedAt': DateTime.now().toIso8601String(),
    });
    _save.setString(_dlqKey, jsonEncode(dlq));
  }

  List<Map<String, dynamic>> _getPendingQueue() {
    final raw = _save.getString(_queueKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _getDLQ() {
    final raw = _save.getString(_dlqKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
