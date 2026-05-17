import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flutter/services.dart';

// Projenizdeki kendi yollarınızı buraya ekleyin
import 'package:okey_master/services/sync_queue_service.dart';
import 'package:okey_master/services/save_service.dart';
import 'package:okey_master/utils/constants.dart';

// --- FIREBASE VE AUTH MOCK KURULUMU (ApiService'in çökmemesi için) ---
class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FirebaseAppPlatform(name, const FirebaseOptions(apiKey: 'a', appId: 'a', messagingSenderId: 'a', projectId: 'a'));
  }
  @override
  Future<FirebaseAppPlatform> initializeApp({String? name, FirebaseOptions? options}) async => app(name ?? defaultFirebaseAppName);
}

class MockUserPlatform extends Fake with MockPlatformInterfaceMixin implements UserPlatform {
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'sahte_token_12345678901234567890';
}

class MockFirebaseAuthPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues({dynamic currentUser, String? languageCode}) => this;
  @override
  UserPlatform? get currentUser => MockUserPlatform();
}

void setupFirebaseMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
}

void main() {
  setupFirebaseMocks();

  late SaveService saveService;

  // Nock (HTTP Mock) için güvenli URL parçalaması
  final baseUri = Uri.parse(AppConstants.apiBaseUrl);
  final origin = baseUri.origin;
  final basePath = baseUri.path.endsWith('/') ? baseUri.path.substring(0, baseUri.path.length - 1) : baseUri.path;

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();
    nock.init(); 
  });

  setUp(() async {
    nock.cleanAll(); 
    
    // Her testten önce yerel hafızayı (Kuyruğu) tertemiz yapıyoruz
    SharedPreferences.setMockInitialValues({});
    saveService = SaveService();
    await saveService.init();
  });

  group('SyncQueueService Testleri', () {
    
    test('enqueue() veriyi hafızaya doğru formatta ve retryCount 0 olarak eklemeli', () async {
      final testData = {'nickname': 'oyuncu1', 'isWin': true, 'duration': 100, 'type': 'duel'};
      
      await SyncQueueService.enqueue(testData);

      // Hafızadan raw (ham) veriyi çekip kontrol edelim
      final rawQueue = saveService.getString('pending_game_results');
      expect(rawQueue, isNotNull);

      final queue = jsonDecode(rawQueue!) as List;
      expect(queue.length, 1);
      expect(queue[0]['retryCount'], 0); // Başlangıç deneme sayısı 0 olmalı
      expect(queue[0]['data']['nickname'], 'oyuncu1');
    });

    test('processQueue() API başarılı olursa kuyruğu tamamen boşaltmalı', () async {
      // 1. Hazırlık: Kuyruğa veri ekle
      final testData = {'nickname': 'oyuncu1', 'isWin': true, 'duration': 100, 'type': 'duel'};
      await SyncQueueService.enqueue(testData);

      // 2. Hazırlık: Sahte API (Başarılı)
      nock(origin).post('$basePath/games/result', anything).reply(200, 'Success');

      // 3. Eylem: Kuyruğu işle
      await SyncQueueService.processQueue();

      // 4. Doğrulama: İstek başarılı olduğu için kuyruk boşaltılmış olmalı
      final rawQueue = saveService.getString('pending_game_results');
      final queue = jsonDecode(rawQueue!) as List;
      expect(queue, isEmpty); // [] olmalı
    });

    test('processQueue() API hata (500) verirse veriyi kuyrukta tutmalı ve retryCount artırmalı', () async {
      // 1. Hazırlık
      final testData = {'nickname': 'oyuncu1', 'isWin': true, 'duration': null, 'type': 'memory'};
      await SyncQueueService.enqueue(testData); // Eklendiğinde retryCount: 0

      // 2. Sahte API (Hata)
      nock(origin).post('$basePath/games/result', anything).reply(500, 'Internal Server Error');

      // 3. Eylem
      await SyncQueueService.processQueue();

      // 4. Doğrulama: Hata aldığı için kuyrukta kalmalı ama deneme sayısı (retry) 1 artmalı
      final rawQueue = saveService.getString('pending_game_results');
      final queue = jsonDecode(rawQueue!) as List;
      expect(queue.length, 1);
      expect(queue[0]['retryCount'], 1); // 0'dan 1'e çıktı
    });

    test('processQueue() maxRetries (5) aşıldığında veriyi kuyruktan tamamen silmeli (Vazgeçmeli)', () async {
      // 1. Hazırlık: Kuyruğa veri ekle
      final testData = {'nickname': 'oyuncu1', 'isWin': true, 'duration': 100, 'type': 'duel'};
      await SyncQueueService.enqueue(testData);

      // Kodumuzda _maxRetries = 5 tanımlı. Yani ilk eklemeden sonra tam 6 kere başarısız istek atarsak
      // veriden vazgeçip kuyruktan uçurması gerekiyor.
      for (int i = 0; i < 6; i++) {
        // Her döngüde sahte API hep 500 hata dönecek
        nock(origin).post('$basePath/games/result', anything).reply(500, 'Error');
        
        await SyncQueueService.processQueue();
      }

      // 6. başarısız denemenin ardından sistem pes etmeli ve hafızayı temizlemeli
      final rawQueue = saveService.getString('pending_game_results');
      final queue = jsonDecode(rawQueue!) as List;
      expect(queue, isEmpty); // Limit aşıldığı için silindi
    });

  });
}