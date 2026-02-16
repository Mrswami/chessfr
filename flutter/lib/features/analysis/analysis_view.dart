import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../logic/game_analysis_service.dart';
import '../logic/stockfish_service.dart';
import '../training/training_screen.dart';

class AnalysisView extends StatefulWidget {
  final String pgn;
  final String? userSide; // 'w' or 'b'

  const AnalysisView({
    super.key,
    required this.pgn,
    this.userSide,
  });

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final _stockfish = StockfishService();
  late final _analysisService = GameAnalysisService(_stockfish);
  
  List<SwingSpot> _swingSpots = [];
  bool _isAnalyzing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  @override
  void dispose() {
    _stockfish.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    try {
      final spots = await _analysisService.findSwingSpots(
        widget.pgn, 
        userSide: widget.userSide
      );
      if (mounted) {
        setState(() {
          _swingSpots = spots;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Analysis failed: $e';
          _isAnalyzing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Analysis')),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Searching for critical moments...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const Text(
                    'This may take a minute.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text(_error!))
              : _swingSpots.isEmpty
                  ? Center(
                      child: Text(
                        'No major swing spots found!\nGreat game.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _swingSpots.length,
                      itemBuilder: (context, index) {
                        final spot = _swingSpots[index];
                        return _buildSpotCard(context, spot, index);
                      },
                    ),
    );
  }

  Widget _buildSpotCard(BuildContext context, SwingSpot spot, int index) {
    // We want to show the board briefly or just stats
    // showing board is expensive on resources in a list, 
    // maybe just show move number and swing value for now.
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to training with this FEN
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrainingScreen(
                initialFen: spot.fenBefore,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${spot.moveIndex ~/ 2 + 1}', // Approximate move number
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed Opportunity',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // Format swing: -150 cp -> -1.5
                      'Swing: ${(spot.swing / 100).toStringAsFixed(1)} pts',
                      style: const TextStyle(color: Colors.white70),
                    ),
                     Text(
                      'You played: ${spot.movePlayedSan}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white30),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.1, end: 0);
  }
}
