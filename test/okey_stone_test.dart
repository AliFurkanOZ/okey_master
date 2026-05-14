import 'package:flutter_test/flutter_test.dart';
import 'package:okey_master/models/okey_stone.dart';

void main() {
  group('OkeyStone Model Birim Testleri', () {
    test('Varsayılan olarak isRevealed false olmalı', () {
      final stone = OkeyStone(
        path: 'assets/stones/red_1.png',
        id: 'red_1',
        value: 1,
        color: 'red',
      );

      expect(stone.isRevealed, isFalse);
      expect(stone.value, 1);
      expect(stone.color, 'red');
      expect(stone.id, 'red_1');
      expect(stone.path, 'assets/stones/red_1.png');
    });

    test('isRevealed parametresi constructor üzerinden atanabilmeli', () {
      final stone = OkeyStone(
        path: 'assets/stones/black_13.png',
        id: 'black_13',
        value: 13,
        color: 'black',
        isRevealed: true,
      );

      expect(stone.isRevealed, isTrue);
    });

    test('isRevealed değeri sonradan güncellenebilmeli', () {
      final stone = OkeyStone(
        path: 'assets/stones/blue_5.png',
        id: 'blue_5',
        value: 5,
        color: 'blue',
      );

      expect(stone.isRevealed, isFalse);
      
      stone.isRevealed = true;
      expect(stone.isRevealed, isTrue);
    });
  });
}
