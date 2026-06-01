import 'package:flutter/material.dart';

class OpeningCurveChart extends StatefulWidget {
  final List<String> openings;
  final String selectedOpening;
  final Function(String) onOpeningSelected;
  final int totalGames;

  const OpeningCurveChart({
    Key? key,
    required this.openings,
    required this.selectedOpening,
    required this.onOpeningSelected,
    this.totalGames = 0,
  }) : super(key: key);

  @override
  State<OpeningCurveChart> createState() => _OpeningCurveChartState();
}

class _OpeningCurveChartState extends State<OpeningCurveChart> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalGames < 5) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.data_usage, color: Colors.white54, size: 48),
              SizedBox(height: 16),
              Text(
                'Gathering Data',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Play at least 5 games to unlock synthesis curves.\\n(Current: ${widget.totalGames}/5)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Opening Frequency vs Online Average",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              _buildLegendItem(Colors.greenAccent, "Favorite"),
              SizedBox(width: 16),
              _buildLegendItem(Colors.cyanAccent, "Online Average"),
            ],
          ),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _CurvePainter(
                    progress: _controller.value,
                    selectedOpeningIndex: widget.openings.indexOf(widget.selectedOpening),
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
          // X-Axis Labels
          Container(
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: widget.openings.map((opening) {
                final isSelected = opening == widget.selectedOpening;
                return GestureDetector(
                  onTap: () => widget.onOpeningSelected(opening),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white12 : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.cyanAccent.withOpacity(0.5) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      opening,
                      style: TextStyle(
                        color: isSelected ? Colors.cyanAccent : Colors.white54,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color.withOpacity(0.8)),
        SizedBox(width: 6),
        Text(text, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

class _CurvePainter extends CustomPainter {
  final double progress;
  final int selectedOpeningIndex;

  _CurvePainter({required this.progress, required this.selectedOpeningIndex});

  @override
  void paint(Canvas canvas, Size size) {
    // A simplified representation of overlapping spline curves
    final width = size.width;
    final height = size.height;

    final paintFavorite = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [Colors.greenAccent.withOpacity(0.4 * progress), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final paintFavoriteLine = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.greenAccent.withOpacity(0.8 * progress)
      ..strokeWidth = 3.0;

    final paintOnline = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [Colors.cyanAccent.withOpacity(0.4 * progress), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final paintOnlineLine = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.cyanAccent.withOpacity(0.8 * progress)
      ..strokeWidth = 3.0;

    final pathFav = Path();
    final pathFavLine = Path();
    
    pathFav.moveTo(0, height);
    pathFavLine.moveTo(0, height * 0.8);

    // Hardcoded demo points based on user sketch logic
    final favPoints = [height * 0.8, height * 0.3, height * 0.6, height * 0.2, height * 0.9];
    final onlinePoints = [height * 0.7, height * 0.5, height * 0.4, height * 0.5, height * 0.8];
    
    final step = width / (favPoints.length - 1);

    for (int i = 0; i < favPoints.length - 1; i++) {
      double x1 = i * step;
      double y1 = favPoints[i];
      double x2 = (i + 1) * step;
      double y2 = favPoints[i + 1];

      double cx1 = x1 + step / 2;
      double cy1 = y1;
      double cx2 = x1 + step / 2;
      double cy2 = y2;

      pathFav.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
      pathFavLine.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }
    pathFav.lineTo(width, height);
    pathFav.close();

    final pathOnline = Path();
    final pathOnlineLine = Path();
    
    pathOnline.moveTo(0, height);
    pathOnlineLine.moveTo(0, height * 0.7);

    for (int i = 0; i < onlinePoints.length - 1; i++) {
      double x1 = i * step;
      double y1 = onlinePoints[i];
      double x2 = (i + 1) * step;
      double y2 = onlinePoints[i + 1];

      double cx1 = x1 + step / 2;
      double cy1 = y1;
      double cx2 = x1 + step / 2;
      double cy2 = y2;

      pathOnline.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
      pathOnlineLine.cubicTo(cx1, cy1, cx2, cy2, x2, y2);
    }
    pathOnline.lineTo(width, height);
    pathOnline.close();

    canvas.drawPath(pathFav, paintFavorite);
    canvas.drawPath(pathFavLine, paintFavoriteLine);
    
    canvas.drawPath(pathOnline, paintOnline);
    canvas.drawPath(pathOnlineLine, paintOnlineLine);

    // Draw selection highlight
    if (selectedOpeningIndex >= 0 && selectedOpeningIndex < favPoints.length) {
      double highlightX = selectedOpeningIndex * step;
      final highlightPaint = Paint()
        ..color = Colors.white24
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(highlightX - 20, 0, 40, height), highlightPaint);
      
      final dotPaint = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(highlightX, favPoints[selectedOpeningIndex]), 5, dotPaint);
      canvas.drawCircle(Offset(highlightX, onlinePoints[selectedOpeningIndex]), 5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
