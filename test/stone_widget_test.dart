import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:okey_master/widgets/stone_widget.dart';
import 'package:okey_master/models/okey_stone.dart';

void main() {
  group('StoneBody3D Widget Testleri', () {
    testWidgets('Taş kapalıyken arka yüz resmi (tas_arka.png) gösterilmeli', (WidgetTester tester) async {
      // 1. Hazırlık (Arrange)
      final stone = OkeyStone(
        path: 'assets/images/kirmizi_1.png',
        id: 'red_1',
        value: 1,
        color: 'red',
        isRevealed: false,
      );

      // 2. Uygulama (Act)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoneBody3D(stone: stone),
          ),
        ),
      );

      // 3. Doğrulama (Assert)
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget<Image>(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      
      expect(assetImage.assetName, 'assets/images/tas_arka.png');
    });

    testWidgets('Taş açıkken kendi resmi (ön yüz) gösterilmeli', (WidgetTester tester) async {
      // 1. Hazırlık (Arrange)
      final stone = OkeyStone(
        path: 'assets/images/kirmizi_1.png',
        id: 'red_1',
        value: 1,
        color: 'red',
        isRevealed: true,
      );

      // 2. Uygulama (Act)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoneBody3D(stone: stone),
          ),
        ),
      );

      // 3. Doğrulama (Assert)
      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image imageWidget = tester.widget<Image>(imageFinder);
      final AssetImage assetImage = imageWidget.image as AssetImage;
      
      expect(assetImage.assetName, 'assets/images/kirmizi_1.png');
    });
  });
}
