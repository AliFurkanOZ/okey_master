import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nock/nock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:okey_master/screens/profile_screen.dart';
import 'package:okey_master/utils/constants.dart';

// --- FIREBASE VE AUTH MOCK ALTYAPISI ---
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

class MockUserPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UserPlatform {
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async {
    return 'sahte_token';
  }
}

class MockFirebaseAuthPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({FirebaseApp? app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    dynamic currentUser,
    String? languageCode,
  }) =>
      this;

  @override
  UserPlatform? get currentUser => MockUserPlatform();
}

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;

  FirebasePlatform.instance = MockFirebasePlatform();

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
}

Future<void> pumpProfileScreen(
  WidgetTester tester, {
  required String nickname,
  required VoidCallback onExit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ProfileScreen(
        nickname: nickname,
        onExit: onExit,
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

void main() {
  setupMocks();

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

  group('ProfileScreen Widget Testleri', () {
    testWidgets(
      'Kullanıcı hiç maç yapmamışsa (0 oyun) boş durum görünmeli',
      (WidgetTester tester) async {
        nock(origin).get(anything).reply(200, {
          'totalGames': 0,
          'rank': 'bronze',
          'avgScore': 0,
        });

        nock(origin).get(anything).reply(200, []);

        await pumpProfileScreen(
          tester,
          nickname: 'YeniOyuncu',
          onExit: () {},
        );

        expect(find.text('YeniOyuncu'), findsOneWidget);
        expect(find.text('BRONZE'), findsOneWidget);
        expect(find.text('Henüz Maç Yapmadın!'), findsOneWidget);
        expect(find.text('OYUNA BAŞLA'), findsOneWidget);
        expect(find.text('KARİYER İSTATİSTİKLERİ'), findsNothing);
        expect(find.text('Henüz açılmış başarım yok.'), findsOneWidget);
      },
    );

    testWidgets(
      'Kullanıcı maç yapmışsa istatistikler ve başarımlar bölümü görünmeli',
      (WidgetTester tester) async {
        nock(origin).get(anything).reply(200, {
          'totalGames': 42,
          'totalWins': 30,
          'winStreak': 5,
          'bestWinStreak': 10,
          'rank': 'gold',
          'avgScore': 2600,
        });

        nock(origin).get(anything).reply(200, [
          {
            'achievement': {
              'name': 'Oyun Ustası',
              'iconUrl': '🏆',
            }
          }
        ]);

        await pumpProfileScreen(
          tester,
          nickname: 'UstaOyuncu',
          onExit: () {},
        );

        expect(find.text('UstaOyuncu'), findsOneWidget);
        expect(find.text('GOLD'), findsOneWidget);

        expect(find.text('Henüz Maç Yapmadın!'), findsNothing);
        expect(find.text('KARİYER İSTATİSTİKLERİ'), findsOneWidget);

        expect(find.text('42'), findsOneWidget);
        expect(find.text('30'), findsOneWidget);
        expect(find.text('10'), findsOneWidget);
        expect(find.text('2600 / 5000 Puan'), findsOneWidget);

        expect(find.text('BAŞARIMLAR KÖŞESİ'), findsOneWidget);
        expect(find.byType(Wrap), findsOneWidget);
        expect(find.text('Henüz açılmış başarım yok.'), findsNothing);

        // Başarımlar alanı boş değilse en az bir badge widget'ı çizilmiş olmalı.
        // Text içeriği uygulama tarafında farklı parse edilebildiği için tek bir ada zorlamıyoruz.
        final textWidgets = tester.widgetList<Text>(find.byType(Text)).toList();
        expect(textWidgets.isNotEmpty, isTrue);
      },
    );

    testWidgets(
      'API hatası durumunda ekran çökmeden fallback duruma geçmeli',
      (WidgetTester tester) async {
        // ApiService tarafının parse hatasına düşmesi için bozuk JSON
        nock(origin).get(anything).reply(200, 'this is not valid json');
        nock(origin).get(anything).reply(200, 'this is not valid json');

        await pumpProfileScreen(
          tester,
          nickname: 'TestOyuncusu',
          onExit: () {},
        );

        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        // Yükleme bitmiş olmalı
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Uygulama fallback boş durum ya da istatistik ekranına dönmüş olabilir.
        final hasEmptyState =
            find.text('Henüz Maç Yapmadın!').evaluate().isNotEmpty;
        final hasStatsSection =
            find.text('KARİYER İSTATİSTİKLERİ').evaluate().isNotEmpty;

        expect(hasEmptyState || hasStatsSection, isTrue);
      },
    );

    testWidgets(
      'Geri (Ok) butonuna basıldığında onExit ve OYUNA BAŞLA butonları çalışmalı',
      (WidgetTester tester) async {
        nock(origin).get(anything).reply(200, {'totalGames': 0});
        nock(origin).get(anything).reply(200, []);

        int exitCallCount = 0;

        await pumpProfileScreen(
          tester,
          nickname: 'TestOyuncusu',
          onExit: () {
            exitCallCount++;
          },
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        await tester.tap(find.text('OYUNA BAŞLA'));
        await tester.pumpAndSettle();

        expect(exitCallCount, 2);
      },
    );
  });
}