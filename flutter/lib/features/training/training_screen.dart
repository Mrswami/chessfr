import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import '../logic/design_metrics.dart';
import '../logic/move_ranker.dart';
import '../logic/stockfish_service.dart';
import 'training_repository.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  final ChessBoardController _controller = ChessBoardController();
  final StockfishService _stockfish = StockfishService();
  final MoveRanker _ranker = MoveRanker();
  final TrainingRepository _repo = TrainingRepository();

  List<RankedMove> _rankedMoves = [];
  bool _isLoading = true;
  String? _feedback;
  bool _feedbackIsPositive = true;
  DateTime? _positionShownAt;
  String? _profileId;
  String? _positionId;

  final String _startFen =
      'r1bqkb1r/pppp1ppp/2n2n2/4p3/2B1P3/5N2/PPPP1PPP/RNBQK2R w KQkq - 4 4';

  @override
  void initState() {
    super.initState();
    _controller.loadFen(_startFen);
    _resolveIdsAndAnalyze();
  }

  Future<void> _resolveIdsAndAnalyze() async {
    setState(() => _isLoading = true);
    _profileId = await _repo.getProfileId();
    _positionId = await _repo.getOrCreatePositionId(_startFen);

    final engineMoves = await _stockfish.getTopMoves(_controller.getFen());
    final profile = {
      'connectivity_weight': 0.8,
      'engine_trust': 0.2,
    };
    final ranked =
        _ranker.rankMoves(_controller.getFen(), engineMoves, profile);

    if (mounted) {
      setState(() {
        _rankedMoves = ranked;
        _isLoading = false;
        _positionShownAt = DateTime.now();
      });
    }
  }

  void _onMove(String moveSan) {
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
    int xpEarned = 0;
    if (isCorrect) {
      outcome = 'correct';
      xpEarned = 10;
    } else if (isRecommended) {
      outcome = 'correct';
      xpEarned = 5;
    }

    setState(() {
      if (isCorrect) {
        _feedback = "Excellent! That's the most connected move. +$xpEarned XP";
        _feedbackIsPositive = true;
      } else if (isRecommended) {
        _feedback = "Good choice. ${_rankedMoves[rank - 1].explanation} +$xpEarned XP";
        _feedbackIsPositive = true;
      } else {
        _feedback = "Interesting, but check your piece connectivity.";
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
        xpEarned: xpEarned,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Training'),
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
              child: ChessBoard(
                controller: _controller,
                boardColor: BoardColor.brown,
                boardOrientation: PlayerColor.white,
                onMove: () {
                  final history = _controller.getSan();
                  if (history.isNotEmpty) _onMove(history.last!);
                },
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
                  if (_feedback != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: _feedbackIsPositive
                            ? const Color(0xFF0D9488).withOpacity(0.25)
                            : const Color(0xFFF59E0B).withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _feedbackIsPositive
                              ? const Color(0xFF0D9488).withOpacity(0.5)
                              : const Color(0xFFF59E0B).withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _feedbackIsPositive
                                ? Icons.thumb_up_rounded
                                : Icons.lightbulb_outline_rounded,
                            color: _feedbackIsPositive
                                ? const Color(0xFF14B8A6)
                                : const Color(0xFFF59E0B),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _feedback!,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),
                  Text(
                    'Recommended moves',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: _rankedMoves.length,
                        itemBuilder: (context, index) {
                          final move = _rankedMoves[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF14B8A6),
                                  ),
                                ),
                              ),
                              title: Text(
                                move.moveSan,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  move.explanation,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                              trailing: Text(
                                '${move.finalScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: (80 * index).ms)
                              .slideX(begin: 0.08, end: 0, curve: Curves.easeOut);
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
