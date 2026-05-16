import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final String nickname;
  final VoidCallback onExit;
  
  const SettingsScreen({
    required this.nickname, 
    required this.onExit, 
    super.key
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isMusicOn = true;
  bool isSfxOn = true;
  bool isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLinkWithGoogle() async {
    setState(() => isLoading = true);
    try {
      await AuthService.linkWithGoogle();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Google hesabınız başarıyla bağlandı! Artık hesabınızı kaybetmeyeceksiniz."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hesap bağlama başarısız: ${e.toString().split(']').last.trim()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showEmailLinkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("E-posta ile Bağla", style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "E-posta",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Şifre",
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                _handleLinkWithEmail();
              },
              child: const Text("Bağla"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLinkWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("E-posta ve şifre boş olamaz."), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await AuthService.linkWithEmail(email, password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("E-posta adresiniz başarıyla bağlandı! Artık hesabınızı kaybetmeyeceksiniz."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hesap bağlama başarısız: ${e.toString().split(']').last.trim()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showChangeUsernameDialog() {
    final TextEditingController usernameController = TextEditingController(text: widget.nickname);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Kullanıcı Adı Değiştir", style: TextStyle(color: Colors.amber)),
          content: TextField(
            controller: usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Yeni Kullanıcı Adı",
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                _handleChangeUsername(usernameController.text.trim());
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleChangeUsername(String newName) async {
    if (newName.length < 2 || newName.length > 50) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı adı 2 ile 50 karakter arasında olmalıdır."), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => isLoading = true);
    try {
      final result = await ApiService.updateUsername(newName);
      final int status = result['status'];
      
      if (mounted) {
        if (status == 200) {
          // Güncelleme başarılı
          // Normalde burada nick'i uygulamanın genel state'inde de değiştirmeliyiz.
          // Login ekranına çıkıp girilmesini önerebiliriz veya SharedPrefs güncelleyebiliriz.
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı adı başarıyla değiştirildi! Yeni isim bir sonraki girişinizde aktif olacak."), backgroundColor: Colors.green));
        } else if (status == 409) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bu kullanıcı adı zaten kullanılıyor!"), backgroundColor: Colors.redAccent));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata oluştu ($status)"), backgroundColor: Colors.redAccent));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bağlantı hatası: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showChangePasswordDialog() {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text("Şifre Değiştir", style: TextStyle(color: Colors.amber)),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Yeni Şifre",
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
              onPressed: () {
                Navigator.pop(context);
                _handleChangePassword(passwordController.text.trim());
              },
              child: const Text("Kaydet"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleChangePassword(String newPassword) async {
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre en az 6 karakter olmalıdır."), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => isLoading = true);
    try {
      await AuthService.changePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreniz başarıyla değiştirildi!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Şifre değiştirme başarısız (Güvenlik gereği çıkış yapıp tekrar giriş yapmanız gerekebilir): ${e.toString().split(']').last.trim()}"),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _toggleMusic(bool value) {
    setState(() => isMusicOn = value);
    if (isMusicOn) {
      AudioService.playBGM();
    } else {
      AudioService.stopBGM();
    }
  }

  void _toggleSfx(bool value) {
    setState(() => isSfxOn = value);
    // Not implemented fully in AudioService, but ready for logic.
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: const Text("AYARLAR", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentCyan), 
          onPressed: widget.onExit
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.mainBackgroundDecoration,
        child: SafeArea(
          child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accentCyan))
              : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(Icons.person, "HESAP YÖNETİMİ"),
                    const SizedBox(height: 10),
                    _buildAccountCard(user, isGuest),
                    const SizedBox(height: 30),

                    if (isGuest) ...[
                      _buildSectionHeader(Icons.link, "HESABI BAĞLA (KAYBETMEMEK İÇİN)"),
                      const SizedBox(height: 10),
                      _buildLinkOptions(),
                      const SizedBox(height: 30),
                    ],

                    _buildSectionHeader(Icons.volume_up, "SES VE MÜZİK"),
                    const SizedBox(height: 10),
                    _buildAudioSettings(),
                    const SizedBox(height: 30),

                    _buildSectionHeader(Icons.info_outline, "HAKKINDA"),
                    const SizedBox(height: 10),
                    _buildAboutSettings(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildAccountCard(User? user, bool isGuest) {
    bool hasPasswordProvider = user?.providerData.any((p) => p.providerId == 'password') ?? false;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(borderRadius: 20),
          child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGuest ? Colors.grey[700] : AppTheme.accentCyan.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGuest ? Icons.person_outline : Icons.verified_user, 
                  color: isGuest ? Colors.white70 : AppTheme.accentCyan, 
                  size: 30
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nickname,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isGuest ? "Misafir Hesap (Veriler kaybolabilir)" : "Kalıcı Hesap (${user?.email ?? 'Google'})",
                      style: TextStyle(
                        color: isGuest ? Colors.redAccent : Colors.greenAccent, 
                        fontSize: 12,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text("İsim Değiştir", style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _showChangeUsernameDialog,
                ),
              ),
              if (hasPasswordProvider) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.lock_outline, size: 16),
                    label: const Text("Şifre Değiştir", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showChangePasswordDialog,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildLinkOptions() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 30),
              SizedBox(width: 15),
              Expanded(
                child: Text(
                  "Uygulamayı silerseniz veya başka bir cihaza geçerseniz hesabınızı kaybedebilirsiniz. Devam etmek için hesabınızı bağlayın.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            fixedSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: _handleLinkWithGoogle,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.g_mobiledata, size: 30, color: Colors.red),
              const SizedBox(width: 8),
              const Text("Google ile Bağla", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          )
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            fixedSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: _showEmailLinkDialog,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 24, color: Colors.blueAccent),
              const SizedBox(width: 8),
              const Text("E-posta ile Bağla", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          )
        ),
      ],
    );
  }

  Widget _buildAudioSettings() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppTheme.glassDecoration(borderRadius: 20),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text("Arka Plan Müziği", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Oyundaki genel müzik", style: TextStyle(color: Colors.white54, fontSize: 12)),
                activeColor: AppTheme.accentCyan,
                value: isMusicOn,
                onChanged: _toggleMusic,
                secondary: Icon(isMusicOn ? Icons.music_note : Icons.music_off, color: isMusicOn ? AppTheme.accentCyan : Colors.white54),
              ),
              const Divider(color: Colors.white24, height: 1),
              SwitchListTile(
                title: const Text("Ses Efektleri", style: TextStyle(color: Colors.white)),
                subtitle: const Text("Taş hareketleri ve buton sesleri", style: TextStyle(color: Colors.white54, fontSize: 12)),
                activeColor: AppTheme.accentCyan,
                value: isSfxOn,
                onChanged: _toggleSfx,
                secondary: Icon(isSfxOn ? Icons.volume_up : Icons.volume_off, color: isSfxOn ? AppTheme.accentCyan : Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSettings() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppTheme.glassDecoration(borderRadius: 20),
          child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white54),
            title: const Text("Gizlilik Politikası", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            onTap: () {
              // TODO: İleride eklenebilir
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yakında eklenecek.")));
            },
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white54),
            title: const Text("Oyun Hakkında", style: TextStyle(color: Colors.white)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.backgroundDark,
                  title: const Text("Okey Arcade", style: TextStyle(color: AppTheme.accentCyan)),
                  content: const Text(
                    "Okey Arcade, arkadaşlarınızla veya botlara karşı oynayabileceğiniz modern ve dinamik bir okey oyunudur.\n\nSürüm: 1.0.0", 
                    style: TextStyle(color: Colors.white)
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Tamam", style: TextStyle(color: AppTheme.accentCyan)))
                  ],
                )
              );
            },
          ),
        ],
      ),
        ),
      ),
    );
  }
}
