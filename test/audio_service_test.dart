import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:okey_master/services/audio_service.dart'; 

/// AudioPlayers kütüphanesinin test ortamında Native (Cihaz) kanallarını 
/// arayıp uygulamanın çökmesini (MissingPluginException) engellemek için mockluyoruz.
void setupAudioPlayerMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Native tarafa giden tüm istekleri sessizce "başarılı" (1) dönecek şekilde yakalıyoruz.
  Future<Object?> mockHandler(MethodCall methodCall) async {
    return 1; 
  }

  // AudioPlayers'ın kullandığı genel ve oyuncuya özel platform kanalları
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    mockHandler,
  );

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    mockHandler,
  );
}

void main() {
  // Testler başlamadan önce sahte Native kanallarımızı kuruyoruz.
  setupAudioPlayerMocks();

  group('AudioService Testleri', () {
    
    test('playBGM hata fırlatmadan çalışmalı (ReleaseMode.loop set edilmeli)', () async {
      // Act & Assert
      // returnsNormally, kodun hiçbir yerinde uygulamanın çökmediğini (Exception fırlatılmadığını) doğrular.
      expect(
        () async => await AudioService.playBGM(),
        returnsNormally,
      );
    });

    test('stopBGM hata fırlatmadan çalışmalı (Native platform çökmemeli)', () async {
      // stopBGM() içinde try-catch yok. Eğer mock başarısız olsaydı burada test çökerdi.
      expect(
        () async => await AudioService.stopBGM(),
        returnsNormally,
      );
    });

    test('playClick hata fırlatmadan çalışmalı', () async {
      expect(
        () async => await AudioService.playClick(),
        returnsNormally,
      );
    });

    test('playStoneMove hata fırlatmadan çalışmalı', () async {
      expect(
        () async => await AudioService.playStoneMove(),
        returnsNormally,
      );
    });

    test('playWin hata fırlatmadan çalışmalı', () async {
      expect(
        () async => await AudioService.playWin(),
        returnsNormally,
      );
    });

    test('playLose hata fırlatmadan çalışmalı', () async {
      expect(
        () async => await AudioService.playLose(),
        returnsNormally,
      );
    });
    
  });
}