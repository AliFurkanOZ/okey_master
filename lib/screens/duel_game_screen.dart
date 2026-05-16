import 'package:flutter/material.dart';
import 'dart:math';
import '../models/okey_stone.dart';
import '../widgets/stone_widget.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';
import '../services/audio_service.dart';
import 'package:confetti/confetti.dart';
import '../theme/app_theme.dart';

class DuelGameScreen extends StatefulWidget {
  final String nickname;
  final bool isBotMode;
  final VoidCallback onExit;
  const DuelGameScreen({required this.nickname, required this.isBotMode, required this.onExit, super.key});

  @override
  State<DuelGameScreen> createState() => _DuelGameScreenState();
}

class _DuelGameScreenState extends State<DuelGameScreen> {
  List<List<OkeyStone>> playerCols = List.generate(6, (_) => []);
  List<List<OkeyStone>> opponentCols = List.generate(6, (_) => []);
  Map<int, int?> playerRules = {}; 
  Map<int, int?> opponentRules = {};
  
  OkeyStone? stagedStone;
  bool isPlayerTurn = true; 
  bool isAnimating = false;
  bool cameFromPlayer = true; 
  String? winner;

  String get p1Name => widget.isBotMode ? "SİZ" : "1. OYUNCU";
  String get p2Name => widget.isBotMode ? "BOT" : "2. OYUNCU";

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initGame();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initGame() {
    List<String> colors = ['siyah', 'mavi', 'kirmizi', 'sari'];
    List<OkeyStone> deck = [];
    for (var c in colors) {
      for (int i = 1; i <= 12; i++) {
        deck.add(OkeyStone(path: 'assets/images/${c}_$i.png', id: '${c}_${i}_${Random().nextInt(1000)}', value: i, color: c));
      }
    }
    // Fisher-Yates + Random.secure() (kriptografik güvenli)
    final rng = Random.secure();
    for (int i = deck.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final temp = deck[i]; deck[i] = deck[j]; deck[j] = temp;
    }
    setState(() {
      winner = null;
      isPlayerTurn = true;
      cameFromPlayer = true;
      playerRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null};
      opponentRules = {0: null, 1: null, 2: null, 3: null, 4: null, 5: null};
      for (int i = 0; i < 6; i++) {
        playerCols[i] = List.generate(4, (_) => deck.removeLast()..isRevealed = false);
        opponentCols[i] = List.generate(4, (_) => deck.removeLast()..isRevealed = false);
      }
      stagedStone = OkeyStone(path: 'assets/images/sahte_okey.png', id: 'joker', value: 0, color: 'joker', isRevealed: true);
    });
  }

  void _handleMove(int colIdx, bool isFromPlayer) async {
    if (isAnimating || stagedStone == null || isPlayerTurn != isFromPlayer || winner != null) return;
    
    Map<int, int?> currentRules = isFromPlayer ? playerRules : opponentRules;
    if (stagedStone!.id != 'joker') {
      if (currentRules[colIdx] != null && currentRules[colIdx] != stagedStone!.value) return;
      if (currentRules[colIdx] == null && (playerRules.containsValue(stagedStone!.value) || opponentRules.containsValue(stagedStone!.value))) return;
    }
    
    setState(() { isAnimating = true; cameFromPlayer = isFromPlayer; });
    List<List<OkeyStone>> targetGrid = isFromPlayer ? playerCols : opponentCols;
    OkeyStone exiting = targetGrid[colIdx].last;
    OkeyStone entering = stagedStone!;
    
    if (currentRules[colIdx] == null && entering.id != 'joker') currentRules[colIdx] = entering.value;
    
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    
    setState(() {
      targetGrid[colIdx].removeLast();
      entering.isRevealed = true;
      targetGrid[colIdx].insert(0, entering);
      exiting.isRevealed = true;
      stagedStone = exiting;
      isAnimating = false;
    });
    AudioService.playStoneMove();
    _determineNextTurn();
  }

  void _determineNextTurn() async {
    if (_checkWin(playerCols)) { 
      winner = p1Name; 
      if(widget.isBotMode) {
        try {
          debugPrint('[DuelGame] Oyuncu kazandı! Sonuç gönderiliyor...');
          await ApiService.sendResult(nickname: widget.nickname, isWin: true, type: "duel");
          debugPrint('[DuelGame] Sonuç başarıyla gönderildi!');
        } catch (e) {
          debugPrint('[DuelGame] Sonuç gönderilemedi, kuyruğa ekleniyor: $e');
          await SyncQueueService.enqueue({"nickname": widget.nickname, "isWin": true, "type": "duel"});
        }
      }
      _showVictoryDialog(); return; 
    }
    if (_checkWin(opponentCols)) { 
      winner = p2Name; 
      if(widget.isBotMode) {
        try {
          debugPrint('[DuelGame] Bot kazandı! Sonuç gönderiliyor...');
          await ApiService.sendResult(nickname: widget.nickname, isWin: false, type: "duel");
          debugPrint('[DuelGame] Sonuç başarıyla gönderildi!');
        } catch (e) {
          debugPrint('[DuelGame] Sonuç gönderilemedi, kuyruğa ekleniyor: $e');
          await SyncQueueService.enqueue({"nickname": widget.nickname, "isWin": false, "type": "duel"});
        }
      }
      _showVictoryDialog(); return; 
    }
    
    if (stagedStone!.id == 'joker') { isPlayerTurn = !isPlayerTurn; }
    else {
      bool pHasIt = playerRules.containsValue(stagedStone!.value);
      bool oHasIt = opponentRules.containsValue(stagedStone!.value);
      if (isPlayerTurn) {
        if (pHasIt) isPlayerTurn = true; else if (oHasIt) isPlayerTurn = false;
        else { isPlayerTurn = false; if (!opponentRules.containsValue(null)) isPlayerTurn = true; }
      } else {
        if (oHasIt) isPlayerTurn = false; else if (pHasIt) isPlayerTurn = true;
        else { isPlayerTurn = true; if (!playerRules.containsValue(null)) isPlayerTurn = false; }
      }
    }
    if (widget.isBotMode && !isPlayerTurn && winner == null) _playBotTurn();
  }

  void _playBotTurn() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted || winner != null || isPlayerTurn) return;
    int? colToPlay;
    for (int i = 0; i < 6; i++) { if (opponentRules[i] == stagedStone!.value) { colToPlay = i; break; } }
    if (colToPlay == null && stagedStone!.id != 'joker' && !playerRules.containsValue(stagedStone!.value)) {
      for (int i = 0; i < 6; i++) { if (opponentRules[i] == null) { colToPlay = i; break; } }
    }
    if (colToPlay == null && stagedStone!.id == 'joker') {
      for (int i = 0; i < 6; i++) { if (opponentRules[i] == null) { colToPlay = i; break; } }
    }
    if (colToPlay != null) _handleMove(colToPlay, false); else setState(() { isPlayerTurn = true; });
  }

  bool _checkWin(List<List<OkeyStone>> grid) {
    return grid.every((col) {
      if (col.length != 4) return false;
      int firstVal = col[0].value;
      if (firstVal == 0) return false; 
      return col.every((s) => s.isRevealed && s.value == firstVal) && col.map((s) => s.color).toSet().length == 4;
    });
  }

  void _showVictoryDialog() {
    _confettiController.play();
    if(winner == p1Name) {
      AudioService.playWin();
    } else {
      AudioService.playLose();
    }
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => AlertDialog(
      backgroundColor: Colors.brown.shade900,
      title: const Text("OYUN BİTTİ!", style: TextStyle(color: Colors.amber)),
      content: Text("Kazanan: $winner"),
      actions: [
        TextButton(onPressed: () { Navigator.pop(ctx); _initGame(); }, child: const Text("TEKRAR", style: TextStyle(color: Colors.amber))),
        TextButton(onPressed: () { Navigator.pop(ctx); widget.onExit(); }, child: const Text("MENÜ")),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onExit)),
      body: Container(
        decoration: AppTheme.mainBackgroundDecoration,
        child: Stack(
          children: [
            Column(children: [
              Text(p2Name, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              Expanded(child: _buildGrid(opponentCols, false)),
              Container(height: 160, alignment: Alignment.center, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(isPlayerTurn ? "SIRA: $p1Name" : "SIRA: $p2Name", style: TextStyle(color: isPlayerTurn ? Colors.green.shade900 : Colors.red.shade900, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (stagedStone != null) StoneFlipWrapper(key: ValueKey(stagedStone!.id), stone: stagedStone!)
              ])),
              Expanded(child: _buildGrid(playerCols, true)),
              Text(p1Name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ]),
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

  Widget _buildGrid(List<List<OkeyStone>> grid, bool isPlayer) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(6, (colIdx) {
      bool myTurn = (isPlayer == isPlayerTurn);
      return GestureDetector(
        onTap: () => _handleMove(colIdx, isPlayer),
        child: Container(width: 55, height: 310, margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(color: myTurn ? Colors.white.withOpacity(0.15) : Colors.black26, borderRadius: BorderRadius.circular(8)),
          child: Stack(children: grid[colIdx].asMap().entries.map((entry) => AnimatedPositioned(key: ValueKey(entry.value.id), duration: const Duration(milliseconds: 450), top: (entry.key * 74.0), left: 0, right: 0, child: StoneBody3D(stone: entry.value))).toList()),
        ),
      );
    }));
  }
}