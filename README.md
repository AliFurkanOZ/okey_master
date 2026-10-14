# 🀄 Okey Master (Okey Arcade)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![Express.js](https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white)
![Socket.IO](https://img.shields.io/badge/Socket.io-010101?style=for-the-badge&logo=socketdotio&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![License](https://img.shields.io/badge/License-MIT-blue.style=for-the-badge)

**Geleneksel Türk Okey heyecanını modern arcade mekanikleri, gerçek zamanlı çok oyunculu düello ve rekabetçi sıralama sistemiyle buluşturan yeni nesil mobil oyun.**

[Özellikler](#-öne-çıkan-özellikler) • [Mimari](#-sistem-mimarisi) • [Teknolojiler](#-teknoloji-yığını) • [Kurulum](#-kurulum-ve-başlangıç) • [API & WebSocket](#-api-ve-websocket-dokümantasyonu) • [Testler](#-test-ve-kalite-güvencesi)

</div>

---

## 📖 Proje Hakkında

**Okey Master**, klasik okey taşlarını yenilikçi oyun modlarıyla harmanlayan, tam yığın (full-stack) mimariye sahip kapsamlı bir mobil oyundur. İster arkadaşlarınızla aynı cihazda, ister akıllı yapay zeka botlarına karşı, isterseniz **Socket.IO** altyapısıyla Türkiye'nin dört bir yanındaki rakiplerle **gerçek zamanlı çevrimiçi düellolarda** yarışabilirsiniz.

Uygulama; **Flutter** tabanlı zengin görsel tasarımı (Glassmorphism, Dark Neon Arcade teması, konfeti animasyonları ve 3D taş modelleri), **Node.js & Express** mikroservis benzeri REST API'si, **PostgreSQL & Prisma ORM** veri tabanı ve **Firebase Auth** güvenliğiyle uçtan uca eksiksiz bir mimari sunar.

---

## ✨ Öne Çıkan Özellikler

### 🎮 1. Yenilikçi Oyun Modları
- **⚔️ Taş İtme Düellosu (Okey Duel):** 
  - 6 sütunlu taktiksel taş yerleştirme ve itme mekaniği.
  - 4 renk (Kırmızı, Mavi, Siyah, Sarı) ve 1-12 arası numaralandırılmış 48 taşlık deste.
  - Sütun kuralı belirleme, değer karşılaştırma ve stratejik taş yürütme.
  - **Mod Seçenekleri:** 
    - 🌐 *Çevrimiçi Çok Oyunculu (Online Multiplayer)* — Eşzamanlı oda eşleştirme.
    - 🤖 *Yapay Zeka (Bot)* — Taktiksel hamle yapan akıllı bot rakip.
    - 👥 *Yerel 2 Kişilik (Pass & Play)* — Tek ekranda iki kişi oynama keyfi.
- **🧠 Okey Hafıza Oyunu (Memory Match):**
  - Okey taşlarını eşleştirme hafıza kartı modu.
  - **3 Zorluk Seviyesi:** Kolay, Orta, Zor (Farklı taş sayıları ve bot hafıza yüzdesi).
  - Anlık kronometre sayacı, hamle sayısı ve en iyi sürelerin veritabanına kaydı.

---

### 🌐 2. Gerçek Zamanlı Çok Oyunculu Altyapı
- **Socket.IO Eşleştirme Kuyruğu:** Oyuncular sıraya girer, sunucu anında oda oluşturup iki oyuncuyu bağlar.
- **Sunucu Tarafı Güvenli Deste Dağıtımı:** Taşlar sunucuda kriptografik güvenlikle (`crypto.randomInt` + Fisher-Yates) karıştırılır ve oyunculara ters perspektifle dağıtılır.
- **Canlı Senkronizasyon & Kopma Yönetimi:** Hamleler anında karşı tarafa aktarılır; oyuncu ayrıldığında maç güvenle sonlandırılır.

---

### 🔐 3. Gelişmiş Kimlik Doğrulama & Hesap Bağlama (Firebase Auth)
- **Misafir Girişi (Guest Mode):** Kullanıcı adı girerek tek tıkla şifresiz, anonim Firebase hesabı ile oyuna başlama.
- **E-Posta / Şifre Kayıt ve Giriş:** Kalıcı profil oluşturma.
- **Google ile Giriş (Google Sign-In):** Hızlı ve güvenli oturum.
- **Kayıpsız Hesap Bağlama (Account Linking):** Misafir olarak kazanılan tüm skorlar, kupa ve başarımlar kaybolmadan hesabı Google veya E-Posta ile kalıcı hesaba dönüştürme.

---

### 📶 4. Çevrimdışı Destek & Akıllı Senkronizasyon (Offline-First)
- **Kuyruk Mekanizması (`SyncQueueService`):** İnternet bağlantısı koptuğunda oynanan oyunların sonuçları yerel hafızaya (`SharedPreferences`) alınır.
- **Otomatik Gönderim (`ConnectivityService`):** Ağ bağlantısı geri geldiğinde kuyruktaki sonuçlar otomatik olarak arka planda sunucuya iletilir.
- **Dead-Letter Queue (DLQ):** 5 defa üst üste iletilemeyen hatalı istekler güvenli bir kenara ayrılarak sonsuz döngü engellenir.

---

### 🏆 5. Liderlik Tablosu & Başarım Sistemi
- **Global Sıralamalar:** Düello galibiyetleri, seri kazanmalar ve Hafıza Oyunu rekor sürelerine göre anlık sıralama.
- **Kapsamlı Oyuncu Profili:** Toplam oyun, galibiyet/mağlubiyet oranı, kazanma serisi (win streak), en iyi seri, toplam oynama süresi ve rütbe seviyesi (Bronze, Silver, Gold vb.).
- **Dinamik Başarımlar:** Belirli koşulları (ör. ilk galibiyet, 5 seri, 30 saniye altı hafıza bitirme) sağlayan oyunculara özel rozetler.

---

### 🛡️ 6. Üst Düzey Güvenlik & Anti-Cheat
- **Firebase Token Doğrulama:** Tüm API istekleri `Bearer <token>` ile korunur; sahte skor gönderimi imkansızdır.
- **Idempotency Key:** Çift tıklama veya ağ tekrarlarında aynı maç sonucunun iki kez yazılmasını engelleyen tekil anahtar sistemi.
- **Rate Limiting & Helmet:** Sunucu seviyesinde DDoS ve Brute-Force koruması.
- **Zaman Aşımı ve Cron Temizliği:** Süresi dolmuş token ve idempotency anahtarları `node-cron` ile periyodik olarak temizlenir.

---

### 🎨 7. Modern UI / UX Tasarımı
- **Glassmorphism & Neon Dark Theme:** `AppTheme` ile özel koyu lacivert/petrol arka plan, saydam cam kartlar ve rafine teal/amber vurguları.
- **Tipografi:** Google Fonts `Inter` yazı tipi ailesi.
- **Ses Yönetimi (`AudioService`):** Açılıp kapatılabilen arka plan müziği (BGM) ve taş hareketi, galibiyet/mağlubiyet ses efektleri (SFX).
- **Kutlama Efektleri:** Galibiyet anında dinamik konfeti patlaması (`confetti`).
- **3D Model Desteği:** `model_viewer_plus` ile 3D Okey taşı modelleme yeteneği (`.glb` / `.obj`).

---

## 🏛️ Sistem Mimarisi

```mermaid
graph TD
    subgraph Client [Flutter Mobil Uygulama]
        UI[Ekranlar & Widget'lar<br/>Login, Duel, Memory, Profile, Settings]
        Services[Servis Katmanı<br/>Api, Socket, Auth, Save, Audio, SyncQueue]
        LocalDB[(SharedPreferences<br/>Offline Queue & Ayarlar)]
        UI --> Services
        Services <--> LocalDB
    end

    subgraph FirebaseCloud [Firebase Cloud]
        FAuth[Firebase Authentication<br/>Guest, Google, Email]
    end

    subgraph Backend [Node.js & Express Sunucusu]
        MW[Güvenlik & Middleware<br/>Helmet, RateLimit, TokenVerify]
        SocketServer[Socket.IO Server<br/>Oda Yönetimi & Deste Dağıtımı]
        REST[REST API Controllers<br/>Auth, Game, Stats, Leaderboard, Achievement]
        Prisma[Prisma ORM Client]
        Cron[Node-Cron<br/>Bakım Görevleri]
        
        MW --> REST
        REST --> Prisma
        Cron --> Prisma
    end

    subgraph Database [PostgreSQL]
        PG[(PostgreSQL DB<br/>Users, Games, Stats, Achievements, Leaderboard)]
    end

    Services -- "HTTP / REST (Bearer Token)" --> MW
    Services -- "WebSocket (Real-Time)" --> SocketServer
    Services -- "Kimlik Doğrulama" --> FAuth
    MW -- "Token Doğrulama" --> FAuth
    Prisma <--> PG
```

---

## 📁 Proje Dosya Yapısı

```bash
okey_master/
├── assets/                          # Uygulama içi statik varlıklar
│   ├── images/                      # Okey taşları (4 renk x 12 numara), arka plan, 3D glb
│   └── models/                      # 3D taş modelleri (.obj, .mtl)
├── lib/                             # Flutter istemci kaynak kodları
│   ├── firebase_options.dart        # Platform bazlı Firebase yapılandırması
│   ├── main.dart                    # Uygulama başlangıcı, tema ve ekran yönlendirici
│   ├── models/
│   │   └── okey_stone.dart          # Taş veri modeli (renk, değer, görsel yolu)
│   ├── screens/                     # Kullanıcı arayüzü ekranları
│   │   ├── duel_game_screen.dart    # Taş İtme Düellosu (Bot & Yerel 2P)
│   │   ├── online_duel_screen.dart  # Çevrimiçi Çok Oyunculu Düello (Socket.IO)
│   │   ├── memory_game_screen.dart  # Okey Hafıza Oyunu (Kolay/Orta/Zor)
│   │   ├── leaderboard_screen.dart  # Liderlik Sıralama Tablosu
│   │   ├── login_screen.dart        # Giriş, Kayıt ve Lobi Ekranı
│   │   ├── profile_screen.dart      # Oyuncu İstatistikleri ve Başarımlar
│   │   └── settings_screen.dart     # Ses, Müzik ve Hesap Bağlama Ayarları
│   ├── services/                    # İş mantığı ve veri erişim katmanı
│   │   ├── api_service.dart         # Backend REST API istemcisi
│   │   ├── socket_service.dart      # Socket.IO gerçek zamanlı bağlantı
│   │   ├── auth_service.dart        # Firebase Auth oturum ve hesap bağlama
│   │   ├── audio_service.dart       # Arka plan müziği ve ses efektleri
│   │   ├── connectivity_service.dart# Canlı internet bağlantı kontrolü
│   │   ├── save_service.dart        # Yerel veri saklama (SharedPreferences)
│   │   └── sync_queue_service.dart  # Çevrimdışı oyun sonuçları kuyruğu & DLQ
│   ├── theme/
│   │   └── app_theme.dart           # Neon Glassmorphism koyu tema tanımları
│   ├── utils/
│   │   └── constants.dart           # Çevresel sabitler (API_URL vb.)
│   └── widgets/
│       └── stone_widget.dart        # Etkileşimli ve animasyonlu taş bileşeni
├── okey-master-server/              # Backend sunucu projesi
│   ├── prisma/
│   │   └── schema.prisma            # PostgreSQL veritabanı şeması ve modelleri
│   ├── src/
│   │   ├── config/                  # Socket.IO ve Firebase Admin ayarları
│   │   ├── controllers/             # İstek işleyicileri (Auth, Game, Stats, vb.)
│   │   ├── middleware/              # Firebase token doğrulama middleware
│   │   ├── routes/                  # Express rotaları
│   │   ├── utils/                   # Prisma istemcisi vb. yardımcılar
│   │   └── index.js                 # Sunucu giriş noktası ve Cron görevleri
│   ├── test/                        # Backend Jest entegrasyon testleri
│   └── package.json                 # Node.js bağımlılıkları ve scriptleri
├── test/                            # Flutter birim ve widget testleri (16 test paketi)
└── pubspec.yaml                     # Flutter bağımlılıkları ve konfigürasyonu
```

---

## 🛠️ Teknoloji Yığını

### Mobil İstemci (Frontend)
| Teknoloji / Kütüphane | Sürüm | Kullanım Amacı |
|:---|:---|:---|
| **Flutter & Dart SDK** | SDK ^3.11.5 | Çapraz platform yüksek performanslı mobil geliştirme |
| **flutter_riverpod** | ^3.3.1 | Reaktif durum yönetimi (State Management) |
| **firebase_core & auth** | ^4.7.0 / ^6.4.0 | Anonim, Google ve E-posta kimlik doğrulama |
| **socket_io_client** | ^3.1.4 | Gerçek zamanlı çift yönlü WebSocket iletişimi |
| **http** | ^1.1.0 | REST API HTTP istekleri |
| **connectivity_plus** | ^7.1.1 | Ağ bağlantısı durumunu canlı izleme |
| **shared_preferences** | ^2.5.5 | Çevrimdışı kuyruk ve yerel ayar önbelleği |
| **audioplayers** | ^6.6.0 | Arka plan müziği (BGM) ve ses efektleri (SFX) |
| **google_fonts** | ^8.1.0 | Tipografi tasarımı (Inter fontu) |
| **confetti** | ^0.8.0 | Galibiyet kutlama partikül animasyonları |
| **model_viewer_plus** | ^1.7.0 | 3D Okey taşı görüntüleme ve etkileşimi |
| **equatable & crypto** | ^2.0.8 / ^3.0.3 | Model karşılaştırma ve istemci tarafı hash üretimi |

### Sunucu & Veritabanı (Backend)
| Teknoloji / Kütüphane | Sürüm | Kullanım Amacı |
|:---|:---|:---|
| **Node.js & Express** | Express 5.x | Hızlı, modüler RESTful backend mimarisi |
| **Socket.IO** | ^4.8.3 | Düşük gecikmeli gerçek zamanlı oyun odası sunucusu |
| **PostgreSQL** | Relational DB | Güvenilir ve ilişkisel veri saklama katmanı |
| **Prisma ORM** | ^7.7.0 | Tip güvenli veritabanı modellemesi ve migration yönetimi |
| **Firebase Admin SDK** | ^13.8.0 | Sunucu tarafı Firebase ID token doğrulama |
| **helmet** | ^8.1.0 | HTTP güvenlik başlıkları koruması |
| **express-rate-limit** | ^8.3.2 | API brute-force ve DDoS hız sınırlaması |
| **node-cron** | ^4.2.1 | Süresi dolan kayıtları temizleme ve periyodik görevler |

---

## 🚀 Kurulum ve Başlangıç

Projeyi yerel makinenizde çalıştırmak için aşağıdaki adımları sırasıyla uygulayabilirsiniz.

### 📋 Ön Koşullar
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.11 veya üzeri)
- [Node.js](https://nodejs.org/) (v18 veya üzeri) & npm
- [PostgreSQL](https://www.postgresql.org/) (Yerel veya Bulut örn: Supabase / Railway)
- Bir [Firebase](https://console.firebase.google.com/) Projesi (Authentication aktif edilmiş)

---

### 1️⃣ Projeyi Klonlayın
```bash
git clone https://github.com/AliFurkanOZ/okey_master.git
cd okey_master
```

---

### 2️⃣ Backend Sunucusunun Kurulumu

1. Sunucu dizinine geçin ve bağımlılıkları kurun:
   ```bash
   cd okey-master-server
   npm install
   ```

2. Ortam değişkenlerini hazırlayın:
   `.env.example` dosyasını kopyalayarak `.env` dosyasını oluşturun:
   ```bash
   cp .env.example .env
   ```
   `.env` dosyasını kendi veritabanı ve Firebase bilgilerinizle doldurun:
   ```env
   PORT=3000
   NODE_ENV=development
   DATABASE_URL="postgresql://kullanici:sifre@localhost:5432/okey_master?sslmode=disable"
   
   FIREBASE_PROJECT_ID="proje-id-buraya"
   FIREBASE_CLIENT_EMAIL="firebase-adminsdk-xxx@proje-id.iam.gserviceaccount.com"
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   ```

3. Veritabanı tablolarını oluşturun (Prisma Migration):
   ```bash
   npx prisma migrate dev --name init
   npx prisma generate
   ```

4. Sunucuyu başlatın:
   ```bash
   npm run dev
   ```
   > Sunucu varsayılan olarak `http://localhost:3000` portunda çalışacaktır. `http://localhost:3000/api/health` adresinden sağlık durumunu kontrol edebilirsiniz.

---

### 3️⃣ Flutter Mobil Uygulamasının Kurulumu

1. Ana proje dizinine dönün:
   ```bash
   cd ..
   ```

2. Flutter paketlerini indirin:
   ```bash
   flutter pub get
   ```

3. Firebase Yapılandırması:
   - Android için Firebase Console'dan indirdiğiniz `google-services.json` dosyasını `android/app/` dizinine yerleştirin.
   - FlutterFire CLI ile üretilen `firebase_options.dart` dosyasının projenizle eşleştiğinden emin olun.

4. Uygulamayı çalıştırın:
   - **Android Emülatör için** (Emülatör localhost'a `10.0.2.2` üzerinden erişir):
     ```bash
     flutter run
     ```
   - **Fiziksel Cihaz veya Farklı Sunucu için:**
     ```bash
     flutter run --dart-define=API_URL=http://BILGISAYAR_IP_ADRESINIZ:3000/api
     ```

---

## 📡 API ve WebSocket Dokümantasyonu

### 🌐 REST API Uç Noktaları

Tüm korumalı uç noktalar `Authorization: Bearer <Firebase_ID_Token>` başlığı gerektirir.

| Yöntem | Uç Nokta | Korumalı | Açıklama |
|:---:|:---|:---:|:---|
| `GET` | `/api/health` | ❌ | Sunucu ve veritabanı bağlantı sağlık kontrolü |
| `POST` | `/api/auth/register` | ✅ | Kullanıcı kaydı ve profil açılışı |
| `GET` | `/api/auth/profile` | ✅ | Aktif kullanıcının profil detayları |
| `PUT` | `/api/auth/username` | ✅ | Kullanıcı adı güncelleme |
| `POST` | `/api/games` | ✅ | Yeni oyun oturumu başlatma |
| `POST` | `/api/games/:id/finish`| ✅ | Oyun tamamlama, anti-cheat doğrulama ve skor kaydı |
| `POST` | `/api/games/result` | ✅ | Hafıza / Düello oyunu hızlı sonuç kaydı (Idempotent) |
| `GET` | `/api/stats/me` | ✅ | Oyuncunun kişisel istatistikleri ve kazanma serisi |
| `GET` | `/api/leaderboard` | ❌ | Global liderlik tablosu sıralaması |
| `GET` | `/api/achievements/me`| ✅ | Kullanıcının açtığı başarımlar listesi |
| `POST` | `/api/achievements/check` | ✅ | Koşulları sağlanan yeni başarımları tetikleme |

---

### ⚡ WebSocket (Socket.IO) Olayları

| Olay Adı | Yön | Veri İçeriği | Açıklama |
|:---|:---:|:---|:---|
| `join_queue` | İstemci ➔ Sunucu | `{ nickname, type: 'duel_online' }` | Oyuncuyu eşleştirme kuyruğuna ekler |
| `game_start` | Sunucu ➔ İstemci | `{ roomId, players, firstTurn, gameState }` | Eşleşme sağlandı, oda açıldı ve desteler dağıtıldı |
| `game_move` | İstemci ➔ Sunucu | `{ roomId, details: { colIdx, exitingStone } }` | Oyuncunun hamlesi sunucuya bildirilir |
| `opponent_move` | Sunucu ➔ İstemci | `{ colIdx, exitingStone }` | Rakibin hamlesi diğer oyuncuya iletilir |
| `game_end` | İstemci ➔ Sunucu | `{ roomId, details: { winner } }` | Maç sonu bildirilir ve oda temizlenir |
| `opponent_disconnected` | Sunucu ➔ İstemci | - | Rakip oyundan koptuğunda diğer oyuncuya haber verilir |

---

## 🧪 Test ve Kalite Güvencesi

Proje hem istemci (Flutter) hem de sunucu (Node.js) tarafında kapsamlı birim, widget ve entegrasyon testleriyle desteklenmektedir.

### Flutter Testlerini Çalıştırma
Tüm ekran, servis ve modelleri test etmek için:
```bash
flutter test
```
*Test kapsamı: `api_service_test`, `auth_service_test`, `socket_service_test`, `connectivity_service_test`, `sync_queue_service_test`, `save_service_test`, ekran testleri ve taş widget testleri.*

### Sunucu Testlerini Çalıştırma (Jest & Supertest)
```bash
cd okey-master-server
npm test
```
*Test kapsamı: Auth, Game controller, Stats, Leaderboard ve Achievement uç noktalarının mock doğrulamaları.*

---

## 🤝 Katkıda Bulunma

Projeye katkıda bulunmaktan mutluluk duyarız!
1. Bu depoyu Fork'layın (`Fork` butonuna tıklayın).
2. Özellik dalınızı oluşturun (`git checkout -b feature/YeniOzellik`).
3. Değişikliklerinizi commit'leyin (`git commit -m 'feat: Yeni bir mod eklendi'`).
4. Dalınıza push yapın (`git push origin feature/YeniOzellik`).
5. Bir **Pull Request** açın.

---

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) kapsamında lisanslanmıştır. Detaylar için `LICENSE` dosyasına göz atabilirsiniz.

---

<div align="center">

Geliştirici: **[Ali Furkan ÖZ](https://github.com/AliFurkanOZ)**  
*Sorularınız veya geri bildirimleriniz için GitHub Issues üzerinden iletişime geçebilirsiniz.*

⭐ Beğendiyseniz projeye bir yıldız bırakmayı unutmayın!

</div>
