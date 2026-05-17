import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:okey_master/screens/settings_screen.dart';

class MockFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return FirebaseAppPlatform(
      name,
      const FirebaseOptions(
        apiKey: 'a',
        appId: 'a',
        messagingSenderId: 'a',
        projectId: 'a',
      ),
    );
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return app(name ?? defaultFirebaseAppName);
  }
}

class MockFirebaseAuthPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseAuthPlatform {
  MockFirebaseAuthPlatform(this.user);

  final UserPlatform? user;

  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    dynamic currentUser,
    String? languageCode,
  }) =>
      this;

  @override
  UserPlatform? get currentUser => user;
}

class MockUserPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UserPlatform {
  MockUserPlatform({
    required this.anonymous,
    this.emailValue,
    this.displayNameValue,
  });

  final bool anonymous;
  final String? emailValue;
  final String? displayNameValue;

  @override
  bool get isAnonymous => anonymous;

  @override
  bool get isEmailVerified => !anonymous;

  @override
  String? get email => emailValue;

  @override
  String? get displayName => displayNameValue;

  @override
  List<UserInfo> get providerData => const [];

  @override
  String get uid => 'uid-1';

  @override
  String? get phoneNumber => null;

  @override
  String? get photoURL => null;

  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async {
    return 'sahte_token';
  }
}

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
}

Future<void> pumpSettingsScreen(
  WidgetTester tester, {
  required String nickname,
  required VoidCallback onExit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SettingsScreen(
        nickname: nickname,
        onExit: onExit,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> openDialog(WidgetTester tester, String buttonText) async {
  await tester.tap(find.text(buttonText));
  await tester.pumpAndSettle();
}

void main() {
  setupMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  setUp(() {
    FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform(null);
  });

  group('SettingsScreen Widget Testleri', () {
    testWidgets(
      'Misafir kullanıcıda hesap bağlama seçenekleri görünmeli',
      (WidgetTester tester) async {
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform(
          MockUserPlatform(
            anonymous: true,
            emailValue: null,
            displayNameValue: null,
          ),
        );

        await pumpSettingsScreen(
          tester,
          nickname: 'MisafirOyuncu',
          onExit: () {},
        );

        expect(find.text('MisafirOyuncu'), findsOneWidget);
        expect(
          find.text('Misafir Hesap (Veriler kaybolabilir)'),
          findsOneWidget,
        );

        expect(find.text('HESABI BAĞLA (KAYBETMEMEK İÇİN)'), findsOneWidget);
        expect(find.text('Google ile Bağla'), findsOneWidget);
        expect(find.text('E-posta ile Bağla'), findsOneWidget);
      },
    );

    testWidgets(
      'Kullanıcı adı kısa girilirse uyarı snackbarı görünmeli',
      (WidgetTester tester) async {
        await pumpSettingsScreen(
          tester,
          nickname: 'TestOyuncu',
          onExit: () {},
        );

        await openDialog(tester, 'İsim Değiştir');

        await tester.enterText(find.byType(TextField).first, 'A');
        await tester.tap(find.text('Kaydet'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Kullanıcı adı 2 ile 50 karakter arasında olmalıdır.',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'E-posta ile bağla diyaloğunda boş alanlar uyarı vermeli',
      (WidgetTester tester) async {
        FirebaseAuthPlatform.instance = MockFirebaseAuthPlatform(
          MockUserPlatform(
            anonymous: true,
            emailValue: null,
            displayNameValue: null,
          ),
        );

        await pumpSettingsScreen(
          tester,
          nickname: 'MisafirOyuncu',
          onExit: () {},
        );

        await openDialog(tester, 'E-posta ile Bağla');

        await tester.tap(find.text('Bağla'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'E-posta ve şifre boş olamaz.',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Hakkında bölümünde gizlilik politikası tıklanınca snackbar görünmeli',
      (WidgetTester tester) async {
        await pumpSettingsScreen(
          tester,
          nickname: 'TestOyuncu',
          onExit: () {},
        );

        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Gizlilik Politikası'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'Yakında eklenecek.',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Geri butonu onExit çağırmalı',
      (WidgetTester tester) async {
        await pumpSettingsScreen(
          tester,
          nickname: 'TestOyuncusu',
          onExit: () {},
        );

        int exitCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: SettingsScreen(
              nickname: 'TestOyuncusu',
              onExit: () {
                exitCount++;
              },
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(exitCount, 1);
      },
    );
  });
}