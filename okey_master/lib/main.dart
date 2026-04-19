import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/save_service.dart';
import 'providers/service_providers.dart';

void main() async {
  // Flutter binding'lerini başlat (Arka planda sistemle iletişim kurabilmek için şart)
  WidgetsFlutterBinding.ensureInitialized();

  // SaveService'i asenkron olarak başlat
  final saveService = SaveService();
  await saveService.init();

  runApp(
    // Riverpod ProviderScope ile uygulamayı sarıyoruz.
    // Uygulama başlarken boş bıraktığımız provider'ı gerçek çalışan servisimizle eziyoruz (override)
    ProviderScope(
      overrides: [
        saveServiceProvider.overrideWithValue(saveService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OkeyMaster',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Uygulama başlarken şimdilik test ekranını göster
      home: const PlaceholderScreen(),
    );
  }
}

// Geçici bir test ekranı (Kişi 2 daha sonra gerçek UI tasarımlarını yapacak)
class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Örnek: SaveService'i Riverpod üzerinden okuyup verilere erişiyoruz
    final saveService = ref.watch(saveServiceProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('OkeyMaster')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text(
              'SaveService Başarıyla Çalışıyor!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'En Yüksek Skor: ${saveService.getHighScore()}',
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
