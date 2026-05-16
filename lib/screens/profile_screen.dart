import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final String nickname;
  final VoidCallback onExit;
  
  const ProfileScreen({
    required this.nickname, 
    required this.onExit, 
    super.key
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  Map<String, dynamic>? stats;
  List<dynamic> achievements = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final fetchedStats = await ApiService.getMyStats();
      final fetchedAchievements = await ApiService.getMyAchievements();
      
      if (mounted) {
        setState(() {
          stats = fetchedStats;
          achievements = fetchedAchievements;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profil verileri yüklenemedi: $e"))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0,
        title: const Text("OYUNCU PROFİLİ", style: TextStyle(color: AppTheme.accentCyan, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
              : _buildProfileContent(),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    final int totalGames = stats?['totalGames'] ?? 0;
    final String rank = stats?['rank'] ?? 'bronze';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // ÜST KISIM: Avatar, İsim ve Rank Progress
          _buildHeaderSection(rank),
          const SizedBox(height: 25),

          // EĞER OYUN OYNANMAMIŞSA: Call to Action (Sıfırdan başlayanlar için)
          if (totalGames == 0) _buildEmptyStateCTA(),

          // İSTATİSTİKLER (Grid yapısı)
          if (totalGames > 0) _buildStatsGrid(),
          const SizedBox(height: 25),
          
          // BAŞARIMLAR
          _buildAchievementsSection(),
          
          const SizedBox(height: 40), // Alt boşluk
        ],
      ),
    );
  }

  Widget _buildHeaderSection(String rank) {
    int currentScore = stats?['avgScore'] ?? 0;
    int nextRankScore = _getNextRankScore(rank);
    double progress = nextRankScore > 0 ? (currentScore / nextRankScore) : 1.0;
    if(progress > 1.0) progress = 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassDecoration(borderRadius: 25, glow: true, glowColor: _getRankColor(rank)),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: _getRankColor(rank), width: 3),
                      boxShadow: [BoxShadow(color: _getRankColor(rank).withOpacity(0.5), blurRadius: 10)]
                    ),
                    child: const Icon(Icons.person, size: 50, color: Colors.white),
                  ),
              const SizedBox(width: 20),
              // İsim ve Unvan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.nickname,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRankColor(rank).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rank.toUpperCase(),
                        style: TextStyle(color: _getRankColor(rank), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          // XP Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Rütbe İlerlemesi", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                  Text("$currentScore / $nextRankScore Puan", style: TextStyle(color: _getRankColor(rank), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(_getRankColor(rank)),
                ),
              )
            ],
          )
        ],
      ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateCTA() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.shade700, Colors.orange.shade900]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 15)]
      ),
      child: Column(
        children: [
          const Icon(Icons.videogame_asset, size: 50, color: Colors.white),
          const SizedBox(height: 10),
          const Text("Henüz Maç Yapmadın!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Hemen lobiye dön ve ilk Okey düellona başla. İstatistiklerin burada görünecek.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.orange.shade900,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            onPressed: widget.onExit,
            child: const Text("OYUNA BAŞLA", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 10),
          child: Text("KARİYER İSTATİSTİKLERİ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.25,
          children: [
            _statCard("Toplam Oyun", stats!['totalGames']?.toString() ?? '0', Icons.casino, Colors.blueAccent),
            _statCard("Kazanma", stats!['totalWins']?.toString() ?? '0', Icons.emoji_events, Colors.greenAccent),
            _statCard("Kazanma Serisi", stats!['winStreak']?.toString() ?? '0', Icons.local_fire_department, Colors.orange),
            _statCard("En İyi Seri", stats!['bestWinStreak']?.toString() ?? '0', Icons.whatshot, Colors.deepOrange),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: AppTheme.glassDecoration(borderRadius: 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 10, bottom: 10),
          child: Text("BAŞARIMLAR KÖŞESİ", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(borderRadius: 20),
              child: achievements.isEmpty
                  ? Column(
                      children: [
                        const Icon(Icons.lock_outline, size: 40, color: Colors.white30),
                        const SizedBox(height: 10),
                        const Text("Henüz açılmış başarım yok.", style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 5),
                        Text("Oynadıkça gizli başarımları keşfet!", style: TextStyle(color: AppTheme.accentAmber, fontSize: 12)),
                      ],
                    )
                  : Wrap(
                      spacing: 15,
                      runSpacing: 15,
                      alignment: WrapAlignment.center,
                      children: achievements.map((a) {
                        final ach = a['achievement'];
                        return _achievementBadge(ach['name'] ?? 'Rozet', ach['iconUrl'] ?? '🏆');
                      }).toList(),
                    ),
            ),
          ),
        )
      ],
    );
  }

  Widget _achievementBadge(String name, String icon) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.accentCyan.withOpacity(0.3))
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Text(icon.contains('http') ? '🏆' : icon, style: const TextStyle(fontSize: 35)),
          const SizedBox(height: 8),
          Text(
            name, 
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          )
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFFC0C0C0);
      case 'gold': return const Color(0xFFFFD700);
      case 'diamond': return const Color(0xFF00FFFF);
      case 'master': return const Color(0xFF9370DB);
      default: return AppTheme.accentCyan;
    }
  }

  int _getNextRankScore(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze': return 1000;
      case 'silver': return 2500;
      case 'gold': return 5000;
      case 'diamond': return 10000;
      case 'master': return 0; // Max rank
      default: return 1000;
    }
  }
}
