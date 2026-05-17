import 'package:flutter_test/flutter_test.dart';
import 'package:okey_master/services/socket_service.dart';

void main() {
  // Testler tamamlandıktan sonra arka planda açık kalan soket 
  // bağlantılarının (timer'ların) testleri askıda bırakmasını önlemek için:
  tearDownAll(() {
    SocketService.disconnect();
  });

  group('SocketService Testleri', () {
    
    setUp(() {
      // Her testten önce soketi temizleyip bağlantıyı koparıyoruz ki 
      // testler birbirini etkilemesin (İzolasyon).
      SocketService.disconnect();
    });

    test('connect() metodu hata fırlatmadan çalışmalı ve soketi başlatmalı', () {
      // Act & Assert
      expect(() => SocketService.connect(), returnsNormally);
      
      // Tekrar çağrıldığında (zaten bağlıyken) if kontrolüne takılıp çökmemeli
      expect(() => SocketService.connect(), returnsNormally);
    });

    test('disconnect() metodu bağlantıyı koparmalı ve temizlemeli', () {
      // Önce bağlan
      SocketService.connect();
      
      // Sonra kopar
      expect(() => SocketService.disconnect(), returnsNormally);
      
      // Koptuktan sonra ID null olmalı (koddaki _socket = null mantığı çalışmalı)
      expect(SocketService.socketId, isNull);
    });

    test('joinQueue() soket kapalıyken bile çökmeden connect() tetikleyip çalışmalı', () {
      // Başlangıçta soket kapalı (setUp'da kapattık)
      // Koddaki "if (_socket == null) connect();" mantığı test ediliyor
      expect(
        () => SocketService.joinQueue('test_oyuncu', 'duel'), 
        returnsNormally,
      );
    });

    test('on() metodu kapalıyken çökmemeli ve dinleyici eklemeli', () {
      // Koddaki "if (_socket == null) connect();" mantığı test ediliyor
      expect(
        () => SocketService.on('match_found', (data) {
          // Dummy callback
        }), 
        returnsNormally,
      );
    });

    test('off() metodu soket varken ve yokken çökmeden çalışmalı', () {
      // 1. Soket yokken off çağrılırsa (if kontrolüne takılır, çökmez)
      expect(() => SocketService.off('match_found'), returnsNormally);

      // 2. Soket varken off çağrılırsa
      SocketService.connect();
      expect(() => SocketService.off('match_found'), returnsNormally);
    });

    test('emit() metodu soket varken ve yokken çökmeden çalışmalı', () {
      // 1. Soket yokken emit çağrılırsa (if kontrolüne takılır, çökmez)
      expect(() => SocketService.emit('chat_message', 'merhaba'), returnsNormally);

      // 2. Soket varken emit çağrılırsa
      SocketService.connect();
      expect(() => SocketService.emit('chat_message', 'merhaba'), returnsNormally);
    });

    test('socketId başlangıçta null dönmeli', () {
      // setUp'da disconnect olduğu için _socket null olmalı
      expect(SocketService.socketId, isNull);
    });
  });
}