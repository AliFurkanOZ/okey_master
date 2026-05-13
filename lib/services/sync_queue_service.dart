import 'dart:convert';
import 'save_service.dart';
import 'api_service.dart';

class SyncQueueService {
  static const _queueKey = 'pending_game_results';
  static const _maxRetries = 5;

  static Future<void> enqueue(Map<String, dynamic> data) async {
    final save = SaveService();
    await save.init();
    final raw = save.getString(_queueKey);
    List<Map<String, dynamic>> queue = [];
    if (raw != null) {
      queue = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    }
    queue.add({
      'data': data,
      'retryCount': 0,
    });
    await save.setString(_queueKey, jsonEncode(queue));
  }

  static Future<void> processQueue() async {
    final save = SaveService();
    await save.init();
    final raw = save.getString(_queueKey);
    if (raw == null) return;
    final queue = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    if (queue.isEmpty) return;

    final remaining = <Map<String, dynamic>>[];

    for (final item in queue) {
      final retryCount = (item['retryCount'] as int?) ?? 0;
      try {
        await ApiService.sendResult(
          nickname: item['data']['nickname'],
          isWin: item['data']['isWin'],
          duration: item['data']['duration'],
          type: item['data']['type']
        );
      } on ApiException catch (e) {
        if (retryCount < _maxRetries) {
          remaining.add({
            ...item,
            'retryCount': retryCount + 1,
          });
        }
      } catch (e) {
        if (retryCount < _maxRetries) {
          remaining.add({...item, 'retryCount': retryCount + 1});
        }
      }
    }
    
    await save.setString(_queueKey, jsonEncode(remaining));
  }
}
