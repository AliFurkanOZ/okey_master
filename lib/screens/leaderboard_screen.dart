import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatelessWidget {
  final VoidCallback onExit;
  const LeaderboardScreen({required this.onExit, super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("LİDERLİK TABLOLARI"),
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: onExit),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: "DÜELLO"),
              Tab(text: "HAFIZA (KOLAY)"),
              Tab(text: "HAFIZA (ORTA)"),
              Tab(text: "HAFIZA (ZOR)"),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
          child: const TabBarView(
            children: [
              _RankList(category: "duel"),
              _RankList(category: "memory_easy"),
              _RankList(category: "memory_medium"),
              _RankList(category: "memory_hard"),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  final String category;
  const _RankList({required this.category});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: ApiService.getLeaderboard(category),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final list = snapshot.data!;
        
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final entry = list[index];
            // NULL KONTROLÜ: Eğer score null ise 0 kabul et
            final double score = (entry['score'] ?? 0).toDouble();
            
            return ListTile(
              leading: CircleAvatar(child: Text("${index + 1}")),
              title: Text(entry['nickname'] ?? "İsimsiz", style: const TextStyle(color: Colors.white)),
              trailing: Text(
                category == "duel" ? "$score Puan" : "${(score).toStringAsFixed(1)} sn",
                style: const TextStyle(color: Colors.amber),
              ),
            );
          },
        );
      },
    );
  }
}