import 'package:flutter/material.dart';

class SegmentedStatusBar extends StatelessWidget {
  const SegmentedStatusBar({
    required this.value,
    required this.color,
    this.segmentCount = 5,
    this.height = 8,
    super.key,
  }) : assert(segmentCount > 0),
       assert(height > 0);

  final double value;
  final Color color;
  final int segmentCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    final normalized = value.clamp(0.0, 1.0).toDouble();
    final radius = BorderRadius.circular(height * 0.5);
    final emptyTop = Color.lerp(color, Colors.white, 0.76)!;
    final emptyBottom = Color.lerp(color, Colors.white, 0.54)!;
    final borderColor = Color.lerp(color, Colors.black, 0.34)!;
    final dividerColor = Color.lerp(
      color,
      Colors.black,
      0.28,
    )!.withValues(alpha: 0.78);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 1.5,
              offset: Offset(0, 0.8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[emptyTop, emptyBottom],
                  ),
                ),
              ),
              if (normalized > 0)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: normalized,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color.lerp(color, Colors.white, 0.35)!,
                            color,
                            Color.lerp(color, Colors.black, 0.18)!,
                          ],
                          stops: const <double>[0, 0.48, 1],
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: 1,
                right: 1,
                top: 0.7,
                height: (height * 0.18).clamp(0.8, 1.3).toDouble(),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.38),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              CustomPaint(
                painter: _SegmentDividerPainter(
                  segmentCount: segmentCount,
                  color: dividerColor,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: borderColor, width: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentDividerPainter extends CustomPainter {
  const _SegmentDividerPainter({
    required this.segmentCount,
    required this.color,
  });

  final int segmentCount;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (segmentCount <= 1 || size.width <= 0 || size.height <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.65;

    for (var index = 1; index < segmentCount; index++) {
      final x = size.width * index / segmentCount;
      canvas.drawLine(Offset(x, 0.8), Offset(x, size.height - 0.8), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SegmentDividerPainter oldDelegate) {
    return oldDelegate.segmentCount != segmentCount ||
        oldDelegate.color != color;
  }
}
