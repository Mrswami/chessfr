import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart' hide Color;
import '../logic/move_ranker.dart';
import '../logic/stockfish_service.dart';
import '../logic/opening_service.dart';
import '../logic/ml_service_client.dart';
import '../logic/design_metrics.dart';
import 'training_repository.dart';

class TrainingScreen extends StatefulWidget {
  final String? initialFen;
  
  const TrainingScreen({
    super.key,
    this.initialFen,
  });

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final StockfishService _stockfish = StockfishService();
  final OpeningService _openingService = OpeningService();
  final MLServiceClient _mlServiceClient = MLServiceClient();
  final MoveRanker _ranker = MoveRanker();
  final TrainingRepository _repo = TrainingRepository();

  List<RankedMove> _rankedMoves = [];
  OpeningStats? _openingStats;
  bool _isLoading = true;
  bool _isLoadingNextPuzzle = false;
  String? _feedback;
  bool _feedbackIsPositive = true;
  DateTime? _positionShownAt;
  
  Map<String, dynamic>? _userProfile;
  String? _profileId;
  String? _positionId;
  late String _currentFen;

  // Archetype & visual highlights state
  String _selectedArchetype = 'London Squeezer';
  final Map<int, Color> _squareHighlights = {};

  @override
  void initState() {
    super.initState();
    _currentFen = widget.initialFen ?? 
        'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4';
        
    _controller.loadFen(_currentFen);
    _resolveIdsAndAnalyze();
  }

  int _squareToIdx(String sq) {
    if (sq.length != 2) return -1;
    final file = sq.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = sq.codeUnitAt(1) - '1'.codeUnitAt(0);
    if (file < 0 || file > 7 || rank < 0 || rank > 7) return -1;
    return rank * 8 + file;
  }

  Future<void> _resolveIdsAndAnalyze() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    _squareHighlights.clear();
    
    // Fetch profile and position in parallel
    final profileFuture = _repo.getProfile();
    final positionIdFuture = _repo.getOrCreatePositionId(_currentFen);
    
    final metaResults = await Future.wait([profileFuture, positionIdFuture]);
    _userProfile = metaResults[0] as Map<String, dynamic>?;
    _profileId = _userProfile?['id'];
    _positionId = metaResults[1] as String?;

    final bool isDankFish = _userProfile?['engine_mode'] == 'dankfish';

    // 1. If DankFish Mode is active, fetch predictions from our Dockerized ML Service
    if (isDankFish) {
      try {
        final mlResponse = await _mlServiceClient.predictHumanMove(
          fen: _controller.getFen(),
          elo: 1200,
          archetype: _selectedArchetype,
        );

        // Map ML predictions to RankedMoves
        final List<RankedMove> ranked = [];
        for (var i = 0; i < mlResponse.topMoves.length; i++) {
          final pred = mlResponse.topMoves[i];
          
          // Generate square highlights
          if (pred.uci.length >= 2) {
            final dest = pred.uci.substring(pred.uci.length - 2);
            final idx = _squareToIdx(dest);
            if (idx != -1) {
              Color? col;
              if (pred.visuals.color == 'emerald') {
                col = const Color(0xFF10B981).withOpacity(0.5); // Emerald Move Likelihood
              } else if (pred.visuals.color == 'amber') {
                col = const Color(0xFFF59E0B).withOpacity(0.5); // Amber Trap Warning
              } else if (pred.visuals.color == 'crimson') {
                col = const Color(0xFFEF4444).withOpacity(0.6); // Crimson Attention Tunnel
              } else {
                col = const Color(0xFF3B82F6).withOpacity(0.4); // Sapphire Connection
              }

              if (!_squareHighlights.containsKey(idx)) {
                _squareHighlights[idx] = col;
              }
            }
          }

          ranked.add(
            RankedMove(
              moveSan: pred.san,
              finalScore: pred.probability * 10,
              engineEval: (pred.visuals.blunderRisk * -100).toInt(),
              designMetrics: DesignMetrics(
                isBridge: pred.visuals.cognitiveTunnel,
                islandCount: 3,
                connectivityGain: pred.probability,
                responseGain: pred.probability,
                influenceGain: pred.probability,
              ),
              explanation: pred.insights,
            ),
          );
        }

        // Fetch opening stats in parallel to complete loading
        final openingStats = await _openingService.getOpeningStats(_controller.getFen());

        if (mounted) {
          setState(() {
            _rankedMoves = ranked;
            _openingStats = openingStats;
            _isLoading = false;
            _positionShownAt = DateTime.now();
          });
        }
        return;
      } catch (e) {
        debugPrint('ML predictions failed, falling back to standard Stockfish: $e');
      }
    }

    // 2. Fallback to standard client-side Stockfish + MoveRanker (if Stockfish Mode or ML API error)
    final engineMovesFuture = _stockfish.getTopMoves(_controller.getFen());
    final openingStatsFuture = _openingService.getOpeningStats(_controller.getFen());

    final results = await Future.wait([engineMovesFuture, openingStatsFuture]);
    final engineMoves = results[0] as List<EngineMove>;
    final openingStats = results[1] as OpeningStats?;

    final ranked = _ranker.rankMoves(
      _controller.getFen(), 
      engineMoves, 
      _userProfile ?? {
        'connectivity_weight': 0.5,
        'engine_trust': 0.5,
        'engine_mode': 'stockfish',
      }
    );

    if (mounted) {
      setState(() {
        _rankedMoves = ranked;
        _openingStats = openingStats;
        _isLoading = false;
        _positionShownAt = DateTime.now();
      });
    }
  }

  void _onMove(String moveSan) {
    if (_rankedMoves.isEmpty) return;
    
    final bestMove = _rankedMoves.first;
    int rank = -1;
    for (var i = 0; i < _rankedMoves.length; i++) {
      if (_rankedMoves[i].moveSan == moveSan) {
        rank = i + 1;
        break;
      }
    }

    final isCorrect = moveSan == bestMove.moveSan;
    final isRecommended = rank >= 1 && rank <= 3;
    String outcome = 'incorrect';
    int auraEarned = 0;
    
    if (isCorrect) {
      outcome = 'correct';
      auraEarned = 10;
    } else if (isRecommended) {
      outcome = 'correct';
      auraEarned = 5;
    }

    setState(() {
      if (isCorrect) {
        _feedback = "Excellent! That's the recommended choice. +$auraEarned Aura";
        _feedbackIsPositive = true;
      } else if (isRecommended) {
        _feedback = "Good choice. ${_rankedMoves[rank - 1].explanation} +$auraEarned Aura";
        _feedbackIsPositive = true;
      } else {
        _feedback = "Not quite. Check your piece connectivity!";
        _feedbackIsPositive = false;
      }
    });

    if (_profileId != null && _positionId != null) {
      final latencyMs = _positionShownAt != null
          ? DateTime.now().difference(_positionShownAt!).inMilliseconds
          : null;
      _repo.recordSession(
        profileId: _profileId!,
        positionId: _positionId!,
        chosenMove: moveSan,
        responseLatencyMs: latencyMs,
        outcome: outcome,
        auraEarned: auraEarned,
      );
    }
  }

  Future<void> _loadNextPuzzle() async {
    setState(() {
      _isLoadingNextPuzzle = true;
      _feedback = null;
      _squareHighlights.clear();
    });

    final nextFen = await _repo.getRandomPositionFen();
    if (nextFen != null) {
      _currentFen = nextFen;
      _controller.loadFen(_currentFen);
      await _resolveIdsAndAnalyze();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load next puzzle. Try again!')),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isLoadingNextPuzzle = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDankFish = _userProfile?['engine_mode'] == 'dankfish';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isDankFish ? '🎅 DankFish Training' : 'Pattern Training'),
        actions: [
          if (isDankFish)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent),
                  ),
                  child: const Text(
                    'PERSONALIZED',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ChessBoard(
                    controller: _controller,
                    boardColor: BoardColor.brown,
                    boardOrientation: PlayerColor.white,
                    onMove: () {
                      final history = _controller.getSan();
                      if (history.isNotEmpty) _onMove(history.last!);
                    },
                  ),
                  // Visual overlays mapping to DankFish predictions
                  if (isDankFish && _squareHighlights.isNotEmpty)
                    IgnorePointer(
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 8,
                          ),
                          itemCount: 64,
                          itemBuilder: (context, index) {
                            // Map GridView visual index (0 is top-left, 63 is bottom-right)
                            // to python-chess square index (0 is bottom-left, 63 is top-right)
                            final pythonChessSquare = (7 - (index ~/ 8)) * 8 + (index % 8);
                            final color = _squareHighlights[pythonChessSquare];
                            if (color != null) {
                              return Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: color.withOpacity(0.8),
                                    width: 1.5,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_feedback != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _feedbackIsPositive
                            ? (isDankFish ? Colors.red.shade900.withValues(alpha: 0.3) : const Color(0xFF0D9488).withValues(alpha: 0.25))
                            : const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _feedbackIsPositive
                              ? (isDankFish ? Colors.red : const Color(0xFF0D9488).withValues(alpha: 0.5))
                              : const Color(0xFFF59E0B).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _feedbackIsPositive
                                ? (isDankFish ? Icons.celebration : Icons.thumb_up_rounded)
                                : Icons.lightbulb_outline_rounded,
                            color: _feedbackIsPositive
                                ? (isDankFish ? Colors.redAccent : const Color(0xFF14B8A6))
                                : const Color(0xFFF59E0B),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _feedback!,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0),
                    
                    // Next Puzzle Button Loop
                    ElevatedButton.icon(
                      onPressed: _isLoadingNextPuzzle ? null : _loadNextPuzzle,
                      icon: _isLoadingNextPuzzle
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Next Puzzle', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDankFish ? Colors.red.shade800 : const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                  ],
                  
                  if (_openingStats != null && _openingStats!.name != 'Unknown Position')
                    _buildOpeningCard(context),

                  // Archetype Select Dropdown (Active in DankFish Mode)
                  if (isDankFish) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Opponent Profile:',
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                          value: _selectedArchetype,
                          dropdownColor: const Color(0xFF1E293B),
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          underline: Container(height: 1, color: Colors.redAccent),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedArchetype = newValue;
                              });
                              _resolveIdsAndAnalyze();
                            }
                          },
                          items: <String>[
                            'London Squeezer',
                            'Wayward Queen Raider',
                            'Fried Liver Fanatic',
                            'French/Caro Squeezer',
                            'Gambiteer',
                            'Symmetrical Copier'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isDankFish ? '🎅 Dank Recommendations' : 'Recommended moves',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                      if (isDankFish)
                        const Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rankedMoves.length,
                        itemBuilder: (context, index) {
                          final move = _rankedMoves[index];
                          return _buildMoveTile(context, index, move, isDankFish);
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

  Widget _buildOpeningCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_openingStats!.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (_openingStats!.eco.isNotEmpty) Text('ECO: ${_openingStats!.eco}', style: const TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.public, size: 14, color: Colors.white54),
                const SizedBox(width: 4),
                Text('${_openingStats!.totalGames}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildMoveTile(BuildContext context, int index, RankedMove move, bool isDankFish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: isDankFish && index == 0 ? Border.all(color: Colors.amber.withValues(alpha: 0.5)) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: (isDankFish && index == 0 ? Colors.amber : Colors.teal).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('${index + 1}', style: TextStyle(fontWeight: FontWeight.w700, color: isDankFish && index == 0 ? Colors.amber : Colors.teal)),
        ),
        title: Text(move.moveSan, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(move.explanation, style: const TextStyle(fontSize: 13, color: Colors.white70)),
        ),
        trailing: isDankFish && index == 0 
          ? const Icon(Icons.star, color: Colors.amber, size: 18)
          : Text(move.finalScore.toStringAsFixed(1), style: const TextStyle(fontSize: 13, color: Colors.white54, fontWeight: FontWeight.w500)),
      ),
    ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.08, end: 0);
  }
}
