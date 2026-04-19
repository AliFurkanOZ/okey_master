import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/save_service.dart';

// İleride API, Ses, Analitik gibi diğer servisleri de buraya ekleyeceğiz.
final saveServiceProvider = Provider<SaveService>((ref) {
  throw UnimplementedError('saveServiceProvider initialize edilmedi!');
});

