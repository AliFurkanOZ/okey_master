import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/save_service.dart';
import '../services/analytics_service.dart'; // YENİ: Analytics'i projeye dahil ettik

// SaveService asenkron başladığı için main.dart'ta override ediliyor.
final saveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError('saveServiceProvider initialize edilmedi!');
});

// YENİ: AnalyticsService Provider
// Bu servis anında (senkron) başlatılabildiği için direkt return ediyoruz.
// Artık uygulamanın herhangi bir yerinde ref.watch(analyticsServiceProvider) diyerek kullanabiliriz!
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
