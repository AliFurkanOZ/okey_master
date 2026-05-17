import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:connectivity_plus_platform_interface/connectivity_plus_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:okey_master/services/connectivity_service.dart';

/// 1. Connectivity (İnternet) Sahtelemesi
class MockConnectivityPlatform extends ConnectivityPlatform with MockPlatformInterfaceMixin {
  // Anlık durumları (isOnline) kontrol etmek için
  List<ConnectivityResult> currentResult = [ConnectivityResult.wifi];

  // Canlı değişiklikleri (Stream) kontrol etmek için
  final StreamController<List<ConnectivityResult>> streamController = StreamController<List<ConnectivityResult>>.broadcast();

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return currentResult;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return streamController.stream;
  }
}

void main() {
  late MockConnectivityPlatform mockPlatform;
  late ConnectivityService connectivityService;

  setUp(() {
    // Her testten önce platformu sahtesiyle değiştiriyoruz
    mockPlatform = MockConnectivityPlatform();
    ConnectivityPlatform.instance = mockPlatform;

    // Servisimizi başlatıyoruz
    connectivityService = ConnectivityService();
  });

  tearDown(() {
    // Hafıza sızıntısı olmaması için stream'i kapatıyoruz
    mockPlatform.streamController.close();
  });

  group('ConnectivityService Testleri', () {
    
    // --- 1. ANLIK BAĞLANTI KONTROLLERİ (isOnline) ---
    
    test('İnternet bağlıyken (Wifi/Mobil) isOnline true dönmeli', () async {
      // Sahte interneti Wifi yapıyoruz
      mockPlatform.currentResult = [ConnectivityResult.wifi];
      expect(await connectivityService.isOnline, isTrue);

      // Sahte interneti Mobil Veri yapıyoruz
      mockPlatform.currentResult = [ConnectivityResult.mobile];
      expect(await connectivityService.isOnline, isTrue);
    });

    test('İnternet yokken (none) isOnline false dönmeli', () async {
      // Sahte interneti kapattık
      mockPlatform.currentResult = [ConnectivityResult.none];
      expect(await connectivityService.isOnline, isFalse);
    });


    // --- 2. CANLI DİNLEME (Stream) KONTROLLERİ (onConnectivityChanged) ---
    
    test('Stream üzerinden internet durumu değiştiğinde doğru değerleri yaymalı (emit)', () async {
      // Act & Assert
      // Stream'e sırasıyla 3 olay göndereceğiz ve çıkan sonuçları sırayla bekleyeceğiz.
      expect(
        connectivityService.onConnectivityChanged,
        emitsInOrder([
          true,  // Önce Wifi bağlandı (true)
          false, // Sonra internet koptu (false)
          true,  // Tekrar Mobil bağlandı (true)
        ]),
      );

      // Test senaryosunu (Stream olaylarını) tetikliyoruz:
      mockPlatform.streamController.add([ConnectivityResult.wifi]);
      mockPlatform.streamController.add([ConnectivityResult.none]);
      mockPlatform.streamController.add([ConnectivityResult.mobile]);
    });
  });
}