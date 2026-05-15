import 'package:flutter/material.dart';
import '../models/okey_stone.dart';
import '../widgets/stone_widget.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/audio_service.dart';
import 'package:confetti/confetti.dart';

class OnlineDuelScreen extends StatefulWidget {
  final String nickname;
  final VoidCallback onExit;
  const OnlineDuelScreen({required this.nickname, required this.onExit, super.key});

  @override
  State<OnlineDuelScreen> createState() => _OnlineDuelScreenState();
}

class _OnlineDuelScreenState extends State<OnlineDuelScreen> {
  List<List<OkeyStone>> playerCols = List.generate(6, (_) => []);
  List<List<OkeyStone>> opponentCols = List.generate(6, (_) => []);
  Map<int, int?> playerRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null}; 
  Map<int, int?> opponentRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null};
  
  OkeyStone? stagedStone;
  bool isPlayerTurn = false; 
  bool isAnimating = false;
  String? winner;

  bool isWaiting = true;
  String? roomId;
  String opponentName = "RAKİP ARANIYOR...";
  String p1Name = "";

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    p1Name = widget.nickname;
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initSocket();
  }

  void _initSocket() {
    SocketService.connect();
    
    // Kuyruğa katıl
    SocketService.joinQueue(widget.nickname, 'duel_online');

    // Oyun Başladı — Sunucudan gelen gameState ile board oluştur
    SocketService.on('game_start', (data) {
      if (!mounted) return;
      setState(() {
        roomId = data['roomId'];
        isWaiting = false;
        
        // Rakibin ismini bul
        for(var p in data['players']) {
          if(p['id'] != SocketService.socketId) {
            opponentName = p['nickname'];
          }
        }

        // Kim başlayacak?
        isPlayerTurn = data['firstTurn'] == SocketService.socketId;

        // ============ SUNUCUDAN GELEN GAME STATE İLE BOARD OLUŞTUR ============
        final gameState = data['gameState'];
        _buildBoardFromServer(gameState);
      });
    });

    // Rakip Hamle Yaptı — Sunucudan gelen taş bilgisi ve sıra bilgisi ile güncelle
    SocketService.on('opponent_move', (data) {
      if (!mounted) return;
      int colIdx = data['colIdx'];
      // Rakipten çıkan taşın bilgisi de geliyor
      Map<String, dynamic>? exitingStoneData = data['exitingStone'] != null 
          ? Map<String, dynamic>.from(data['exitingStone']) 
          : null;
      // Sıra bilgisi: rakip bana "sıra sende mi?" diye söylüyor
      bool? nextTurnIsYours = data['nextTurnIsYours'];
      _applyOpponentMove(colIdx, exitingStoneData, nextTurnIsYours);
    });

    // Rakip Ayrıldı
    SocketService.on('opponent_disconnected', (_) {
      if (!mounted) return;
      setState(() {
        winner = p1Name;
      });
      _showVictoryDialog("Rakip oyundan ayrıldı!");
    });
  }

  @override
  void dispose() {
    SocketService.off('game_start');
    SocketService.off('opponent_move');
    SocketService.off('opponent_disconnected');
    // Odadan çık (sunucu zaten disconnect ile yakalar)
    SocketService.disconnect();
    _confettiController.dispose();
    super.dispose();
  }

  /// Sunucudan gelen gameState ile tahtayı oluştur
  void _buildBoardFromServer(Map<String, dynamic> gameState) {
    final playerStonesData = gameState['playerStones'] as List;
    final opponentStonesData = gameState['opponentStones'] as List;
    final centerStoneData = Map<String, dynamic>.from(gameState['centerStone']);

    winner = null;
    playerRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null};
    opponentRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null};

    // Oyuncu taşlarını yerleştir
    for (int col = 0; col < 6; col++) {
      final colData = (playerStonesData[col] as List);
      playerCols[col] = colData.map((stoneJson) {
        return OkeyStone.fromJson(Map<String, dynamic>.from(stoneJson));
      }).toList();
    }

    // Rakip taşlarını yerleştir
    for (int col = 0; col < 6; col++) {
      final colData = (opponentStonesData[col] as List);
      opponentCols[col] = colData.map((stoneJson) {
        return OkeyStone.fromJson(Map<String, dynamic>.from(stoneJson));
      }).toList();
    }

    // Ortadaki taş (joker ile başlar)
    stagedStone = OkeyStone.fromJson(centerStoneData);

    debugPrint('[OnlineDuel] Board sunucudan yüklendi. Ortadaki taş: ${stagedStone!.color}_${stagedStone!.value}');
    debugPrint('[OnlineDuel] Oyuncu sütun 0 ilk taş: ${playerCols[0].isNotEmpty ? "${playerCols[0][0].color}_${playerCols[0][0].value}" : "boş"}');
  }

  void _handleMove(int colIdx) async {
    if (isAnimating || stagedStone == null || !isPlayerTurn || winner != null || isWaiting) return;
    
    // Kural kontrolü
    if (stagedStone!.id != 'joker') {
      if (playerRules[colIdx] != null && playerRules[colIdx] != stagedStone!.value) return;
      if (playerRules[colIdx] == null && (playerRules.containsValue(stagedStone!.value) || opponentRules.containsValue(stagedStone!.value))) return;
    }
    
    setState(() { isAnimating = true; });
    OkeyStone exiting = playerCols[colIdx].last;
    OkeyStone entering = stagedStone!;
    
    if (playerRules[colIdx] == null && entering.id != 'joker') playerRules[colIdx] = entering.value;
    
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    
    setState(() {
      playerCols[colIdx].removeLast();
      entering.isRevealed = true;
      playerCols[colIdx].insert(0, entering);
      exiting.isRevealed = true;
      stagedStone = exiting;
      isAnimating = false;
      // isPlayerTurn burada DEĞİŞTİRİLMİYOR — _determineNextTurn hesaplayacak
    });
    
    AudioService.playStoneMove();

    // Önce sırayı hesapla (offline mantıkla)
    bool nextTurnIsMe = _calculateNextTurn(afterPlayerMove: true);
    
    setState(() {
      isPlayerTurn = nextTurnIsMe;
    });

    // Sunucuya hamleyi bildir — sıra bilgisini de gönder
    SocketService.emit('game_move', {
      'roomId': roomId,
      'details': {
        'colIdx': colIdx,
        'exitingStone': exiting.toJson(),
        'nextTurnIsYours': !nextTurnIsMe, // Rakibe "sıra sende mi?" bilgisi
      }
    });

    _checkForWins(isAfterPlayerMove: true);
  }

  void _applyOpponentMove(int colIdx, Map<String, dynamic>? exitingStoneData, bool? nextTurnIsYours) async {
    if (isAnimating || stagedStone == null || winner != null) return;
    
    setState(() { isAnimating = true; });
    
    // Ortadaki taş rakibin sütununa giriyor
    OkeyStone entering = stagedStone!;
    
    if (opponentRules[colIdx] == null && entering.id != 'joker') opponentRules[colIdx] = entering.value;
    
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    
    setState(() {
      // Rakibin sütunundan son taşı çıkar
      opponentCols[colIdx].removeLast();
      entering.isRevealed = true;
      opponentCols[colIdx].insert(0, entering);
      
      // Ortaya yeni taşı koy — rakipten gelen exitingStone bilgisi
      if (exitingStoneData != null) {
        stagedStone = OkeyStone.fromJson(exitingStoneData);
        stagedStone!.isRevealed = true;
      }
      
      isAnimating = false;
      // Sıra bilgisi rakipten geliyor — iki taraf da aynı sonucu kullanıyor
      isPlayerTurn = nextTurnIsYours ?? true;
    });
    
    AudioService.playStoneMove();

    _checkForWins(isAfterPlayerMove: false);
  }

  /// Ortadaki taşa göre sıranın kimde olacağını hesapla (offline mantık)
  /// true = sıra bende, false = sıra rakipte
  bool _calculateNextTurn({required bool afterPlayerMove}) {
    if (stagedStone == null) return !afterPlayerMove;
    
    if (stagedStone!.id == 'joker') {
      // Joker çıktıysa sıra diğer oyuncuya geçer
      return !afterPlayerMove;
    }
    
    bool pHasIt = playerRules.containsValue(stagedStone!.value);
    bool oHasIt = opponentRules.containsValue(stagedStone!.value);
    
    if (afterPlayerMove) {
      // Ben oynadım, yeni staged stone çıktı
      if (pHasIt) return true;        // Benim sütunumda bu değer var → sıra bende
      if (oHasIt) return false;       // Rakibin sütununda var → sıra rakipte
      // Hiçbirinde yok → rakibe geç (boş sütunu yoksa bana dön)
      if (!opponentRules.containsValue(null)) return true;
      return false;
    } else {
      // Rakip oynadı
      if (oHasIt) return false;       // Rakibin sütununda var → sıra rakipte kalır
      if (pHasIt) return true;        // Benim sütunumda var → sıra bende
      // Hiçbirinde yok → bana geç (boş sütunumuz yoksa rakipte kalsın)
      if (!playerRules.containsValue(null)) return false;
      return true;
    }
  }

  /// Kazanan var mı kontrol et
  void _checkForWins({required bool isAfterPlayerMove}) async {
    if (_checkWin(playerCols)) { 
      winner = p1Name; 
      await ApiService.sendResult(nickname: widget.nickname, isWin: true, type: "duel_online");
      _showVictoryDialog("Kazandın!"); 
      return; 
    }
    if (_checkWin(opponentCols)) { 
      winner = opponentName; 
      await ApiService.sendResult(nickname: widget.nickname, isWin: false, type: "duel_online");
      _showVictoryDialog("Kaybettin!"); 
      return; 
    }
  }

  bool _checkWin(List<List<OkeyStone>> grid) {
    return grid.every((col) {
      if (col.length != 4) return false;
      int firstVal = col[0].value;
      if (firstVal == 0) return false; 
      return col.every((s) => s.isRevealed && s.value == firstVal) && col.map((s) => s.color).toSet().length == 4;
    });
  }

  void _showVictoryDialog(String msg) {
    _confettiController.play();
    if(winner == p1Name) {
      AudioService.playWin();
    } else {
      AudioService.playLose();
    }
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.brown.shade900,
      title: const Text("OYUN BİTTİ!", style: TextStyle(color: Colors.amber)),
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); widget.onExit(); }, child: const Text("MENÜ")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onExit),
        title: Text(isWaiting ? "Eşleştiriliyor..." : "Online Düello", style: const TextStyle(color: Colors.amber)),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFE8D0A9), Color(0xFF8B5A2B)], radius: 1.3)),
        child: Stack(
          children: [
            isWaiting ? _buildWaitingUI() : _buildGameUI(),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Colors.amber),
          SizedBox(height: 20),
          Text("Rakip Bekleniyor...", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGameUI() {
    return Column(children: [
      Text(opponentName, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
      Expanded(child: _buildGrid(opponentCols, false)),
      Container(
        height: 160, 
        alignment: Alignment.center, 
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(isPlayerTurn ? "SIRA SENDE" : "SIRA RAKİPTE ($opponentName)", 
            style: TextStyle(color: isPlayerTurn ? Colors.green.shade900 : Colors.red.shade900, fontSize: 18, fontWeight: FontWeight.bold)
          ),
          const SizedBox(height: 10),
          if (stagedStone != null) StoneFlipWrapper(key: ValueKey(stagedStone!.id), stone: stagedStone!)
        ])
      ),
      Expanded(child: _buildGrid(playerCols, true)),
      Text(p1Name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
    ]);
  }

  Widget _buildGrid(List<List<OkeyStone>> grid, bool isPlayer) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (colIdx) {
      bool myTurn = (isPlayer && isPlayerTurn);
      return GestureDetector(
        onTap: () {
          if(isPlayer) _handleMove(colIdx);
        },
        child: Container(width: 55, height: 310, margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(color: myTurn ? Colors.white.withOpacity(0.15) : Colors.black26, borderRadius: BorderRadius.circular(8)),
          child: Stack(children: grid[colIdx].asMap().entries.map((entry) => AnimatedPositioned(key: ValueKey(entry.value.id), duration: const Duration(milliseconds: 450), top: (entry.key * 74.0), left: 0, right: 0, child: StoneBody3D(stone: entry.value))).toList()),
        ),
      );
    }));
  }
}
