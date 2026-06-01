import 'dart:math';
import 'package:flutter/material.dart';

class PsychosisGears extends StatefulWidget {
  final bool isAnalyzing;

  const PsychosisGears({Key? key, this.isAnalyzing = true}) : super(key: key);

  @override
  State<PsychosisGears> createState() => _PsychosisGearsState();
}

class _PsychosisGearsState extends State<PsychosisGears> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    if (widget.isAnalyzing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PsychosisGears oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnalyzing && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnalyzing && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GearPainter(rotation: _controller.value * 2 * pi),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  final double rotation;

  _GearPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center1 = Offset(size.width * 0.35, size.height * 0.5);
    final radius1 = size.height * 0.35;
    
    final center2 = Offset(size.width * 0.65, size.height * 0.5);
    final radius2 = size.height * 0.25;

    _drawGear(canvas, center1, radius1, 12, rotation, Colors.purpleAccent, "Psychosis");
    _drawGear(canvas, center2, radius2, 8, -rotation * (radius1/radius2) + 0.2, Colors.cyanAccent, "Box B");
  }

  void _drawGear(Canvas canvas, Offset center, double radius, int teethCount, double rotation, Color color, String label) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glow = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);

    final path = Path();
    final innerRadius = radius * 0.8;
    final toothDepth = radius * 0.2;

    for (int i = 0; i < teethCount * 2; i++) {
      final angle = rotation + (i * pi / teethCount);
      final r = (i % 2 == 0) ? radius : radius - toothDepth;
      
      final x = center.dx + r * cos(angle);
      final y = center.dy + r * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, glow);
    canvas.drawPath(path, paint);
    canvas.drawCircle(center, innerRadius * 0.3, paint);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
