import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async'; // Timer için gerekli
import '../models/okey_stone.dart';
import '../widgets/stone_widget.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';
enum BotDifficulty { easy, medium, hard }

class OkeyMemoryGame extends StatefulWidget {
  final String nickname;
  final bool isBotMode;
  final VoidCallback onExit;
  const OkeyMemoryGame({required this.nickname, required this.isBotMode, required this.onExit, super.key});

  @override
  State<OkeyMemoryGame> createState() => _OkeyMemoryGameState();
}

class _OkeyMemoryGameState extends State<OkeyMemoryGame> {
  // --- SENİN ASIL OYUN DEĞİŞKENLERİN ---
  List<OkeyStone> cards = [];
  List<int> flippedIndexes = [];
  List<int> botMemory = []; 
  bool isPlayerTurn = true;
  int playerScore = 0;
  int opponentScore = 0;
  bool isBusy = false;
  BotDifficulty? difficulty;
  bool gameStarted = false;

  // --- YENİ EKLENEN SÜRE ÖLÇER DEĞİŞKENLERİ ---
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer; // Ekrandaki saniyeyi anlık güncellemek için

  @override
  void initState() {
    super.initState();
    if (!widget.isBotMode) _setupGame(BotDifficulty.medium);
  }

  @override
  void dispose() {
    _stopwatch.stop();
    _timer?.cancel(); // Bellek sızıntısını önle
    super.dispose();
  }

  // --- OYUN KURULUMU ---
  void _setupGame(BotDifficulty selectedDiff) {
    List<String> colors = ['siyah', 'mavi', 'kirmizi', 'sari'];
    List<OkeyStone> uniqueStones = [];
    for (var c in colors) {
      for (int i = 1; i <= 12; i++) {
        uniqueStones.add(OkeyStone(path: 'assets/images/${c}_$i.png', id: '${c}_$i', value: i, color: c));
      }
    }
    uniqueStones.shuffle(); 
    List<OkeyStone> deck = [];
    for (int i = 0; i < 16; i++) {
      var stone = uniqueStones[i];
      deck.add(OkeyStone(path: stone.path, id: '${stone.id}_A', value: stone.value, color: stone.color));
      deck.add(OkeyStone(path: stone.path, id: '${stone.id}_B', value: stone.value, color: stone.color));
    }
    deck.shuffle();

    setState(() {
      cards = deck;
      flippedIndexes = [];
      botMemory = [];
      playerScore = 0;
      opponentScore = 0;
      isPlayerTurn = true;
      isBusy = false;
      difficulty = selectedDiff;
      gameStarted = true;
      
      // SÜRE BAŞLATMA
      _stopwatch.reset();
      _stopwatch.start();
      // Ekrandaki süreyi saniyede bir tazelemek için timer başlatıyoruz
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {}); 
      });
    });
  }

  // --- KART VE BOT MANTIĞI (DOKUNULMADI) ---
  void _onCardTap(int index) async {
    if (isBusy || cards[index].isRevealed || flippedIndexes.contains(index)) return;
    if (widget.isBotMode && !isPlayerTurn) return;
    _revealCard(index);
    if (flippedIndexes.length == 2) _checkMatchLogic();
  }

  void _revealCard(int index) {
    setState(() {
      cards[index].isRevealed = true;
      flippedIndexes.add(index);
      if (!botMemory.contains(index)) {
        botMemory.add(index);
        if (difficulty == BotDifficulty.easy && botMemory.length > 4) botMemory.removeAt(0); 
        else if (difficulty == BotDifficulty.medium && botMemory.length > 6) botMemory.removeAt(0);
      }
    });
  }

  void _checkMatchLogic() async {
    isBusy = true;
    int first = flippedIndexes[0];
    int second = flippedIndexes[1];

    if (cards[first].value == cards[second].value && cards[first].color == cards[second].color) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() {
        if (isPlayerTurn) playerScore++; else opponentScore++;
        flippedIndexes = [];
        isBusy = false;
      });
      _checkWin();
      if (widget.isBotMode && !isPlayerTurn && (playerScore + opponentScore < 16)) _playBotTurn(); 
    } else {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        cards[first].isRevealed = false;
        cards[second].isRevealed = false;
        flippedIndexes = [];
        isPlayerTurn = !isPlayerTurn; 
        isBusy = false;
      });
      if (widget.isBotMode && !isPlayerTurn) _playBotTurn(); 
    }
  }

  void _playBotTurn() async {
    if (isPlayerTurn || (playerScore + opponentScore == 16)) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    int? pick1, pick2;
    double memoryChance = difficulty == BotDifficulty.hard ? 1.0 : (difficulty == BotDifficulty.medium ? 0.25 : 0.10);

    if (Random().nextDouble() < memoryChance) {
      for (int i = 0; i < botMemory.length; i++) {
        for (int j = i + 1; j < botMemory.length; j++) {
          int idx1 = botMemory[i];
          int idx2 = botMemory[j];
          if (!cards[idx1].isRevealed && !cards[idx2].isRevealed &&
              cards[idx1].value == cards[idx2].value && cards[idx1].color == cards[idx2].color) {
            pick1 = idx1; pick2 = idx2; break;
          }
        }
        if (pick1 != null) break;
      }
    }

    if (pick1 == null) {
      List<int> available = [for (var i = 0; i < cards.length; i++) if (!cards[i].isRevealed) i];
      if (available.isEmpty) return;
      pick1 = available[Random().nextInt(available.length)];
      if (Random().nextDouble() < memoryChance) {
        for (int known in botMemory) {
          if (known != pick1 && !cards[known].isRevealed &&
              cards[known].value == cards[pick1].value && cards[known].color == cards[pick1].color) {
            pick2 = known; break;
          }
        }
      }
      if (pick2 == null) { available.remove(pick1); pick2 = available[Random().nextInt(available.length)]; }
    }

    _revealCard(pick1);
    await Future.delayed(const Duration(milliseconds: 800));
    _revealCard(pick2!);
    _checkMatchLogic();
  }

  // --- OYUN BİTİŞİ VE VERİ GÖNDERİMİ ---
  void _checkWin() async {
    if (playerScore + opponentScore == 16) {
      _stopwatch.stop();
      _timer?.cancel();
      int finalTime = _stopwatch.elapsed.inSeconds;

      // SUNUCUYA REKORU GÖNDERİYORUZ
      if (widget.isBotMode) {
        String diffString = difficulty.toString().split('.').last;
        try {
          debugPrint('[MemoryGame] Sonuç gönderiliyor... type=memory_$diffString, isWin=${playerScore > opponentScore}, duration=$finalTime');
          await ApiService.sendResult(
            nickname: widget.nickname,
            isWin: playerScore > opponentScore,
            duration: finalTime,
            type: "memory_$diffString"
          );
          debugPrint('[MemoryGame] Sonuç başarıyla gönderildi!');
        } catch (e) {
          debugPrint('[MemoryGame] Sonuç gönderilemedi, kuyruğa ekleniyor: $e');
          await SyncQueueService.enqueue({
            "nickname": widget.nickname,
            "isWin": playerScore > opponentScore,
            "duration": finalTime,
            "type": "memory_$diffString"
          });
        }
      }

      String winnerText = playerScore > opponentScore ? "TEBRİKLER, KAZANDIN!" : (opponentScore > playerScore ? "BOT KAZANDI!" : "BERABERE!");
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.brown.shade900,
          title: Text(winnerText, style: const TextStyle(color: Colors.amber)),
          content: Text("Süre: $finalTime Saniye\nSkor: $playerScore - $opponentScore", style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(onPressed: () { Navigator.pop(ctx); setState(() => gameStarted = false); }, child: const Text("TEKRAR", style: TextStyle(color: Colors.amber))),
            TextButton(onPressed: () { Navigator.pop(ctx); widget.onExit(); }, child: const Text("MENÜ", style: TextStyle(color: Colors.white))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text("Hafıza Oyunu"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onExit),
        actions: [
          if (gameStarted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Center(child: Text("${_stopwatch.elapsed.inSeconds} sn", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18))),
            ),
        ],
      ),
      body: gameStarted ? _buildGameGrid() : _buildDifficultySelection(),
    );
  }

  Widget _buildDifficultySelection() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Text("BOT ZORLUĞUNU SEÇİN", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 30),
      _diffBtn("KOLAY", BotDifficulty.easy, Colors.green),
      _diffBtn("ORTA", BotDifficulty.medium, Colors.orange),
      _diffBtn("ZOR", BotDifficulty.hard, Colors.red),
    ]));
  }

  Widget _diffBtn(String label, BotDifficulty diff, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: color, fixedSize: const Size(250, 50)), onPressed: () => _setupGame(diff), child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))));
  }

  Widget _buildGameGrid() {
    String p1Name = widget.isBotMode ? "SİZ" : "1. OYUNCU";
    String p2Name = widget.isBotMode ? "BOT" : "2. OYUNCU";

    return Column(children: [
      Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30), color: Colors.black.withOpacity(0.6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("$p1Name: $playerScore", style: TextStyle(color: Colors.green.shade400, fontSize: 18, fontWeight: FontWeight.bold)), Text("$p2Name: $opponentScore", style: TextStyle(color: Colors.red.shade400, fontSize: 18, fontWeight: FontWeight.bold))])),
      Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0), child: Column(children: List.generate(8, (rowIdx) {
        return Expanded(child: Row(children: List.generate(4, (colIdx) {
          int index = rowIdx * 4 + colIdx;
          return Expanded(child: GestureDetector(onTap: () => _onCardTap(index), child: Container(margin: const EdgeInsets.all(2.5), child: FittedBox(fit: BoxFit.contain, child: StoneFlipWrapper(key: ValueKey(cards[index].id), stone: cards[index])))));
        })));
      })))),
    ]);
  }
}