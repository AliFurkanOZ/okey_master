import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projenizdeki yollara göre güncelleyin
import 'package:okey_master/screens/duel_game_screen.dart';

void setupMockChannels() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 1. AudioService için sahte kanal (Ses çalmaya çalışıp çökmemesi için)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async => 1,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (MethodCall methodCall) async => 1,
  );

  // 2. Api/Firebase için sahte kanal
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );

  // 3. SharedPreferences (Kuyruk servisi için) sahtelemesi
  SharedPreferences.setMockInitialValues({});
}

void main() {
  // Testler başlamadan önce sahte Native bağlantılarını kuruyoruz
  setupMockChannels();

  group('DuelGameScreen Widget Testleri', () {
    
    testWidgets('Bot Modu açıkken ekranda SİZ ve BOT yazıları görünmeli', (WidgetTester tester) async {
      // 1. Ekranı sanal bir cihazda ayağa kaldırıyoruz
      await tester.pumpWidget(
        MaterialApp(
          home: DuelGameScreen(
            nickname: 'oyuncu1',
            isBotMode: true, // Bot modunu açtık
            onExit: () {},
          ),
        ),
      );

      // Animasyonların bitmesini ve ekranın tam çizilmesini bekle
      await tester.pumpAndSettle();

      // 2. Doğrulamalar (Arayüzde bu metinlerin olduğunu kanıtlıyoruz)
      expect(find.text('SİZ'), findsOneWidget);
      expect(find.text('BOT'), findsOneWidget);
      expect(find.text('SIRA: SİZ'), findsOneWidget);
    });

    testWidgets('Bot Modu kapalıyken (PvP) ekranda 1. ve 2. OYUNCU yazıları görünmeli', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DuelGameScreen(
            nickname: 'oyuncu1',
            isBotMode: false, // PvP modu
            onExit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('1. OYUNCU'), findsOneWidget);
      expect(find.text('2. OYUNCU'), findsOneWidget);
    });

    testWidgets('Appbar geri butonuna basıldığında onExit tetiklenmeli', (WidgetTester tester) async {
      bool isExitPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DuelGameScreen(
            nickname: 'oyuncu1',
            isBotMode: true,
            // Geri tuşuna basılınca bu fonksiyon çalışacak
            onExit: () {
              isExitPressed = true;
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Geri butonunu (Icon) bul
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);

      // 2. Butona sanal olarak tıkla
      await tester.tap(backButtonFinder);
      await tester.pumpAndSettle();

      // 3. onExit fonksiyonunun çalıştığını doğrula
      expect(isExitPressed, isTrue);
    });

    testWidgets('Oyun başlangıcında ekran doğru parçalarla yüklenmeli', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DuelGameScreen(
            nickname: 'oyuncu1',
            isBotMode: true,
            onExit: () {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Appbar yüklenmiş mi?
      expect(find.byType(AppBar), findsOneWidget);

      // Grid'ler (GestureDetector'lar) çizilmiş mi?
      // Oyuncu tarafında 6, rakip tarafında 6 toplam en az 12 kolon tıklama alanı olmalı
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}