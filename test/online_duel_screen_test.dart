import 'dart:io'; // ÇÖZÜM İÇİN EKLENDİ
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projenizdeki yollara göre güncelleyin
import 'package:okey_master/screens/online_duel_screen.dart';
import 'package:okey_master/services/socket_service.dart'; // SocketService'i kapatmak için eklendi

void setupMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // ÇÖZÜM BURADA: WebSocket/HTTP isteklerinin test ortamında "UnsupportedError" 
  // fırlatıp çökmesini engellemek için Flutter'ın HTTP engelleyicisini kaldırıyoruz.
  HttpOverrides.global = null;

  // AudioService ve Firebase kanallarını susturuyoruz (Çökmemesi için)
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (MethodCall methodCall) async => 1,
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/firebase_auth'),
    (MethodCall methodCall) async => null,
  );
  
  SharedPreferences.setMockInitialValues({});
}

void main() {
  setupMocks();

  // Testler bittikten sonra arkada açık kalmaya çalışan soketleri tamamen temizliyoruz
  tearDownAll(() {
    SocketService.disconnect();
  });

  group('OnlineDuelScreen Widget Testleri', () {

    testWidgets('Ekran açıldığında "Eşleştiriliyor..." ve "Rakip Bekleniyor" yazıları gelmeli', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnlineDuelScreen(
            nickname: 'OnlineOyuncu',
            onExit: () {},
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Eşleştiriliyor...'), findsOneWidget); 
      expect(find.text('Rakip Bekleniyor...'), findsOneWidget); 
      expect(find.byType(CircularProgressIndicator), findsOneWidget); 
      
      expect(find.text('SIRA SENDE'), findsNothing);
    });

    testWidgets('Geri (Ok) butonuna basıldığında onExit tetiklenmeli ve soket kapatılmalı', (WidgetTester tester) async {
      bool isExitPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: OnlineDuelScreen(
            nickname: 'OnlineOyuncu',
            onExit: () {
              isExitPressed = true;
            },
          ),
        ),
      );

      await tester.pump();

      final backButtonFinder = find.byIcon(Icons.arrow_back);
      expect(backButtonFinder, findsOneWidget);

      await tester.tap(backButtonFinder);
      await tester.pump(); 

      expect(isExitPressed, isTrue);
    });

  });
}