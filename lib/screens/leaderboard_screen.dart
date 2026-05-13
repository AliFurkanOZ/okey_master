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

class _RankList extends StatefulWidget {
  final String category;
  const _RankList({required this.category});

  @override
  State<_RankList> createState() => _RankListState();
}

class _RankListState extends State<_RankList> {
  late Future<List<dynamic>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _leaderboardFuture = ApiService.getLeaderboard(widget.category);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _loadData();
    });
    await _leaderboardFuture;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      child: FutureBuilder<List<dynamic>>(
        future: _leaderboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Veriler yüklenemedi.", style: TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _handleRefresh, 
                    child: const Text("Tekrar Dene")
                  )
                ]
              )
            );
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                const Center(child: Text("Henüz sıralama yok.", style: TextStyle(color: Colors.white70))),
              ]
            );
          }
          
          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final entry = list[index];
              final double score = (entry['score'] ?? 0).toDouble();
              
              return ListTile(
                leading: CircleAvatar(child: Text("${index + 1}")),
                title: Text(entry['nickname'] ?? "İsimsiz", style: const TextStyle(color: Colors.white)),
                trailing: Text(
                  widget.category == "duel" ? "$score Puan" : "${(score).toStringAsFixed(1)} sn",
                  style: const TextStyle(color: Colors.amber),
                ),
              );
            },
          );
        },
      ),
    );
  }
}