import 'package:flutter/material.dart';
import 'dart:math';
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

    // Oyun Başladı
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
        _initBoard();
      });
    });

    // Rakip Hamle Yaptı
    SocketService.on('opponent_move', (data) {
      if (!mounted) return;
      int colIdx = data['colIdx'];
      _applyOpponentMove(colIdx);
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

  void _initBoard() {
    List<String> colors = ['siyah', 'mavi', 'kirmizi', 'sari'];
    List<OkeyStone> deck = [];
    for (var c in colors) {
      for (int i = 1; i <= 12; i++) {
        deck.add(OkeyStone(path: 'assets/images/${c}_$i.png', id: '${c}_${i}_${Random().nextInt(1000)}', value: i, color: c));
      }
    }
    
    // Her iki taraf için aynı deste dizilimini garanti etmek adına
    // seed tabanlı prng kullanılabilirdi ama şimdilik client tarafında bağımsız kart çekiyoruz.
    // Görsel amaçlı her oyuncu kendi ekranında kartları görüyor. Gerçek kurallı senaryoda deste seed'i sunucudan gelmeli.
    final rng = Random();
    for (int i = deck.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = deck[i]; deck[i] = deck[j]; deck[j] = temp;
    }
    
    setState(() {
      winner = null;
      for (int i = 0; i < 6; i++) {
        playerCols[i] = List.generate(4, (_) => deck.removeLast()..isRevealed = false);
        opponentCols[i] = List.generate(4, (_) => deck.removeLast()..isRevealed = false);
      }
      stagedStone = OkeyStone(path: 'assets/images/sahte_okey.png', id: 'joker', value: 0, color: 'joker', isRevealed: true);
    });
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
      isPlayerTurn = false; // Sırayı rakibe ver
    });
    
    AudioService.playStoneMove();

    // Sunucuya hamleyi bildir
    SocketService.emit('game_move', {
      'roomId': roomId,
      'details': {'colIdx': colIdx}
    });

    _determineNextTurn(isAfterPlayerMove: true);
  }

  void _applyOpponentMove(int colIdx) async {
    if (isAnimating || stagedStone == null || winner != null) return;
    
    setState(() { isAnimating = true; });
    OkeyStone exiting = opponentCols[colIdx].last;
    OkeyStone entering = stagedStone!;
    
    if (opponentRules[colIdx] == null && entering.id != 'joker') opponentRules[colIdx] = entering.value;
    
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    
    setState(() {
      opponentCols[colIdx].removeLast();
      entering.isRevealed = true;
      opponentCols[colIdx].insert(0, entering);
      exiting.isRevealed = true;
      stagedStone = exiting;
      isAnimating = false;
      isPlayerTurn = true; // Sıra bize geçti
    });
    
    AudioService.playStoneMove();

    _determineNextTurn(isAfterPlayerMove: false);
  }

  void _determineNextTurn({required bool isAfterPlayerMove}) async {
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
    
    // Joker atıldıysa veya doluluk varsa sıra mantığını buraya entegre edebilirsiniz
    // Şu anki versiyonda Socket üzerinden sırayla değişiyor.
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
