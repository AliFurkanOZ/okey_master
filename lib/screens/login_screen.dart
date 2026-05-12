import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String) onSelect;
  const LoginScreen({required this.onSelect, super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nickController = TextEditingController();
  String? registeredNick;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSavedNick();
  }

  void _checkSavedNick() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedNick = prefs.getString('user_nick');
    if (savedNick != null) {
      setState(() => registeredNick = savedNick);
    }
  }

  void _register() async {
    String nick = _nickController.text.trim();
    if (nick.length < 2) {
      _showError("Kullanıcı adı en az 2 karakter olmalıdır.");
      return;
    }

    setState(() => isLoading = true);

    try {
      int statusCode = await ApiService.registerPlayer(nick);

      if (statusCode == 201 || statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_nick', nick);
        setState(() => registeredNick = nick);
      } else if (statusCode == 409) {
        _showError("Bu isim zaten alınmış!");
      } else {
        _showError("Sunucu Hatası ($statusCode)!");
      }
    } catch (e) {
      _showError("Bağlantı kurulamadı.");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_nick');
    setState(() => registeredNick = null);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Arka plan rengini gradient'in en koyu tonu yapıyoruz ki boşluk kalmasın
      backgroundColor: const Color(0xFF8B5A2B),
      body: Container(
        width: double.infinity,
        height: double.infinity, // TÜM EKRANI KAPLA
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFFE8D0A9), Color(0xFF8B5A2B)],
            radius: 1.3
          )
        ),
        child: registeredNick == null ? _buildRegisterUI() : _buildLobbyUI(),
      ),
    );
  }

  Widget _buildRegisterUI() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 30),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(20)
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "OKEY ARCADE",
              style: TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nickController,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Bir takma isim belirleyin",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 20),
            isLoading 
              ? const CircularProgressIndicator(color: Colors.amber)
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black
                  ),
                  onPressed: _register, 
                  child: const Text("BAŞLA")
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLobbyUI() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 60),
            const Text("LOBİ", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text("Hoş geldin, $registeredNick", style: const TextStyle(color: Colors.amber, fontSize: 18)),
            const SizedBox(height: 40),
            _lobbyButton("DÜELLO (2 OYUNCU)", "duel_2p"),
            _lobbyButton("HAFIZA (2 OYUNCU)", "memory_2p"),
            const Divider(color: Colors.white24, indent: 50, endIndent: 50, height: 40),
            _lobbyButton("DÜELLO (BOT)", "duel_bot"),
            _lobbyButton("HAFIZA (BOT)", "memory_bot"),
            const SizedBox(height: 10),
            _lobbyButton("LİDERLİK TABLOSU", "leaderboard"),
            const SizedBox(height: 30),
            TextButton(
              onPressed: _logout,
              child: const Text("Farklı İsimle Giriş Yap", style: TextStyle(color: Colors.white70))
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _lobbyButton(String title, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          fixedSize: const Size(280, 50),
          backgroundColor: Colors.white.withOpacity(0.9),
          foregroundColor: Colors.brown,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))
        ),
        onPressed: () => widget.onSelect(registeredNick!, route),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}