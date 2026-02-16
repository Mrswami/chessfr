import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/chess_com_service.dart';
import 'analysis_view.dart';

class ImportView extends StatefulWidget {
  const ImportView({super.key});

  @override
  State<ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<ImportView> {
  final _usernameController = TextEditingController();
  final _pgnController = TextEditingController();
  final _chessComService = ChessComService();
  
  List<ChessComGame> _recentGames = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchGames() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final games = await _chessComService.getRecentGames(username);
      setState(() {
        _recentGames = games;
      });
    } catch (e) {
      setState(() => _error = 'Failed to fetch games.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _analyzePgn(String pgn, {String? userSide}) {
    if (pgn.isEmpty) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AnalysisView(pgn: pgn, userSide: userSide),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Game')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PGN Input Section
            Text(
              'Paste PGN',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pgnController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '[Event "Live Chess"]...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _analyzePgn(_pgnController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Analyze PGN'),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Chess.com Import Section
            Text(
              'Chess.com Recent Games',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      hintText: 'Username (e.g. Hikaru)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _isLoading ? null : _fetchGames,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20, 
                          height: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),

            const SizedBox(height: 16),
            
            if (_recentGames.isNotEmpty) ...[
              Text(
                'Select a game to analyze:',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _recentGames.length,
                itemBuilder: (context, index) {
                  final game = _recentGames[index];
                  final isWin = game.result == '1-0' && game.whiteUsername.toLowerCase() == _usernameController.text.toLowerCase() ||
                                game.result == '0-1' && game.blackUsername.toLowerCase() == _usernameController.text.toLowerCase();
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('${game.whiteUsername} vs ${game.blackUsername}'),
                      subtitle: Text('${game.timeControl} • ${game.date.toString().split(' ')[0]}'),
                      trailing: Chip(
                        label: Text(game.whiteUsername.toLowerCase() == _usernameController.text.toLowerCase() 
                            ? (game.result == '1-0' ? 'Won' : (game.result == '0-1' ? 'Lost' : 'Draw'))
                            : (game.result == '0-1' ? 'Won' : (game.result == '1-0' ? 'Lost' : 'Draw'))
                        ),
                        backgroundColor: isWin ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                      ),
                      onTap: () => _analyzePgn(game.pgn, userSide: game.whiteUsername.toLowerCase() == _usernameController.text.toLowerCase() ? 'w' : 'b'),
                    ),
                  ).animate().fadeIn(delay: (50 * index).ms).slideX();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
