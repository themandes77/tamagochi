import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class MinigameSelector extends PositionComponent with TapCallbacks {
  final VoidCallback? onPlayTrepaNubes;

  static const double gap = 16;
  static const double buttonHeight = 60;
  static const double buttonWidth = 250;
  static const double closeBtnSize = 40;

  MinigameSelector({this.onPlayTrepaNubes});

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.black54,
    );

    _drawCloseButton(canvas);

    final title = TextPainter(
      text: TextSpan(
        text: 'Mini Games',
        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset((size.x - title.width) / 2, 80));

    _drawButton(canvas, 0, 'Trepa Nubes');
  }

  void _drawCloseButton(Canvas canvas) {
    final rect = Rect.fromLTWH(size.x - closeBtnSize - 10, 10, closeBtnSize, closeBtnSize);
    canvas.drawRect(rect, Paint()..color = Colors.white24);
    canvas.drawRect(rect, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final tp = TextPainter(
      text: TextSpan(
        text: 'X',
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(rect.center.dx - tp.width / 2, rect.center.dy - tp.height / 2));
  }

  void _drawButton(Canvas canvas, int index, String label) {
    final x = (size.x - buttonWidth) / 2;
    final y = 160 + index * (buttonHeight + gap);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, buttonWidth, buttonHeight),
      const Radius.circular(12),
    );

    canvas.drawRRect(rect, Paint()..color = Colors.white24);
    canvas.drawRRect(rect, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.x / 2 - tp.width / 2, y + (buttonHeight - tp.height) / 2));
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final local = event.localPosition.toOffset();

    final closeRect = Rect.fromLTWH(size.x - closeBtnSize - 10, 10, closeBtnSize, closeBtnSize);
    if (closeRect.contains(local)) {
      removeFromParent();
      return true;
    }

    final x = (size.x - buttonWidth) / 2;
    final y = 160.0;

    final rect = Rect.fromLTWH(x, y, buttonWidth, buttonHeight);
    if (rect.contains(local)) {
      onPlayTrepaNubes?.call();
      return true;
    }

    return false;
  }
}
