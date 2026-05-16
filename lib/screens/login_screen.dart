import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final Function(String, String) onSelect;
  const LoginScreen({required this.onSelect, super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nickController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? registeredNick;
  bool isLoading = false;
  bool isGuestMode = false;
  bool isEmailMode = false;
  bool isLogin = true;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  void _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedNick = prefs.getString('user_nick');
    
    // Eğer Firebase'de oturum varsa ve lokalde de nick varsa lobiye geç
    if (AuthService.currentUser != null && savedNick != null) {
      setState(() => registeredNick = savedNick);
    } else {
      // Oturum düşmüş veya senkronizasyon bozulmuşsa temizle
      await prefs.remove('user_nick');
      await AuthService.signOut();
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => isGuestMode = true);
  }

  Future<void> _registerGuest() async {
    String nick = _nickController.text.trim();
    if (nick.length < 2) {
      _showError("Kullanıcı adı en az 2 karakter olmalıdır.");
      return;
    }

    setState(() => isLoading = true);

    try {
      // 1. Firebase Anonim Giriş
      if (AuthService.currentUser == null) {
        await AuthService.signInAsGuest();
      }

      // 2. Sunucuya Kayıt
      final result = await ApiService.registerPlayer(nick);
      final int statusCode = result['status'] as int;
      final String? assignedUsername = result['username'] as String?;

      if (statusCode == 201 || statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final actualNick = assignedUsername ?? nick;
        await prefs.setString('user_nick', actualNick);
        setState(() {
          registeredNick = actualNick;
          isGuestMode = false;
        });
      } else if (statusCode == 409) {
        _showError("Bu isim zaten alınmış!");
      } else {
        _showError("Sunucu Hatası ($statusCode)!");
      }
    } catch (e) {
      _showError("Giriş yapılamadı: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String nick = _nickController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Lütfen e-posta ve şifrenizi girin.");
      return;
    }

    if (!isLogin && nick.length < 2) {
      _showError("Kullanıcı adı en az 2 karakter olmalıdır.");
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await AuthService.signInWithEmail(email, password);
      } else {
        await AuthService.registerWithEmail(email, password);
      }

      // Sunucuya Kayıt / Bilgi Çekme
      // Eğer giriş yapılıyorsa ve backend'de zaten kayıtlıysa gönderilen username önemsenmez,
      // ancak backend doğrulamasını (min 2 karakter) geçmek için geçerli bir string gönderiyoruz.
      String dummyNick = email.split('@')[0];
      if (dummyNick.length < 2) dummyNick += "user";
      final result = await ApiService.registerPlayer(isLogin ? dummyNick : nick);
      final int statusCode = result['status'] as int;
      final String? assignedUsername = result['username'] as String?;

      if (statusCode == 201 || statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final actualNick = assignedUsername ?? (isLogin ? email.split('@')[0] : nick);
        await prefs.setString('user_nick', actualNick);
        setState(() {
          registeredNick = actualNick;
          isEmailMode = false;
        });
      } else if (statusCode == 409) {
        _showError("Bu kullanıcı adı zaten alınmış!");
      } else {
        _showError("Sunucu Hatası ($statusCode)!");
      }
    } catch (e) {
      _showError("${isLogin ? 'Giriş' : 'Kayıt'} başarısız: ${e.toString().split(']').last.trim()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => isLoading = true);

    try {
      // 1. Google ile Firebase Girişi
      final cred = await AuthService.signInWithGoogle();
      final user = cred.user;
      
      if (user == null) throw Exception("Kullanıcı bilgisi alınamadı");

      String nick = user.displayName ?? "Oyuncu_${user.uid.substring(0, 5)}";

      // 2. Sunucuya Kayıt (Google bilgilerini sunucu otomatik alacak)
      final result = await ApiService.registerPlayer(nick);
      final int statusCode = result['status'] as int;
      final String? assignedUsername = result['username'] as String?;

      if (statusCode == 201 || statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final actualNick = assignedUsername ?? nick;
        await prefs.setString('user_nick', actualNick);
        setState(() => registeredNick = actualNick);
      } else if (statusCode == 409) {
        _showError("Google isminiz sistemde başka birine ait! Lütfen farklı bir takma isim belirleyin.");
        setState(() {
          isGuestMode = true;
          _nickController.text = nick;
        });
      } else {
        _showError("Sunucu Hatası ($statusCode)!");
      }
    } catch (e) {
      _showError("Google girişi başarısız: ${e.toString().split(']').last.trim()}");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_nick');
    await AuthService.signOut();
    setState(() {
      registeredNick = null;
      isGuestMode = false;
      isEmailMode = false;
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.mainBackgroundDecoration,
        child: SafeArea(
          child: registeredNick == null 
              ? _buildAuthUI() 
              : _buildLobbyUI(),
        ),
      ),
    );
  }

  Widget _buildAuthUI() {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.symmetric(horizontal: 25),
            decoration: AppTheme.glassDecoration(borderRadius: 25, glow: true),
            child: Column(
              mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.casino, size: 70, color: AppTheme.accentCyan),
            const SizedBox(height: 15),
            const Text(
              "OKEY ARCADE",
              style: TextStyle(
                color: Colors.white, 
                fontSize: 32, 
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                shadows: [Shadow(color: AppTheme.accentCyan, blurRadius: 10)]
              )
            ),
            const SizedBox(height: 30),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(color: AppTheme.accentCyan),
              )
            else if (isGuestMode)
              _buildGuestInputUI()
            else if (isEmailMode)
              _buildEmailAuthUI()
            else
              _buildAuthButtons(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildAuthButtons() {
    return Column(
      children: [
        // E-posta ile Giriş Butonu
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            fixedSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.black54,
          ),
          onPressed: () => setState(() => isEmailMode = true),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 24, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text("E-posta ile Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          )
        ),
        const SizedBox(height: 15),

        // Google Giriş Butonu
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            fixedSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 5,
            shadowColor: Colors.black54,
          ),
          onPressed: _handleGoogleLogin, 
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Google Icon (kısa yoldan oluşturulmuş basit bir icon veya asset)
              const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
              const SizedBox(width: 8),
              const Text("Google ile Giriş Yap", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          )
        ),
        
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.white30, thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text("veya", style: TextStyle(color: Colors.white54)),
              ),
              Expanded(child: Divider(color: Colors.white30, thickness: 1)),
            ],
          ),
        ),

        // Misafir Butonu
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white54, width: 1.5),
            fixedSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          onPressed: _handleGuestLogin,
          child: const Text("Misafir Olarak Devam Et", style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildGuestInputUI() {
    return Column(
      children: [
        TextField(
          controller: _nickController,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: "Bir takma isim belirleyin",
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppTheme.accentCyan, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => setState(() => isGuestMode = false),
            ),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: AppTheme.accentCyan.withOpacity(0.5),
                ),
                onPressed: _registerGuest, 
                child: const Text("BAŞLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildEmailAuthUI() {
    return Column(
      children: [
        Text(
          isLogin ? "E-posta ile Giriş" : "E-posta ile Kayıt",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        if (!isLogin) ...[
          TextField(
            controller: _nickController,
            style: const TextStyle(color: Colors.black87),
            decoration: InputDecoration(
              hintText: "Kullanıcı Adı",
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: "E-posta Adresi",
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: "Şifre",
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => setState(() => isEmailMode = false),
            ),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: AppTheme.accentCyan.withOpacity(0.5),
                ),
                onPressed: _handleEmailAuth,
                child: Text(isLogin ? "GİRİŞ YAP" : "KAYIT OL", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () => setState(() => isLogin = !isLogin),
          child: Text(
            isLogin ? "Hesabınız yok mu? Kayıt olun" : "Zaten hesabınız var mı? Giriş yapın",
            style: const TextStyle(color: Colors.white70),
          ),
        )
      ],
    );
  }

  Widget _buildLobbyUI() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.accentCyan, width: 2),
                boxShadow: [BoxShadow(color: AppTheme.accentCyan.withOpacity(0.3), blurRadius: 10)]
              ),
              child: const Icon(Icons.person, size: 50, color: AppTheme.accentCyan),
            ),
            const SizedBox(height: 15),
            const Text("LOBİ", style: TextStyle(color: Colors.white, fontSize: 32, letterSpacing: 4, fontWeight: FontWeight.w900)),
            Text("Hoş geldin, $registeredNick", style: const TextStyle(color: AppTheme.accentAmber, fontSize: 18, fontWeight: FontWeight.w500)),
            
            if (AuthService.currentUser?.isAnonymous == true)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Misafir Hesap", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ),

            const SizedBox(height: 30),
            _lobbyButton("DÜELLO (LOKAL)", "duel_2p", Icons.people),
            _lobbyButton("DÜELLO (ONLİNE)", "duel_online", Icons.public, isPrimary: true),
            _lobbyButton("HAFIZA (LOKAL)", "memory_2p", Icons.psychology),
            const Divider(color: Colors.white24, indent: 50, endIndent: 50, height: 40),
            _lobbyButton("DÜELLO (BOT)", "duel_bot", Icons.smart_toy),
            _lobbyButton("HAFIZA (BOT)", "memory_bot", Icons.memory),
            const Divider(color: Colors.white24, indent: 50, endIndent: 50, height: 40),
            _lobbyButton("PROFİLİM", "profile", Icons.person_outline),
            _lobbyButton("LİDERLİK TABLOSU", "leaderboard", Icons.emoji_events),
            _lobbyButton("AYARLAR", "settings", Icons.settings),
            const SizedBox(height: 30),
            TextButton.icon(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              label: const Text("Çıkış Yap", style: TextStyle(color: Colors.white70, fontSize: 16)),
              onPressed: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _lobbyButton(String title, String route, IconData icon, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 30),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPrimary ? AppTheme.accentCyan.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(color: isPrimary ? AppTheme.accentCyan : Colors.white24, width: 1)
              ),
              elevation: 0,
            ),
            onPressed: () => widget.onSelect(registeredNick!, route),
            child: Row(
              children: [
                Icon(icon, size: 24, color: isPrimary ? AppTheme.accentCyan : Colors.white70),
                const SizedBox(width: 15),
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isPrimary ? AppTheme.accentCyan : Colors.white, letterSpacing: 1.2))),
                Icon(Icons.arrow_forward_ios, size: 16, color: isPrimary ? AppTheme.accentCyan : Colors.white24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}