import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Projenizdeki save_service.dart dosyasının doğru yolunu buraya yazın
import 'package:okey_master/services/save_service.dart';

void main() {
  late SaveService saveService;

  setUp(() async {
    // ÇÖZÜM BURADA: SharedPreferences'ın test ortamında hata vermemesi ve 
    // her testten önce hafızanın tertemiz (boş) olması için sahte verileri ayarlıyoruz.
    SharedPreferences.setMockInitialValues({});

    // Sınıf statik olmadığı için her testten önce yeni bir obje üretiyor ve başlatıyoruz.
    saveService = SaveService();
    await saveService.init();
  });

  group('SaveService Testleri', () {
    
    // --- 1. SKOR TESTLERİ ---
    test('Skor başlangıçta 0 olmalı', () {
      expect(saveService.getHighScore(), 0);
    });

    test('Yeni skor mevcut skordan yüksekse kaydedilmeli', () async {
      await saveService.saveHighScore(50);
      expect(saveService.getHighScore(), 50);

      // Daha yüksek bir skor gelirse güncellemeli
      await saveService.saveHighScore(100);
      expect(saveService.getHighScore(), 100);
    });

    test('Yeni skor mevcut skordan düşükse KAYDEDİLMEMELİ', () async {
      await saveService.saveHighScore(50); // Skoru 50 yaptık
      
      await saveService.saveHighScore(30); // 30 kaydetmeye çalışıyoruz
      
      // Skor hala 50 olarak kalmalı
      expect(saveService.getHighScore(), 50);
    });


    // --- 2. İSTATİSTİK TESTLERİ ---
    test('Oyun sayısı ve kazanma sayısı doğru şekilde artmalı', () async {
      // Başlangıç kontrolleri
      expect(saveService.getTotalGames(), 0);
      expect(saveService.getTotalWins(), 0);

      // 2 oyun oynandı, 1'i kazanıldı
      await saveService.incrementGamesPlayed();
      await saveService.incrementGamesPlayed();
      await saveService.incrementWins();

      // Sonuç kontrolleri
      expect(saveService.getTotalGames(), 2);
      expect(saveService.getTotalWins(), 1);
    });


    // --- 3. AYAR TESTLERİ ---
    test('Ses ve müzik ayarları varsayılan olarak true dönmeli', () {
      expect(saveService.isSoundEnabled(), isTrue);
      expect(saveService.isMusicEnabled(), isTrue);
    });

    test('Ses ve müzik ayarları değiştirilebilmeli', () async {
      await saveService.setSoundEnabled(false);
      await saveService.setMusicEnabled(false);

      expect(saveService.isSoundEnabled(), isFalse);
      expect(saveService.isMusicEnabled(), isFalse);
    });


    // --- 4. GENEL GETTER / SETTER TESTLERİ ---
    test('Genel getString ve setString doğru çalışmalı', () async {
      // Olmayan veri null dönmeli
      expect(saveService.getString('test_key'), isNull);

      await saveService.setString('test_key', 'test_value');
      expect(saveService.getString('test_key'), 'test_value');
    });

    test('Genel getBool ve setBool doğru çalışmalı', () async {
      expect(saveService.getBool('test_bool'), isNull);

      await saveService.setBool('test_bool', true);
      expect(saveService.getBool('test_bool'), isTrue);
    });


    // --- 5. RESET TESTİ ---
    test('resetAll tüm verileri silmeli (Fabrika Ayarları)', () async {
      // Önce hafızaya rastgele veriler dolduralım
      await saveService.saveHighScore(999);
      await saveService.incrementWins();
      await saveService.setSoundEnabled(false);

      // Tüm hafızayı temizleyelim
      await saveService.resetAll();

      // Her şeyin varsayılan değerlere (0, true veya null) döndüğünden emin olalım
      expect(saveService.getHighScore(), 0);
      expect(saveService.getTotalWins(), 0);
      expect(saveService.isSoundEnabled(), isTrue); // Varsayılanı true'ydu
    });

  });
}