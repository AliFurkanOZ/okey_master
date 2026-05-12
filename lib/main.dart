import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/duel_game_screen.dart';
import 'screens/memory_game_screen.dart';
import 'screens/leaderboard_screen.dart';

void main() {
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
        primarySwatch: Colors.brown,
        useMaterial3: true,
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

    // 4. LİDERLİK TABLOSU
    if (currentScreen == "leaderboard") {
      return LeaderboardScreen(
        onExit: () => changeScreen(userNickname, "login")
      );
    }

    // Varsayılan hata dönüşü
    return const Scaffold(body: Center(child: Text("Ekran Yüklenemedi!")));
  }
}