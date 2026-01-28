import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class GameLibraryScreen extends StatelessWidget {
  const GameLibraryScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchGames() async {
     final snap = await FirebaseFirestore.instance
          .collection('games')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cloud Library"), 
        backgroundColor: const Color(0xFF6C22F5), 
        foregroundColor: Colors.white
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final games = snapshot.data!;
          if (games.isEmpty) return const Center(child: Text("No games found in Cloud DB."));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final dateStr = game['date'] as String? ?? "";
              DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();
              final result = game['result'] ?? "?";
              final pgn = game['pgn'] ?? "";
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: result == "1-0" ? Colors.white : (result == "0-1" ? Colors.black : Colors.grey),
                    radius: 24,
                    child: Text(
                      result,
                      style: TextStyle(
                        color: result == "0-1" ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 10
                      ),
                    ),
                  ),
                  title: Text(
                    "Game ${index + 1}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${date.year}-${date.month}-${date.day} ${date.hour}:${date.minute.toString().padLeft(2,'0')}"),
                      const SizedBox(height: 4),
                      Text(
                        pgn.length > 50 ? "${pgn.substring(0, 50)}..." : pgn,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700], fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showGameDetails(context, game),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showGameDetails(BuildContext context, Map<String, dynamic> game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Game Details"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("PGN (Portable Game Notation):", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 4, bottom: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: SelectableText(
                  game['pgn'] ?? "No PGN", 
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)
                ),
              ),
              const Text("Final FEN:", style: TextStyle(fontWeight: FontWeight.bold)),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: SelectableText(
                  game['fen'] ?? "?", 
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11)
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy),
            onPressed: () {
               Clipboard.setData(ClipboardData(text: game['pgn'] ?? ""));
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PGN Copied to Clipboard!")));
            },
            label: const Text("COPY PGN"),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CLOSE")),
        ],
      ),
    );
  }
}
