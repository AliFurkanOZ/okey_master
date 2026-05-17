import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:okey_master/screens/leaderboard_screen.dart';
import 'package:okey_master/utils/constants.dart';

// --- FIREBASE VE NATIVE MOCK KURULUMU (ApiService'in çökmemesi için) ---
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
  Future<String> getIdToken([bool forceRefresh = false]) async => 'sahte_token';
}

class MockFirebaseAuthPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues({dynamic currentUser, String? languageCode}) => this;
  @override
  UserPlatform? get currentUser => MockUserPlatform();
}

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
}

void main() {
  setupMocks();

  // Nock (HTTP Mock) için güvenli URL parçalaması
  final baseUri = Uri.parse(AppConstants.apiBaseUrl);
  final origin = baseUri.origin;

  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform();
    nock.init();
  });

  setUp(() {
    nock.cleanAll();
  });

  group('LeaderboardScreen Widget Testleri', () {
    
    testWidgets('Appbar ve sekmeler (Tabs) eksiksiz yüklenmeli', (WidgetTester tester) async {
      // TabBarView en az 2 sekmeyi aynı anda yüklemeye çalışır. 
      // Garanti olması için 4 sekmenin de API isteklerini karşılayacak 4 adet sahte yanıt (mock) hazırlıyoruz.
      for (int i = 0; i < 4; i++) {
        nock(origin).get(anything).reply(200, []);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(onExit: () {}),
        ),
      );

      // Arayüzdeki başlık ve sekmeleri kontrol et
      expect(find.text('LİDERLİK TABLOLARI'), findsOneWidget);
      expect(find.text('DÜELLO'), findsOneWidget);
      expect(find.text('HAFIZA (KOLAY)'), findsOneWidget);
      
      await tester.pumpAndSettle();
      expect(find.text('Henüz sıralama yok.'), findsWidgets); 
    });

    testWidgets('API başarılı yanıt verdiğinde liderlik tablosu çizilmeli', (WidgetTester tester) async {
      final mockData = [
        {"nickname": "KralOyuncu", "score": 2500},
        {"nickname": "UstaBot", "score": 1800.5}
      ];
      
      // 4 sekme için 4 yanıt hazırlıyoruz
      for (int i = 0; i < 4; i++) {
        nock(origin).get(anything).reply(200, mockData);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(onExit: () {}),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('KralOyuncu'), findsWidgets);
      expect(find.text('2500.0 Puan'), findsWidgets); 
      expect(find.text('UstaBot'), findsWidgets);
    });

    testWidgets('API hata verdiğinde (ApiService hatayı yutarsa) boş liste ekranı çizilmeli', (WidgetTester tester) async {
      // 4 sekme için 4 hata yanıtı hazırlıyoruz
      for (int i = 0; i < 4; i++) {
        nock(origin).get(anything).reply(500, 'Internal Server Error');
      }

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(onExit: () {}),
        ),
      );

      await tester.pumpAndSettle();

      // ApiService hatayı yakalayıp geriye [] döndüğü için ekranda hata butonu değil, 
      // boş liste mesajı görünür. Biz de bunu test ediyoruz!
      expect(find.text('Henüz sıralama yok.'), findsWidgets);
    });

    testWidgets('Geri butonuna basıldığında onExit tetiklenmeli', (WidgetTester tester) async {
      for (int i = 0; i < 4; i++) {
        nock(origin).get(anything).reply(200, []);
      }

      bool isExitPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: LeaderboardScreen(
            onExit: () {
              isExitPressed = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Geri okunu bul ve tıkla
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // onExit fonksiyonunun çalıştığını doğrula
      expect(isExitPressed, isTrue);
    });
  });
}