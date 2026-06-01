import 'package:flutter/material.dart';

enum TabiyaState { Actual, Theoretical, Mutated }

class TabiyaVisualizerBoard extends StatelessWidget {
  final TabiyaState currentState;
  final String openingName;
  final Function(TabiyaState) onStateChanged;

  const TabiyaVisualizerBoard({
    Key? key,
    required this.currentState,
    required this.openingName,
    required this.onStateChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "$openingName Tabiya Analysis",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _TabiyaBoardPainter(state: currentState),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStateToggle("Actual", TabiyaState.Actual),
              SizedBox(width: 8),
              _buildStateToggle("Theory", TabiyaState.Theoretical),
              SizedBox(width: 8),
              _buildStateToggle("Mutated", TabiyaState.Mutated),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateToggle(String label, TabiyaState state) {
    final isSelected = currentState == state;
    return GestureDetector(
      onTap: () => onStateChanged(state),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.purpleAccent.withOpacity(0.3) : Colors.black45,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.white24,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TabiyaBoardPainter extends CustomPainter {
  final TabiyaState state;

  _TabiyaBoardPainter({required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;

    // Draw Board Grid
    final gridPaint = Paint()
      ..color = Colors.white10
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 8; i++) {
      canvas.drawLine(Offset(0, i * squareSize), Offset(size.width, i * squareSize), gridPaint);
      canvas.drawLine(Offset(i * squareSize, 0), Offset(i * squareSize, size.height), gridPaint);
    }

    // Colors depend on state
    Color nodeColor;
    if (state == TabiyaState.Actual) nodeColor = Colors.cyanAccent;
    else if (state == TabiyaState.Theoretical) nodeColor = Colors.orangeAccent;
    else nodeColor = Colors.purpleAccent;

    // Draw generic nodes for demo
    final nodePaint = Paint()
      ..color = nodeColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final nodeGlow = Paint()
      ..color = nodeColor.withOpacity(0.3)
      ..style = PaintingStyle.fill
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    final linePaint = Paint()
      ..color = nodeColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // A predefined layout depending on the state
    List<Offset> nodes;
    if (state == TabiyaState.Actual) {
      nodes = [
        Offset(squareSize * 4.5, squareSize * 4.5),
        Offset(squareSize * 3.5, squareSize * 3.5),
        Offset(squareSize * 5.5, squareSize * 3.5),
      ];
    } else if (state == TabiyaState.Theoretical) {
      nodes = [
        Offset(squareSize * 4.5, squareSize * 3.5),
        Offset(squareSize * 3.5, squareSize * 4.5),
        Offset(squareSize * 5.5, squareSize * 4.5),
      ];
    } else {
      nodes = [
        Offset(squareSize * 6.5, squareSize * 2.5), // The creative mutated node
        Offset(squareSize * 4.5, squareSize * 4.5),
        Offset(squareSize * 3.5, squareSize * 3.5),
      ];
    }

    // Connect nodes
    for (int i = 0; i < nodes.length - 1; i++) {
      canvas.drawLine(nodes[i], nodes[i+1], linePaint);
    }

    // Draw nodes
    for (var node in nodes) {
      canvas.drawCircle(node, squareSize * 0.3, nodeGlow);
      canvas.drawCircle(node, squareSize * 0.2, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
