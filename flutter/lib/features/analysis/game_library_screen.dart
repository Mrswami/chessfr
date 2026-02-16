import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class GameLibraryScreen extends StatelessWidget {
  const GameLibraryScreen({super.key});

  Future<List<Map<String, dynamic>>> _fetchGames() async {
    final client = Supabase.instance.client;
    final response = await client
        .from('live_sessions')
        .select()
        .order('started_at', ascending: false)
        .limit(20);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Game Archive"), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchGames(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white70)));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
          
          final games = snapshot.data!;
          if (games.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white24),
                   SizedBox(height: 16),
                   Text("No games recorded yet.", style: TextStyle(color: Colors.white24)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              final dateStr = game['started_at'] as String? ?? "";
              DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();
              final status = game['status'] ?? "Unknown";
              final pgn = game['pgn'] ?? "No move history recorded.";
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.cyan.withOpacity(0.2) : Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      status == 'active' ? Icons.sensors_active : Icons.history,
                      color: status == 'active' ? Colors.cyanAccent : Colors.white38,
                    ),
                  ),
                  title: Text(
                    "Session ${date.day}/${date.month}/${date.year}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    pgn.length > 50 ? "${pgn.substring(0, 50)}..." : pgn,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("GAME SESSION DETAILS", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            const SizedBox(height: 20),
            const Text("PGN DATA", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: SelectableText(
                game['pgn'] ?? "No PGN data recorded.", 
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12)
              ),
            ),
            const SizedBox(height: 16),
            const Text("LAST BOARD FEN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
              child: SelectableText(
                game['fen'] ?? "Unknown", 
                style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 12)
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                       Clipboard.setData(ClipboardData(text: game['pgn'] ?? ""));
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PGN Copied!")));
                    },
                    label: const Text("COPY PGN"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan.withOpacity(0.2),
                      foregroundColor: Colors.cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                    child: const Text("CLOSE", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
