import 'package:flutter/material.dart';
import 'dart:math' as math;

class MasterMap extends StatelessWidget {
  final int totalXp;
  final int currentLevel;

  const MasterMap({
    super.key,
    required this.totalXp,
    required this.currentLevel,
  });

  @override
  Widget build(BuildContext context) {
    // Map configuration
    const double nodeSpacing = 120.0;
    const int nodesPerWorld = 10;
    const double mapHeight = 400.0;

    return SizedBox(
      height: mapHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5, // 5 Worlds for now
        itemBuilder: (context, worldIndex) {
          return _WorldSection(
            worldIndex: worldIndex,
            currentLevel: currentLevel,
            nodesPerWorld: nodesPerWorld,
            nodeSpacing: nodeSpacing,
            mapHeight: mapHeight,
          );
        },
      ),
    );
  }
}

class _WorldSection extends StatelessWidget {
  final int worldIndex;
  final int currentLevel;
  final int nodesPerWorld;
  final double nodeSpacing;
  final double mapHeight;

  const _WorldSection({
    required this.worldIndex,
    required this.currentLevel,
    required this.nodesPerWorld,
    required this.nodeSpacing,
    required this.mapHeight,
  });

  @override
  Widget build(BuildContext context) {
    final worldName = _getWorldName(worldIndex);
    final worldColor = _getWorldColor(worldIndex);

    return Container(
      width: nodesPerWorld * nodeSpacing + 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [worldColor.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // World Label
          Positioned(
            top: 40,
            left: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WORLD ${worldIndex + 1}',
                  style: TextStyle(color: worldColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                Text(
                  worldName.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: 2),
                ),
              ],
            ),
          ),
          // Winding Path Painter
          CustomPaint(
            size: Size(nodesPerWorld * nodeSpacing, mapHeight),
            painter: _MapPathPainter(
              nodesPerWorld: nodesPerWorld,
              nodeSpacing: nodeSpacing,
              worldColor: worldColor,
            ),
          ),
          // Level Nodes
          ...List.generate(nodesPerWorld, (i) {
            final globalLevel = worldIndex * nodesPerWorld + i;
            final x = i * nodeSpacing + 100.0;
            final y = (mapHeight / 2) + math.sin(i * 0.8) * 60;
            
            return Positioned(
              left: x,
              top: y,
              child: _MapNode(
                level: globalLevel + 1,
                isUnlocked: globalLevel <= currentLevel,
                isCurrent: globalLevel == currentLevel,
                color: worldColor,
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getWorldName(int index) {
    switch (index) {
      case 0: return 'Gotham City';
      case 1: return 'The Levy Labyrinth';
      case 2: return 'Hikaru\'s Peak';
      case 3: return 'Magnus Meadow';
      default: return 'The Unknown Wilds';
    }
  }

  Color _getWorldColor(int index) {
    switch (index) {
      case 0: return Colors.amber;
      case 1: return Colors.purpleAccent;
      case 2: return Colors.redAccent;
      case 3: return Colors.blueAccent;
      default: return Colors.tealAccent;
    }
  }
}

class _MapPathPainter extends CustomPainter {
  final int nodesPerWorld;
  final double nodeSpacing;
  final Color worldColor;

  _MapPathPainter({
    required this.nodesPerWorld,
    required this.nodeSpacing,
    required this.worldColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = worldColor.withValues(alpha: 0.2)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const startX = 100.0;
    const centerY = 200.0; // Assume height is roughly handled by sin

    for (int i = 0; i < nodesPerWorld; i++) {
      final x = startX + i * nodeSpacing;
      final y = centerY + math.sin(i * 0.8) * 60 + 30; // 30 offset for node center

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = startX + (i - 1) * nodeSpacing;
        final prevY = centerY + math.sin((i - 1) * 0.8) * 60 + 30;
        
        final ctrlX = (x + prevX) / 2;
        final ctrlY = (y + prevY) / 2 + (i % 2 == 0 ? 20 : -20);
        
        path.quadraticBezierTo(ctrlX, ctrlY, x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MapNode extends StatelessWidget {
  final int level;
  final bool isUnlocked;
  final bool isCurrent;
  final Color color;

  const _MapNode({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isCurrent ? color : (isUnlocked ? color.withValues(alpha: 0.4) : const Color(0xFF1E1E1E)),
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isUnlocked ? color : Colors.white12, width: 2),
            boxShadow: isCurrent ? [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 15, spreadRadius: 2)
            ] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '$level',
            style: TextStyle(
              color: isCurrent ? Colors.black : (isUnlocked ? Colors.white : Colors.white24),
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
      ],
    );
  }
}
