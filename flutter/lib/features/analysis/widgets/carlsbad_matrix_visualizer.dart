import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CarlsbadModality {
  artificialFortress, // Modality A
  hPawnBaitHook,      // Modality B
  preEmptiveEvacuation // Modality C
}

class CarlsbadMatrixVisualizer extends StatefulWidget {
  final CarlsbadModality modality;
  final bool showGeologicalConstraints;

  const CarlsbadMatrixVisualizer({
    super.key,
    required this.modality,
    required this.showGeologicalConstraints,
  });

  @override
  State<CarlsbadMatrixVisualizer> createState() => _CarlsbadMatrixVisualizerState();
}

class _CarlsbadMatrixVisualizerState extends State<CarlsbadMatrixVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.03),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _CarlsbadIsometricPainter(
                  modality: widget.modality,
                  showGeological: widget.showGeologicalConstraints,
                  animationValue: _animationController.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "3D TOPOGRAPHY PROJECTION ACTIVE",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
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

class _CarlsbadIsometricPainter extends CustomPainter {
  final CarlsbadModality modality;
  final bool showGeological;
  final double animationValue;

  _CarlsbadIsometricPainter({
    required this.modality,
    required this.showGeological,
    required this.animationValue,
  });

  // Projection math
  Offset project(double x, double y, double z, Size size) {
    // Standard isometric mapping variables
    final double angle = math.pi / 6; // 30 degrees
    final double cosAngle = math.cos(angle);
    final double sinAngle = math.sin(angle);

    // Scale coordinates to fit nicely in canvas
    final double gridScale = size.width / 13;

    // Center coordinates
    final double cx = size.width / 2;
    final double cy = size.height / 2 + size.height * 0.08;

    // Relative to board center (3.5, 3.5 is the middle of 8x8)
    final double rx = (x - 3.5) * gridScale;
    final double ry = (y - 3.5) * gridScale;

    final double screenX = cx + (rx - ry) * cosAngle;
    final double screenY = cy + (rx + ry) * sinAngle - z;

    return Offset(screenX, screenY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Generate elevations for each square
    final List<List<double>> elevations = List.generate(8, (_) => List.filled(8, 0.0));

    // Modality A: Elevate Lonesome Ridge (the corner squares g8, h8, g7, h7 - indices 6..7, 6..7)
    if (modality == CarlsbadModality.artificialFortress) {
      for (int x = 5; x < 8; x++) {
        for (int y = 5; y < 8; y++) {
          elevations[x][y] = 25.0 + (x + y - 10) * 5.0; // Tiered plateau
        }
      }
    }

    // Modality B: H-Pawn bait hook (fault line along h-file, column index 7)
    if (modality == CarlsbadModality.hPawnBaitHook) {
      for (int y = 0; y < 8; y++) {
        elevations[7][y] = -12.0 + math.sin(animationValue * 2 * math.pi + y) * 3.0; // Dipping fault line
      }
    }

    // Render cells back-to-front (top-left coordinates to bottom-right coordinates)
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        _drawIsoTile(canvas, size, x.toDouble(), y.toDouble(), elevations, elevations[x][y]);
      }
    }

    // Draw Overlay path logic
    if (modality == CarlsbadModality.preEmptiveEvacuation) {
      _drawEvacuationPath(canvas, size, elevations);
    } else if (modality == CarlsbadModality.hPawnBaitHook) {
      _drawBaitHookVisuals(canvas, size, elevations);
    } else if (modality == CarlsbadModality.artificialFortress) {
      _drawACECShield(canvas, size, elevations);
    }
  }

  void _drawIsoTile(
    Canvas canvas,
    Size size,
    double x,
    double y,
    List<List<double>> elevations,
    double z,
  ) {
    // Determine land ownership color (Public vs Private BLM Split Estates checkerboard)
    // Public = Cyan/Teal style, Private = Slate/Grey style
    // If showGeological is true, we render using environmental land classification
    final bool isPublicLand = (x.toInt() + y.toInt()) % 2 == 0;
    
    Color topColor;
    Color sideColorL;
    Color sideColorR;

    if (showGeological) {
      if (isPublicLand) {
        // Public Land (Teal/Emerald)
        topColor = const Color(0xFF0F766E).withOpacity(0.85);
        sideColorL = const Color(0xFF0F766E).withOpacity(0.65);
        sideColorR = const Color(0xFF115E59).withOpacity(0.55);
      } else {
        // Private / Split Estate Land (Warm Amber / Desert Orange)
        topColor = const Color(0xFFC2410C).withOpacity(0.85);
        sideColorL = const Color(0xFF9A3412).withOpacity(0.65);
        sideColorR = const Color(0xFF7C2D12).withOpacity(0.55);
      }
    } else {
      // Chess board colors (Deep Blue-Grey glassmorphism)
      final bool isLightSquare = (x.toInt() + y.toInt()) % 2 == 0;
      if (isLightSquare) {
        topColor = const Color(0xFF1E293B).withOpacity(0.85);
        sideColorL = const Color(0xFF1E293B).withOpacity(0.65);
        sideColorR = const Color(0xFF0F172A).withOpacity(0.55);
      } else {
        topColor = const Color(0xFF020617).withOpacity(0.85);
        sideColorL = const Color(0xFF020617).withOpacity(0.65);
        sideColorR = const Color(0xFF000000).withOpacity(0.55);
      }
    }

    // Special highlighting for active Modalities
    if (modality == CarlsbadModality.artificialFortress && x >= 5 && y >= 5) {
      // Glow green/cyan for Lonesome Ridge ACEC Area
      topColor = topColor.withBlue(220).withGreen(200).withOpacity(0.9);
    } else if (modality == CarlsbadModality.hPawnBaitHook && x == 7) {
      // Glow red-orange for the fault line
      topColor = const Color(0xFF991B1B).withOpacity(0.9);
    }

    final pTop = project(x, y, z, size);
    final pRight = project(x + 1, y, elevations[(x + 1).clamp(0, 7).toInt()][y.toInt()], size);
    final pBottom = project(
      x + 1,
      y + 1,
      elevations[(x + 1).clamp(0, 7).toInt()][(y + 1).clamp(0, 7).toInt()],
      size,
    );
    final pLeft = project(x, y + 1, elevations[x.toInt()][(y + 1).clamp(0, 7).toInt()], size);

    // Draw Right Side Wall
    final pathRight = Path()
      ..moveTo(pBottom.dx, pBottom.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pRight.dx, pRight.dy + 8)
      ..lineTo(pBottom.dx, pBottom.dy + 8)
      ..close();
    canvas.drawPath(pathRight, Paint()..color = sideColorR);

    // Draw Left Side Wall
    final pathLeft = Path()
      ..moveTo(pLeft.dx, pLeft.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pBottom.dx, pBottom.dy + 8)
      ..lineTo(pLeft.dx, pLeft.dy + 8)
      ..close();
    canvas.drawPath(pathLeft, Paint()..color = sideColorL);

    // Draw Top Face
    final pathTop = Path()
      ..moveTo(pTop.dx, pTop.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..lineTo(pBottom.dx, pBottom.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..close();

    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(pathTop, Paint()..color = topColor);
    canvas.drawPath(pathTop, borderPaint);

    // Add environmental contour lines if showGeological is active
    if (showGeological && (x.toInt() + y.toInt()) % 3 == 0) {
      final contourPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      
      final pContour1 = Offset((pTop.dx + pLeft.dx) / 2, (pTop.dy + pLeft.dy) / 2);
      final pContour2 = Offset((pRight.dx + pBottom.dx) / 2, (pRight.dy + pBottom.dy) / 2);
      canvas.drawLine(pContour1, pContour2, contourPaint);
    }
  }

  // Draw ACEC defensive shield around King (Modality A)
  void _drawACECShield(Canvas canvas, Size size, List<List<double>> elevations) {
    // King is resting on Lonesome Ridge (6, 6)
    const kx = 6.0;
    const ky = 6.0;
    final kz = elevations[6][6];
    final kingCenter = project(kx + 0.5, ky + 0.5, kz, size);

    // Dynamic glowing shield circle
    final double maxRadius = size.width * 0.12;
    final double radius = maxRadius * (0.8 + 0.2 * math.sin(animationValue * 2 * math.pi));

    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.cyanAccent.withOpacity(0.35),
          Colors.cyanAccent.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: kingCenter, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(kingCenter, radius, glowPaint);

    // Pulse rings
    final ringPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.4 * (1.0 - animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(kingCenter, maxRadius * animationValue, ringPaint);

    // Draw the King icon conceptually in 3D
    final kingPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final kingGlow = Paint()
      ..color = Colors.cyanAccent
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    // Glowing King base node
    canvas.drawCircle(kingCenter - const Offset(0, 10), 10, kingGlow);
    canvas.drawCircle(kingCenter - const Offset(0, 10), 6, kingPaint);
    
    // Draw cross on top
    final crossPaint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 2.0;
    canvas.drawLine(kingCenter - const Offset(0, 22), kingCenter - const Offset(0, 14), crossPaint);
    canvas.drawLine(kingCenter - const Offset(4, 18), kingCenter - const Offset(-4, 18), crossPaint);
  }

  // Draw h-pawn bait hook lines inviting opponent pieces into a canyon (Modality B)
  void _drawBaitHookVisuals(Canvas canvas, Size size, List<List<double>> elevations) {
    // Fault line path along H-file
    final List<Offset> points = [];
    for (int y = 0; y < 8; y++) {
      points.add(project(7.5, y + 0.5, elevations[7][y], size));
    }

    final faultPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], faultPaint);
    }

    // Opponent entry path pointing at the fault line
    final opponentPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final opponentStart = project(4.5, 0.5, 0.0, size);
    final opponentMid = project(6.5, 3.5, 0.0, size);
    final opponentEnd = project(7.5, 4.5, elevations[7][4], size);

    final path = Path()
      ..moveTo(opponentStart.dx, opponentStart.dy)
      ..quadraticBezierTo(opponentMid.dx, opponentMid.dy, opponentEnd.dx, opponentEnd.dy);
    
    canvas.drawPath(path, opponentPaint);

    // Draw animated flow dot moving along the trap path
    final t = (animationValue * 1.5) % 1.0;
    // Calculate point on quadratic bezier: (1-t)^2 * p0 + 2(1-t)t * p1 + t^2 * p2
    final bx = (1 - t) * (1 - t) * opponentStart.dx + 2 * (1 - t) * t * opponentMid.dx + t * t * opponentEnd.dx;
    final by = (1 - t) * (1 - t) * opponentStart.dy + 2 * (1 - t) * t * opponentMid.dy + t * t * opponentEnd.dy;

    canvas.drawCircle(Offset(bx, by), 6, Paint()..color = Colors.amberAccent);
    canvas.drawCircle(Offset(bx, by), 12, Paint()..color = Colors.amberAccent.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  // Draw access easements path escaping to public land (Modality C)
  void _drawEvacuationPath(Canvas canvas, Size size, List<List<double>> elevations) {
    // Evacuation trajectory path through public land squares
    final List<Offset> pathSquares = [
      const Offset(6, 6), // Lonesome Ridge starting position
      const Offset(4, 6),
      const Offset(4, 4),
      const Offset(2, 4),
      const Offset(2, 2),
      const Offset(0, 2),
    ];

    final path = Path();
    for (int i = 0; i < pathSquares.length; i++) {
      final sq = pathSquares[i];
      final p = project(sq.dx + 0.5, sq.dy + 0.5, elevations[sq.dx.toInt()][sq.dy.toInt()], size);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final pathPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawPath(path, pathPaint);

    // Animated dots walking along the public easement path
    final double segmentCount = (pathSquares.length - 1).toDouble();
    final double totalT = animationValue; // 0.0 to 1.0
    final int currentSegment = (totalT * segmentCount).floor().clamp(0, pathSquares.length - 2);
    final double segmentT = (totalT * segmentCount) - currentSegment;

    final sqStart = pathSquares[currentSegment];
    final sqEnd = pathSquares[currentSegment + 1];

    final pStart = project(sqStart.dx + 0.5, sqStart.dy + 0.5, elevations[sqStart.dx.toInt()][sqStart.dy.toInt()], size);
    final pEnd = project(sqEnd.dx + 0.5, sqEnd.dy + 0.5, elevations[sqEnd.dx.toInt()][sqEnd.dy.toInt()], size);

    final dotPos = Offset(
      pStart.dx + (pEnd.dx - pStart.dx) * segmentT,
      pStart.dy + (pEnd.dy - pStart.dy) * segmentT,
    );

    canvas.drawCircle(dotPos, 5, Paint()..color = Colors.greenAccent);
    canvas.drawCircle(
      dotPos,
      10,
      Paint()
        ..color = Colors.greenAccent.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
