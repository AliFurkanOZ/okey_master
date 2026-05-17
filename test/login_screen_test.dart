import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Projenizdeki yollara göre güncelleyin
import 'package:okey_master/screens/login_screen.dart';

// --- FIREBASE VE AUTH MOCK ALTYAPISI ---
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
  String get uid => 'test_uid';
  @override
  bool get isAnonymous => false;
}

class MockFirebaseAuthPlatform extends Fake with MockPlatformInterfaceMixin implements FirebaseAuthPlatform {
  bool isLoggedIn = false;

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues({dynamic currentUser, String? languageCode}) => this;
  
  @override
  UserPlatform? get currentUser => isLoggedIn ? MockUserPlatform() : null;

  // ÇÖZÜM BURADA: Ekranın initState'inde çağrılan signOut metodunu sahtesine ekledik.
  @override
  Future<void> signOut() async {
    isLoggedIn = false;
  }
}

void main() {
  late MockFirebaseAuthPlatform authMock;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FirebasePlatform.instance = MockFirebasePlatform();
    
    // Native Firebase ve Google kanallarını sustur
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/firebase_auth'), (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/google_sign_in'), (MethodCall methodCall) async => null,
    );

    await Firebase.initializeApp();
    authMock = MockFirebaseAuthPlatform();
    FirebaseAuthPlatform.instance = authMock;
  });

  setUp(() {
    authMock.isLoggedIn = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('LoginScreen Widget Testleri', () {

    testWidgets('İlk açılışta Ana Giriş Ekranı (Auth UI) gelmeli', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(onSelect: (n, r) {})));
      await tester.pumpAndSettle();

      expect(find.text('OKEY ARCADE'), findsOneWidget);
      expect(find.text('E-posta ile Giriş Yap'), findsOneWidget);
      expect(find.text('Google ile Giriş Yap'), findsOneWidget);
      expect(find.text('Misafir Olarak Devam Et'), findsOneWidget);
    });

    testWidgets('Misafir butonuna tıklayınca Misafir Modu açılmalı ve geri dönülebilmeli', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(onSelect: (n, r) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Misafir Olarak Devam Et'));
      await tester.pumpAndSettle(); 

      expect(find.text('Bir takma isim belirleyin'), findsOneWidget);
      expect(find.text('BAŞLA'), findsOneWidget);
      expect(find.text('E-posta ile Giriş Yap'), findsNothing); 

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('E-posta ile Giriş Yap'), findsOneWidget); 
    });

    testWidgets('E-posta butonuna tıklayınca Form açılmalı, Giriş/Kayıt arası geçiş yapılabilmeli', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginScreen(onSelect: (n, r) {})));
      await tester.pumpAndSettle();

      await tester.tap(find.text('E-posta ile Giriş Yap'));
      await tester.pumpAndSettle();

      expect(find.text('E-posta ile Giriş'), findsOneWidget);
      expect(find.text('GİRİŞ YAP'), findsOneWidget);
      expect(find.text('Kullanıcı Adı'), findsNothing); 

      await tester.tap(find.text('Hesabınız yok mu? Kayıt olun'));
      await tester.pumpAndSettle();

      expect(find.text('E-posta ile Kayıt'), findsOneWidget);
      expect(find.text('KAYIT OL'), findsOneWidget);
      expect(find.text('Kullanıcı Adı'), findsOneWidget); 
    });

    testWidgets('Oturum varsa (Auto-login) doğrudan Lobi Ekranı açılmalı', (WidgetTester tester) async {
      authMock.isLoggedIn = true;
      SharedPreferences.setMockInitialValues({'user_nick': 'TestUstası'});

      await tester.pumpWidget(MaterialApp(home: LoginScreen(onSelect: (n, r) {})));
      
      await tester.pumpAndSettle();

      expect(find.text('LOBİ'), findsOneWidget);
      expect(find.text('Hoş geldin, TestUstası'), findsOneWidget);
      expect(find.text('DÜELLO (ONLİNE)'), findsOneWidget);
    });

    testWidgets('Lobi butonlarına basılınca onSelect callback doğru verilerle tetiklenmeli', (WidgetTester tester) async {
      authMock.isLoggedIn = true;
      SharedPreferences.setMockInitialValues({'user_nick': 'ProOyuncu'});

      String? returnedNick;
      String? returnedRoute;

      await tester.pumpWidget(MaterialApp(
        home: LoginScreen(
          onSelect: (nick, route) {
            returnedNick = nick;
            returnedRoute = route;
          },
        ),
      ));
      
      await tester.pumpAndSettle();

      await tester.tap(find.text('DÜELLO (LOKAL)'));
      await tester.pumpAndSettle();

      expect(returnedNick, 'ProOyuncu');
      expect(returnedRoute, 'duel_2p');
    });

  });
}