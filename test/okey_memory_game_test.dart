import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:okey_master/screens/memory_game_screen.dart';

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Olası Firebase veya Ses kanallarının çökmemsi için sessize alıyoruz
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
  
  SharedPreferences.setMockInitialValues({});
}

void main() {
  setupMocks();

  group('OkeyMemoryGame Widget Testleri', () {

    testWidgets('Bot modu AÇIKKEN ilk başta "Zorluk Seçimi" ekranı gelmeli', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OkeyMemoryGame(
            nickname: 'TestOyuncusu',
            isBotMode: true, // Bot modunu açtık
            onExit: () {},
          ),
        ),
      );
      
      // Timer başlamadığı için normal pump yeterli
      await tester.pump();

      // Oyun başlamamalı, zorluk ekranı görünmeli
      expect(find.text('BOT ZORLUĞUNU SEÇİN'), findsOneWidget);
      expect(find.text('KOLAY'), findsOneWidget);
      expect(find.text('ORTA'), findsOneWidget);
      expect(find.text('ZOR'), findsOneWidget);
      
      // Oyun gridi ortada olmamalı
      expect(find.text('SİZ: 0'), findsNothing);
    });

    testWidgets('Bot modu KAPALIYKEN (PvP) doğrudan oyun ızgarası açılmalı', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OkeyMemoryGame(
            nickname: 'TestOyuncusu',
            isBotMode: false, // PvP Modu (Bot kapalı)
            onExit: () {},
          ),
        ),
      );

      // Ekranı çiz
      await tester.pump();

      // PvP olduğu için "1. OYUNCU" ve "2. OYUNCU" yazmalı, zorluk ekranı olmamalı
      expect(find.text('BOT ZORLUĞUNU SEÇİN'), findsNothing);
      expect(find.text('1. OYUNCU: 0'), findsOneWidget);
      expect(find.text('2. OYUNCU: 0'), findsOneWidget);
      
      // Sayaç ekranda görünmeli
      expect(find.text('0 sn'), findsOneWidget);
    });

    testWidgets('Zorluk butonuna basılınca oyun başlamalı ve kartlar çizilmeli', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OkeyMemoryGame(
            nickname: 'TestOyuncusu',
            isBotMode: true,
            onExit: () {},
          ),
        ),
      );

      // "KOLAY" butonunu bul ve tıkla
      await tester.tap(find.text('KOLAY'));
      
      // setState tetiklendi, ekranın yenilenmesi için 1 kez pump yapıyoruz.
      // pumpAndSettle KULLANMIYORUZ çünkü Timer var!
      await tester.pump();

      // Zorluk ekranı kaybolmalı, skorlar ve sayaç gelmeli
      expect(find.text('BOT ZORLUĞUNU SEÇİN'), findsNothing);
      expect(find.text('SİZ: 0'), findsOneWidget);
      expect(find.text('BOT: 0'), findsOneWidget);
      expect(find.text('0 sn'), findsOneWidget);

      // Kartlar (GestureDetector'lar) ekrana çizilmiş mi?
      // 8 satır * 4 sütun = 32 kart (ve tıklanabilir alan) olması gerek
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Geri (Ok) butonuna basıldığında onExit tetiklenmeli', (WidgetTester tester) async {
      bool isExitPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OkeyMemoryGame(
            nickname: 'TestOyuncusu',
            isBotMode: true,
            onExit: () {
              isExitPressed = true;
            },
          ),
        ),
      );

      // Appbar üzerindeki geri ikonunu bul
      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);

      // Butona sanal olarak tıkla
      await tester.tap(backButtonFinder);
      await tester.pump();

      // Callback fonksiyonu başarıyla tetiklenmiş mi?
      expect(isExitPressed, isTrue);
    });

  });
}