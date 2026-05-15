import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/save_service.dart';
import 'screens/login_screen.dart';
import 'screens/duel_game_screen.dart';
import 'screens/memory_game_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/online_duel_screen.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase başlat
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Auth durumuna göre yönlendirme mantığı LoginScreen içinde veya burada yapılacak
    // Önceden burada olan signInAnonymously kaldırıldı.
  } catch (e) {
    debugPrint('Firebase başlatma hatası: $e');
  }

  // 3. SaveService başlat
  final saveService = SaveService();
  await saveService.init();

  // BGM (Arka Plan Müziği) Başlat
  AudioService.playBGM();

  runApp(const OkeyApp());
}

class OkeyApp extends StatelessWidget {
  const OkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Okey Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.amber,
        ),
      ),
      home: const OkeyAppFlow(),
    );
  }
}

class OkeyAppFlow extends StatefulWidget {
  const OkeyAppFlow({super.key});

  @override
  State<OkeyAppFlow> createState() => _OkeyAppFlowState();
}

class _OkeyAppFlowState extends State<OkeyAppFlow> {
  String currentScreen = "login";
  String userNickname = "";

  // Ekran değiştirme mantığı
  void changeScreen(String nick, String screenName) {
    setState(() {
      userNickname = nick;
      currentScreen = screenName;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. GİRİŞ VE LOBİ EKRANI
    if (currentScreen == "login") {
      return LoginScreen(onSelect: (nick, screen) => changeScreen(nick, screen));
    }

    // 2. DÜELLO (TAŞ İTME) MODLARI
    if (currentScreen == "duel_2p") {
      return DuelGameScreen(
        nickname: userNickname, 
        isBotMode: false, 
        onExit: () => changeScreen(userNickname, "login")
      );
    }
    if (currentScreen == "duel_online") {
      return OnlineDuelScreen(
        nickname: userNickname,
        onExit: () => changeScreen(userNickname, "login")
      );
    }
    if (currentScreen == "duel_bot") {
      return DuelGameScreen(
        nickname: userNickname, 
        isBotMode: true, 
        onExit: () => changeScreen(userNickname, "login")
      );
    }

    // 3. HAFIZA OYUNU MODLARI
    if (currentScreen == "memory_2p") {
      return OkeyMemoryGame(
        nickname: userNickname, 
        isBotMode: false, 
        onExit: () => changeScreen(userNickname, "login")
      );
    }
    if (currentScreen == "memory_bot") {
      return OkeyMemoryGame(
        nickname: userNickname, 
        isBotMode: true, 
        onExit: () => changeScreen(userNickname, "login")
      );
    }

    // 4. LİDERLİK TABLOSU VE PROFİL
    if (currentScreen == "leaderboard") {
      return LeaderboardScreen(
        onExit: () => changeScreen(userNickname, "login")
      );
    }
    if (currentScreen == "profile") {
      return ProfileScreen(
        nickname: userNickname,
        onExit: () => changeScreen(userNickname, "login")
      );
    }
    if (currentScreen == "settings") {
      return SettingsScreen(
        nickname: userNickname,
        onExit: () => changeScreen(userNickname, "login")
      );
    }

    // Varsayılan hata dönüşü
    return const Scaffold(body: Center(child: Text("Ekran Yüklenemedi!")));
  }
}