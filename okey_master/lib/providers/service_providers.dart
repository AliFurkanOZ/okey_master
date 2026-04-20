import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/save_service.dart';
import '../services/analytics_service.dart';
import '../services/connectivity_service.dart';
import '../services/ad_service.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';

final saveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError('saveServiceProvider initialize edilmedi!');
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// YENİ: Connectivity Provider
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

// YENİ: AdService Provider (Connectivity bağımlılığı var)
final adServiceProvider = Provider<AdService>((ref) {
  return AdService(ref.watch(connectivityServiceProvider));
});

// YENİ: ApiService Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// YENİ: StreamProvider (İnternet durumunu arayüzde anlık dinlemek için)
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  return ref.watch(connectivityServiceProvider).onConnectivityChanged;
});

// YENİ: SyncQueueService Provider
final syncQueueServiceProvider = Provider<SyncQueueService>((ref) {
  return SyncQueueService(
    ref.watch(saveServiceProvider),
    ref.watch(apiServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});