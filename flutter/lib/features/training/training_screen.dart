import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../logic/design_metrics.dart';
import '../logic/move_ranker.dart';
import '../logic/stockfish_service.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final StockfishService _stockfish = StockfishService();
  final MoveRanker _ranker = MoveRanker();
  
  List<RankedMove> _rankedMoves = [];
  bool _isLoading = true;
  String? _feedback;
  
  // Sample starting position (Italian Game)
  final String _startFen = 'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4';

  @override
  void initState() {
    super.initState();
    _controller.loadFen(_startFen);
    _analyzePosition();
  }

  Future<void> _analyzePosition() async {
    setState(() => _isLoading = true);
    
    // 1. Get engine moves
    final engineMoves = await _stockfish.getTopMoves(_controller.getFen());
    
    // 2. Rank them based on profile (mock profile for now)
    final profile = {
      'connectivity_weight': 0.8, // High preference for connectivity
      'engine_trust': 0.2,
    };
    
    final ranked = _ranker.rankMoves(_controller.getFen(), engineMoves, profile);
    
    if (mounted) {
      setState(() {
        _rankedMoves = ranked;
        _isLoading = false;
      });
    }
  }

  void _onMove(String moveSan) {
    // Check if move matches our top recommendations
    // Note: flutter_chess_board handles the move logic on the UI, 
    // we just need to validate if it was a "good" move per our ranker.
    
    final bestMove = _rankedMoves.first;
    
    setState(() {
      if (moveSan == bestMove.moveSan) {
        _feedback = "Excellent! That's the most connected move.";
      } else {
        // Find if it was in the top 3
        final match = _rankedMoves.firstWhere(
            (m) => m.moveSan == moveSan, 
            orElse: () => RankedMove(moveSan: '', finalScore: 0, engineEval: 0, designMetrics: DesignMetrics(isBridge: false, islandCount: 0, connectivityGain: 0), explanation: '')
        );
        
        if (match.moveSan.isNotEmpty) {
           _feedback = "Good choice. ${match.explanation}";
        } else {
           _feedback = "Interesting, but check your piece connectivity.";
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Training'),
      ),
      body: Column(
        children: [
          // Chess Board
          Expanded(
            flex: 3,
            child: Center(
              child: ChessBoard(
                controller: _controller,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
                onMove: () {
                  // We need to capture the move SAN. 
                  // The controller tracks history.
                  final history = _controller.getSan();
                  if (history.isNotEmpty) {
                     _onMove(history.last!);
                  }
                },
              ),
            ),
          ),
          
          // Analysis & Feedback
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_feedback != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn().slideY(begin: 0.5, end: 0, duration: 400.ms),
                    
                  Text(
                    'Recommended Moves',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rankedMoves.length,
                        itemBuilder: (context, index) {
                          final move = _rankedMoves[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(move.moveSan, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(move.explanation),
                              trailing: Text('Score: ${move.finalScore.toStringAsFixed(1)}'),
                            ),
                          ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
