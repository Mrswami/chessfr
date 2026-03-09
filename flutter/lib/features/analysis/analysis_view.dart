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
    bool isConnectivityImprovement = spot.connectivityDelta >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
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
              padding: const EdgeInsets.all(24),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Move Indicator
                    Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Text(
                            '${spot.moveIndex ~/ 2 + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        const Expanded(child: VerticalDivider(color: Colors.white10, width: 2, endIndent: 5, indent: 5)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Detail Section
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                "CRITICAL MISSED MOMENT",
                                style: TextStyle(
                                  color: Colors.redAccent.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 2,
                                ),
                              ),
                              const Spacer(),
                              _buildMetricBadge(
                                isConnectivityImprovement ? "CONNECTED" : "FRAGMENTED",
                                isConnectivityImprovement ? Colors.cyanAccent : Colors.orangeAccent,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You played ${spot.movePlayedSan}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildInlineStat("Engine Loss", "${(spot.swing / 100).toStringAsFixed(1)}p", Colors.redAccent),
                              const SizedBox(width: 16),
                              _buildInlineStat("Connectivity", "${spot.connectivityDelta > 0 ? "+" : ""}${spot.connectivityDelta}", isConnectivityImprovement ? Colors.cyanAccent : Colors.orangeAccent),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.1);
  }

  Widget _buildMetricBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildInlineStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 8,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
