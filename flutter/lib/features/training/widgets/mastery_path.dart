import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class MasteryPath extends StatelessWidget {
  final int totalXp;
  final int currentLevel;

  const MasteryPath({
    super.key,
    required this.totalXp,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    const double nodeSpacing = 160.0;
    const int totalNodes = 20; // For now, let's show 20 nodes

    return SingleChildScrollView(
      reverse: true, // Start from the bottom? Or top? Usually bottom-to-top like Mario.
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 100),
        width: double.infinity,
        child: CustomPaint(
          size: Size(double.infinity, totalNodes * nodeSpacing),
          painter: PathPainter(
            nodeSpacing: nodeSpacing,
            totalNodes: totalNodes,
            currentLevel: currentLevel,
          ),
          child: _buildNodes(context, totalNodes, nodeSpacing),
        ),
      ),
    );
  }

  Widget _buildNodes(BuildContext context, int totalNodes, double nodeSpacing) {
    return Stack(
      children: List.generate(totalNodes, (index) {
        final double y = (totalNodes - 1 - index) * nodeSpacing;
        final double xOffset = math.sin(index * 0.8) * 60; // Winding effect
        
        final bool isUnlocked = index <= currentLevel;
        final bool isCurrent = index == currentLevel;

        return Positioned(
          left: (MediaQuery.of(context).size.width / 2) + xOffset - 30,
          top: y,
          child: _MasteryNode(
            level: index + 1,
            isUnlocked: isUnlocked,
            isCurrent: isCurrent,
          ),
        );
      }),
    );
  }
}

class PathPainter extends CustomPainter {
  final double nodeSpacing;
  final int totalNodes;
  final int currentLevel;

  PathPainter({
    required this.nodeSpacing,
    required this.totalNodes,
    required this.currentLevel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final double centerX = size.width / 2;

    for (int i = 0; i < totalNodes; i++) {
        final double y = (totalNodes - 1 - i) * nodeSpacing + 40;
        final double x = centerX + math.sin(i * 0.8) * 60;
        
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          // Quadratic bezier for smooth curves

                    final prevY = (totalNodes - 1 - (i - 1)) * nodeSpacing + 40;
          final controlX = centerX + math.sin((i - 0.5) * 0.8) * 60;
          final controlY = (prevY + y) / 2;
          
          path.quadraticBezierTo(controlX, controlY, x, y);
        }
    }

    // Draw background path (unlocked)
    paint.color = Colors.white10;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _MasteryNode extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCurrent;

  const _MasteryNode({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCurrent 
                ? Colors.cyanAccent 
                : (isUnlocked ? Colors.cyan.shade900 : const Color(0xFF1E1E1E)),
            boxShadow: isCurrent ? [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              )
            ] : null,
            border: Border.all(
              color: isUnlocked ? Colors.cyanAccent.withValues(alpha: 0.5) : Colors.white12,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            isUnlocked ? (isCurrent ? Icons.play_arrow_rounded : Icons.check_rounded) : Icons.lock_outline_rounded,
            color: isCurrent ? Colors.black : (isUnlocked ? Colors.cyanAccent : Colors.white24),
            size: 28,
          ),
        ).animate(onPlay: (c) => isCurrent ? c.repeat(reverse: true) : null)
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 8),
        Text(
          'LEVEL $level',
          style: TextStyle(
            color: isUnlocked ? Colors.white : Colors.white24,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
