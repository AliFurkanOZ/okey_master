# 🎯 OkeyMaster-Main Nihai Geliştirme Planı

> **Kararlar:** ✅ Firebase eklenecek · ✅ Sadece Android · ✅ Prisma Query (Materialized View yok)
> **Kaynak:** `okey_master`'daki backend/mimari alınıp `okey_master-main`'in çalışan UI'ına entegre edilecek.

---

## 📋 GENEL BAKIŞ — Ne Yapılacak, Neden Yapılacak?

`okey_master-main` şu an çalışır durumda ama **3 kritik sorunu** var:

1. **🔴 GÜVENLİK YOK** — Herkes sahte oyun sonucu gönderebilir, liderlik tablosunu manipüle edebilir
2. **🔴 FIREBASE YOK** — Kullanıcı kimlik doğrulaması yok, test UID ile çalışıyor
3. **🟡 ALTYAPI ZAYIF** — Offline destek yok, hata yönetimi yok, state yönetimi ilkel

**Çözüm:** 7 adımda, sırayla, her biri bağımsız test edilebilir şekilde ilerleyeceğiz.

---

## 🗺️ ADIM HARİTASI (Sıralı — Her adım bir öncekine bağlı)

```
ADIM 1: Firebase Kurulumu (Android + Flutter)
    ↓
ADIM 2: Flutter pubspec.yaml + Bağımlılıklar
    ↓
ADIM 3: Prisma Schema Birleştirme (Veritabanı)
    ↓
ADIM 4: Backend Güvenlik Yaması (Server)
    ↓
ADIM 5: Flutter Servis Katmanı (API, Save, Sync)
    ↓
ADIM 6: Flutter Ekran Güncellemeleri (Login, Oyun, Liderlik)
    ↓
ADIM 7: Test & Doğrulama
```

---

# ADIM 1: Firebase Kurulumu (Android)

## Neden?
Şu an `okey_master-main`'de Firebase hiç yok. Kullanıcılar `test_user_ali` gibi sahte UID'lerle kaydediliyor. Firebase Auth olmadan backend güvenliği sağlanamaz.

## Ne Yapılacak?

### 1.1 — `google-services.json` dosyasını kopyala

**Nereden:** `okey_master/okey_master/android/app/google-services.json`
**Nereye:** `okey_master-main/android/app/google-services.json`

> [!IMPORTANT]
> Bu dosya Firebase Console'dan indirilen yapılandırma dosyasıdır. `okey_master`'da zaten mevcut, aynı Firebase projesi (`okeymaster-f93b9`) kullanılacağı için birebir kopyalanabilir. Ancak `package_name` alanı `com.teamname.okey_master` olarak yazılı — bunu `okey_master-main`'in `applicationId`'si olan `com.example.okey_mobil` ile eşleştirmemiz ya da `applicationId`'yi değiştirmemiz gerekiyor.

**Karar noktası:** `applicationId`'yi `com.teamname.okey_master` olarak değiştirmek en temiz yol. Yoksa Firebase Console'dan yeni bir Android uygulaması ekleyip yeni `google-services.json` indirmek gerekir.

### 1.2 — `android/settings.gradle.kts` — Google Services plugin ekle

```diff
 plugins {
     id("dev.flutter.flutter-plugin-loader") version "1.0.0"
     id("com.android.application") version "8.11.1" apply false
+    id("com.google.gms.google-services") version("4.3.15") apply false
     id("org.jetbrains.kotlin.android") version "2.2.20" apply false
 }
```

**Neden:** Firebase SDK'sının çalışması için Google Services Gradle plugin'i gereklidir.

### 1.3 — `android/app/build.gradle.kts` — Plugin uygula + applicationId güncelle

```diff
 plugins {
     id("com.android.application")
+    id("com.google.gms.google-services")
     id("kotlin-android")
     id("dev.flutter.flutter-gradle-plugin")
 }

 android {
-    namespace = "com.example.okey_mobil"
+    namespace = "com.teamname.okey_master"
     ...
     defaultConfig {
-        applicationId = "com.example.okey_mobil"
+        applicationId = "com.teamname.okey_master"
+        minSdk = 23  // Firebase Auth minimum
```

### 1.4 — `firebase_options.dart` dosyasını kopyala

**Nereden:** `okey_master/okey_master/lib/firebase_options.dart`
**Nereye:** `okey_master-main/lib/firebase_options.dart`

Bu dosya FlutterFire CLI tarafından üretilmiş, Android/iOS/Web platformları için Firebase yapılandırmasını içeriyor.

---

# ADIM 2: Flutter Bağımlılıkları (pubspec.yaml)

## Neden?
Firebase Auth, Riverpod, güvenli UUID üretimi gibi paketler olmadan backend ile güvenli iletişim kurulamaz.

## Ne Yapılacak?

### [MODIFY] [pubspec.yaml](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/pubspec.yaml)

```yaml
name: okey_master          # isim değişikliği (Firebase ile uyum)
description: "OkeyMaster - Çin Okeyi Mobil Oyunu"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.11.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # === MEVCUT (korunacak) ===
  model_viewer_plus: ^1.7.0
  cupertino_icons: ^1.0.8
  http: ^1.1.0
  shared_preferences: ^2.5.5
  # === YENİ (okey_master'dan) ===
  flutter_riverpod: ^3.3.1        # State management
  firebase_core: ^4.7.0           # Firebase başlatma
  firebase_auth: ^6.4.0           # Kullanıcı kimlik doğrulama
  firebase_analytics: ^12.3.0     # Analitik takip
  uuid: ^4.2.0                    # Idempotency key üretimi
  connectivity_plus: ^7.1.1       # İnternet durumu takibi
  equatable: ^2.0.8               # Model karşılaştırma
  crypto: ^3.0.3                  # Anti-cheat hash

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

**Her paketin nedeni:**
| Paket | Neden Gerekli |
|-------|---------------|
| `flutter_riverpod` | setState yerine profesyonel state yönetimi |
| `firebase_core` | Firebase'i başlatmak için zorunlu |
| `firebase_auth` | Anonim giriş + token üretimi (backend güvenliği) |
| `firebase_analytics` | Kullanıcı davranış takibi |
| `uuid` | Her oyun bitişinde tekil idempotency key üretme |
| `connectivity_plus` | İnternet var mı yok mu kontrol etme |
| `equatable` | Model nesnelerini karşılaştırma (Riverpod için) |
| `crypto` | Oyun sonucu hash'i üretme (anti-cheat) |

---

# ADIM 3: Prisma Schema Birleştirme

## Neden?
İki projenin `UserStats` modeli farklı alanlar içeriyor:
- `okey_master`: `totalLosses`, `winStreak`, `bestWinStreak`, `rank`, `totalPlayTimeMinutes`
- `okey_master-main`: `bestTimeEasy`, `bestTimeMedium`, `bestTimeHard`

İkisi de lazım. Birleştireceğiz.

### [MODIFY] [schema.prisma](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/prisma/schema.prisma)

Sadece `UserStats` modeli değişecek (62-76 arası satırlar):

```prisma
model UserStats {
  id                   String   @id @default(uuid())
  userId               String   @unique @map("user_id")
  totalGames           Int      @default(0) @map("total_games")
  totalWins            Int      @default(0) @map("total_wins")
  totalLosses          Int      @default(0) @map("total_losses")       // YENİ
  winStreak            Int      @default(0) @map("win_streak")         // YENİ
  bestWinStreak        Int      @default(0) @map("best_win_streak")    // YENİ
  avgScore             Int      @default(0) @map("avg_score")
  totalPlayTimeMinutes Int      @default(0) @map("total_play_time_minutes") // YENİ
  rank                 String   @default("bronze")                     // YENİ
  bestTimeEasy         Int      @default(0) @map("best_time_easy")     // MEVCUT
  bestTimeMedium       Int      @default(0) @map("best_time_medium")   // MEVCUT
  bestTimeHard         Int      @default(0) @map("best_time_hard")     // MEVCUT

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)
  @@map("user_stats")
}
```

**Migration komutu:**
```bash
cd okey_master-main/okey-master-server
npx prisma migrate dev --name add_missing_stats_fields
npx prisma generate
```

---

# ADIM 4: Backend Güvenlik Yaması

## Neden?
Şu an `okey_master-main`'de:
- Game route'unda `verifyToken` yok → herkes sahte sonuç gönderebilir
- Auth register'da token zorunlu değil → sahte hesap açılabilir
- Leaderboard cron job yok → sıralama güncellenmiyor
- Game controller çok basit → anti-cheat, süre kontrolü, hash doğrulama yok

## Ne Yapılacak? (4 dosya değişecek)

### 4.1 — [MODIFY] [auth.controller.js](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/src/controllers/auth.controller.js)

**Sorun (Satır 17):** `req.user` yoksa test UID üretiliyor — güvenlik açığı.

```diff
-    const firebaseUid = (req.user && req.user.uid) ? req.user.uid : `test_user_${username}`;
+    const firebaseUid = req.user.uid;
```

**Neden:** Firebase token doğrulaması zorunlu olacak. `req.user` her zaman var olacak çünkü `verifyToken` middleware route'a eklenecek.

### 4.2 — [MODIFY] [auth.routes.js](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/src/routes/auth.routes.js)

```diff
-router.post('/register', authController.registerValidation, authController.register);
+router.post('/register', verifyToken, authController.registerValidation, authController.register);
```

**Neden:** Register sırasında da kullanıcının gerçek bir Firebase hesabı olması gerekir.

### 4.3 — [MODIFY] [game.controller.js](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/src/controllers/game.controller.js)

**Mevcut durum:** Tek fonksiyon (`saveGameResult`), güvenlik kontrolü yok, 46 satır.

**Hedef:** Mevcut `saveGameResult`'ı KORUYARAK, `okey_master`'dan 3 yeni fonksiyon ekleme:

| Fonksiyon | Ne Yapar | Güvenlik |
|-----------|----------|----------|
| `createGame` | Yeni oyun başlatır, serverSeed üretir | Zombi temizliği, aktif oyun limiti |
| `finishGame` | Oyunu bitirir, skor kaydeder | İdempotency, süre kontrolü, hash doğrulama, skor sınırı |
| `getHistory` | Oyun geçmişi listeler | Sayfalama |
| `saveGameResult` | **MEVCUT — korunacak** | Hafıza oyunu için basit kayıt |

Dosyanın yeni hali `okey_master`'daki `game.controller.js`'in birebir kopyası + mevcut `saveGameResult` olacak.

### 4.4 — [MODIFY] [game.routes.js](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/src/routes/game.routes.js)

```diff
 const express = require('express');
 const router = express.Router();
+const { verifyToken } = require('../middleware/firebase-auth');
 const gameController = require('../controllers/game.controller');

+router.post('/', verifyToken, gameController.createGameValidation, gameController.createGame);
+router.post('/:id/finish', verifyToken, gameController.finishGameValidation, gameController.finishGame);
+router.get('/history', verifyToken, gameController.getHistory);
 router.post('/result', gameController.saveGameResult);  // GERİYE UYUMLULUK
```

### 4.5 — [MODIFY] [index.js](file:///c:/Users/alifu/Desktop/deneme1234/okey_master-main/okey-master-server/src/index.js)

**Sorun (Satır 79-80):** Leaderboard cron job eksik — yorum var ama kod yok.

> [!WARNING]
> Prisma Query kullanacağımız için materialized view refresh yerine farklı bir yaklaşım uygulayacağız. Leaderboard doğrudan Prisma findMany ile sorgulanacak, bu yüzden cron job'a gerek kalmayabilir. Ama idempotency cleanup cron job'u zaten mevcut ve çalışıyor — o korunacak.

---

# ADIM 5: Flutter Servis Katmanı

## Neden?
Mevcut Flutter uygulamasında:
- API çağrıları güvensiz (token yok, timeout yok, hata yönetimi yok)
- İnternet kontrolü yok
- Offline destek yok
- Yerel kayıt sistemi sadece nickname için kullanılıyor

## Ne Yapılacak? (5 yeni dosya + 1 güncelleme)

### 5.1 — [NEW] `lib/utils/constants.dart`

```dart
class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emülatör → localhost
  );
}
```

**Neden:** API URL'si kodun içine gömülmemeli. Compile-time'da `--dart-define` ile değiştirilebilir olmalı.

### 5.2 — [NEW] `lib/services/connectivity_service.dart`

İnternet durumunu kontrol eden ve değişiklikleri dinleyen servis. `connectivity_plus` paketini kullanır. `okey_master`'dan birebir alınacak.

### 5.3 — [NEW] `lib/services/save_service.dart`

SharedPreferences wrapper. High score, toplam oyun sayısı, ses/müzik ayarları ve offline kuyruk verilerini yönetir. `okey_master`'dan birebir alınacak.

### 5.4 — [NEW] `lib/services/sync_queue_service.dart`

Offline oyun sonuçlarını kuyruğa alıp internet gelince otomatik gönderen servis:
- `enqueue()` — Sonucu kuyruğa ekle
- `processQueue()` — İnternet varsa kuyruğu işle
- Dead Letter Queue — 5 denemede başarısız olanları ayır

`okey_master`'dan alınıp `saveGameResult` endpoint'ine uyarlanacak.

### 5.5 — [MODIFY] `lib/services/api_service.dart`

**Mevcut sorunlar:**
1. Hardcoded URL (`http://10.0.2.2:3000/api`) → `AppConstants` kullanılacak
2. Firebase token gönderilmiyor → Her istekte `Authorization: Bearer <token>` eklenecek
3. Timeout yok → 10 saniye default timeout
4. Hata sınıflandırması yok → `ApiException` class'ı eklenecek

**Yeni yapı (mevcut static metotlar korunacak, altyapı değişecek):**

```dart
class ApiService {
  static String get _baseUrl => AppConstants.apiBaseUrl;

  // YENİ: Firebase token'ı otomatik ekle
  static Future<Map<String, String>> _headers() async {
    final user = FirebaseAuth.instance.currentUser;
    final token = user != null ? await user.getIdToken() : '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // MEVCUT metotlar aynı imzayla kalacak ama altyapı güçlenecek
  static Future<int> registerPlayer(String nickname) async { ... }
  static Future<void> sendResult({...}) async { ... }
  static Future<List<dynamic>> getLeaderboard(String type) async { ... }
}
```

### 5.6 — [MODIFY] `lib/main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/save_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Firebase anonim giriş (kullanıcı ilk kez açıyorsa)
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // 3. SaveService başlat
  final saveService = SaveService();
  await saveService.init();

  runApp(const OkeyApp());  // Mevcut UI korunacak
}
```

**Neden anonim giriş?** Kullanıcıdan email/şifre istemeden otomatik bir Firebase UID atanır. Bu UID backend'de güvenli kimlik doğrulaması sağlar. Kullanıcı isterse sonra email ile hesabını yükseltebilir.

---

# ADIM 6: Flutter Ekran Güncellemeleri

## 6.1 — [MODIFY] `lib/screens/login_screen.dart`

**Değişiklik 1: Register akışı**

Mevcut akış:
```
Kullanıcı nick yazar → API'ye username gönder → SharedPreferences'a kaydet
```

Yeni akış:
```
Kullanıcı nick yazar → Firebase anonim giriş zaten var
→ API'ye username + Firebase token gönder → SharedPreferences'a kaydet
```

**Değişiklik 2:** `ApiService.registerPlayer` artık Firebase token göndereceği için backend güvenli.

### 6.2 — [MODIFY] `lib/screens/duel_game_screen.dart`

**Değişiklik 1: Güvenli karıştırma**
```diff
-    deck.shuffle();
+    // Fisher-Yates + Random.secure() (kriptografik güvenli)
+    final rng = Random.secure();
+    for (int i = deck.length - 1; i > 0; i--) {
+      final j = rng.nextInt(i + 1);
+      final temp = deck[i]; deck[i] = deck[j]; deck[j] = temp;
+    }
```

**Değişiklik 2: Offline destek**
```dart
// Oyun bittiğinde
try {
  await ApiService.sendResult(...);
} catch (e) {
  // İnternet yoksa kuyruğa al
  await SyncQueueService.enqueue(gameData);
}
```

### 6.3 — [MODIFY] `lib/screens/memory_game_screen.dart`

**Değişiklik 1:** Satır 269'daki TEST butonu kaldırılacak
**Değişiklik 2:** Offline destek (duel ile aynı mantık)

### 6.4 — [MODIFY] `lib/screens/leaderboard_screen.dart`

**Değişiklik 1:** Boş liste durumu için mesaj
**Değişiklik 2:** Hata durumu için retry butonu
**Değişiklik 3:** Pull-to-refresh desteği

---

# ADIM 7: Test & Doğrulama

## 7.1 — Backend Testleri

```bash
# Sunucuyu başlat
cd okey_master-main/okey-master-server
npm run dev

# Health check
curl http://localhost:3000/api/health
# Beklenen: {"status":"OK","db":"connected",...}
```

## 7.2 — Flutter Testleri

```bash
cd okey_master-main
flutter analyze          # Kod analizi
flutter run              # Emülatörde çalıştır
```

## 7.3 — Entegrasyon Test Senaryoları

| # | Senaryo | Beklenen Sonuç |
|---|---------|---------------|
| 1 | Uygulama ilk açılış | Firebase anonim giriş otomatik |
| 2 | Nick girip BAŞLA | Backend'e token ile kayıt |
| 3 | Düello oyna + bitir | Sonuç backend'e hash ile gönderilir |
| 4 | İnternet kapat + oyun bitir | Sonuç kuyruğa alınır |
| 5 | İnternet aç | Kuyruk otomatik işlenir |
| 6 | Liderlik tablosu | Güncel veriler çekilir |

---

## 📁 DOSYA DEĞİŞİKLİK ÖZETİ

### Yeni Dosyalar (6 adet)
| Dosya | Kaynak |
|-------|--------|
| `android/app/google-services.json` | `okey_master`'dan kopyala |
| `lib/firebase_options.dart` | `okey_master`'dan kopyala |
| `lib/utils/constants.dart` | `okey_master`'dan uyarla |
| `lib/services/save_service.dart` | `okey_master`'dan uyarla |
| `lib/services/connectivity_service.dart` | `okey_master`'dan uyarla |
| `lib/services/sync_queue_service.dart` | `okey_master`'dan uyarla |

### Değişecek Dosyalar (12 adet)
| Dosya | Değişiklik Özeti |
|-------|-----------------|
| `android/settings.gradle.kts` | Google Services plugin ekle |
| `android/app/build.gradle.kts` | Plugin + applicationId |
| `pubspec.yaml` | 7 yeni bağımlılık |
| `lib/main.dart` | Firebase init + anonim giriş |
| `lib/services/api_service.dart` | Token, timeout, hata yönetimi |
| `lib/screens/login_screen.dart` | Firebase ile kayıt akışı |
| `lib/screens/duel_game_screen.dart` | Güvenli shuffle + offline |
| `lib/screens/memory_game_screen.dart` | TEST butonu kaldır + offline |
| `lib/screens/leaderboard_screen.dart` | Boş/hata durumları |
| `okey-master-server/prisma/schema.prisma` | 5 yeni alan |
| `okey-master-server/src/controllers/auth.controller.js` | Test UID kaldır |
| `okey-master-server/src/controllers/game.controller.js` | 3 yeni fonksiyon |
| `okey-master-server/src/routes/auth.routes.js` | verifyToken ekle |
| `okey-master-server/src/routes/game.routes.js` | 3 yeni route |

### Değişmeyecek Dosyalar ✅
- `lib/models/okey_stone.dart` — Mevcut hali çalışıyor
- `lib/widgets/stone_widget.dart` — Mevcut animasyonlar güzel
- `okey-master-server/src/controllers/leaderboard.controller.js` — Prisma Query, zaten iyi
- `okey-master-server/src/controllers/achievement.controller.js` — Aynı
- `okey-master-server/src/controllers/stats.controller.js` — Aynı
- `okey-master-server/src/middleware/firebase-auth.js` — Aynı
- `okey-master-server/src/utils/prisma.js` — Aynı
- `okey-master-server/src/config/firebase-admin.js` — Aynı

---

## ⏱️ TAHMİNİ SÜRE

| Adım | Süre | Karmaşıklık |
|------|------|-------------|
| 1. Firebase Kurulumu | ~30 dk | Düşük (dosya kopyalama) |
| 2. pubspec.yaml | ~15 dk | Düşük |
| 3. Prisma Schema | ~30 dk | Orta (migration) |
| 4. Backend Güvenlik | ~2 saat | Yüksek |
| 5. Flutter Servisler | ~2 saat | Yüksek |
| 6. Ekran Güncellemeleri | ~1.5 saat | Orta |
| 7. Test | ~1 saat | Orta |
| **TOPLAM** | **~8 saat** | |
