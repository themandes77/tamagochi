import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class StoreAccessButton extends PositionComponent with TapCallbacks {
  StoreAccessButton({required this.onPressed})
    : super(size: Vector2(78, 42), priority: 100);

  final VoidCallback onPressed;

  @override
  void onMount() {
    super.onMount();
    position = Vector2(16, 40);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(14),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFF6D3FC0));
    canvas.drawRRect(
      rect,
      Paint()
        ..color = const Color(0xFFE8DCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final label = TextPainter(
      text: const TextSpan(
        text: 'TIENDA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x);

    label.paint(
      canvas,
      Offset((size.x - label.width) / 2, (size.y - label.height) / 2),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    onPressed();
    return true;
  }
}
