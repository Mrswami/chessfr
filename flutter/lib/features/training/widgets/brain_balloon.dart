import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class BrainBalloon extends StatelessWidget {
  final int aura;
  final double size;
  final String? label;
  final String? avatarUrl;
  final bool isUser;

  const BrainBalloon({
    super.key,
    required this.aura,
    this.size = 60,
    this.label,
    this.avatarUrl,
    this.isUser = true,
  });

  @override
  Widget build(BuildContext context) {
    // Scaling logic: head grows as score increases
    // Base size + growth proportional to log of score to avoid infinite growth
    final double growthFactor = math.log(math.max(aura, 1) / 100 + 1) * 20;
    final double totalSize = size + growthFactor;
    
    // Wrinkle count: 1 wrinkle per 100 Aura, max 10 for performance/style
    // The wrinkle count is calculated directly in _BrainPainter, so this variable is unused.

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isUser ? Colors.cyanAccent.withValues(alpha: 0.3) : Colors.white24),
            ),
            child: Text(
              label!,
              style: TextStyle(
                color: isUser ? Colors.cyanAccent : Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn().slideY(begin: 0.5, end: 0),
        const SizedBox(height: 8),
        SizedBox(
          width: totalSize,
          height: totalSize,
          child: Stack(
            children: [
              if (avatarUrl != null)
                Positioned.fill(
                  child: ClipOval(
                    child: Transform.scale(
                      scale: 1.3, // Comical caricature enlargement
                      child: Image.network(
                        avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultBrain(totalSize),
                      ),
                    ),
                  ),
                )
              else
                _buildDefaultBrain(totalSize),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat(reverse: true))
         .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
         .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.5.seconds, curve: Curves.easeInOut),
      ],
    );
  }

  Widget _buildDefaultBrain(double totalSize) {
    return CustomPaint(
      size: Size(totalSize, totalSize),
      painter: _BrainPainter(
        color: isUser ? Colors.cyanAccent : Colors.white,
        wrinkleCount: (aura / 500).floor().clamp(0, 12),
        isUser: isUser,
      ),
    );
  }
}

class _BrainPainter extends CustomPainter {
  final Color color;
  final int wrinkleCount;
  final bool isUser;

  _BrainPainter({
    required this.color,
    required this.wrinkleCount,
    required this.isUser,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.2;

    final paint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    // Draw main brain body (two lobes)
    canvas.drawCircle(center.translate(-radius * 0.2, 0), radius, paint);
    canvas.drawCircle(center.translate(radius * 0.2, 0), radius, paint);

    // Glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Outline
    final outlinePaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    // Draw lobby outline
    final path = Path()
      ..addOval(Rect.fromCircle(center: center.translate(-radius * 0.2, 0), radius: radius))
      ..addOval(Rect.fromCircle(center: center.translate(radius * 0.2, 0), radius: radius));
    canvas.drawPath(path, outlinePaint);

    // Draw wrinkles
    final wrinklePaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final random = math.Random(42); // Seeded for consistency
    for (int i = 0; i < wrinkleCount; i++) {
      final angle = random.nextDouble() * math.pi * 2;
      final dist = random.nextDouble() * radius * 0.7;
      final start = center.translate(math.cos(angle) * dist, math.sin(angle) * dist);
      
      final wrinklePath = Path();
      wrinklePath.moveTo(start.dx, start.dy);
      
      // Squiggly wrinkle
      for (int j = 0; j < 3; j++) {
        final nextAngle = angle + (random.nextDouble() - 0.5) * 1.5;
        final nextDist = dist + (random.nextDouble() * 15);
        final end = center.translate(math.cos(nextAngle) * nextDist, math.sin(nextAngle) * nextDist);
        
        final ctrlX = (start.dx + end.dx) / 2 + (random.nextDouble() - 0.5) * 10;
        final ctrlY = (start.dy + end.dy) / 2 + (random.nextDouble() - 0.5) * 10;
        
        wrinklePath.quadraticBezierTo(ctrlX, ctrlY, end.dx, end.dy);
      }
      canvas.drawPath(wrinklePath, wrinklePaint);
    }
    
    // Eyes (simple vertical slits for "soul-less" or "zen" look)
    final eyePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(center.dx - radius*0.4, center.dy - 5, 2, 10), eyePaint);
    canvas.drawRect(Rect.fromLTWH(center.dx + radius*0.4 - 2, center.dy - 5, 2, 10), eyePaint);
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) => 
      oldDelegate.wrinkleCount != wrinkleCount || oldDelegate.color != color;
}
