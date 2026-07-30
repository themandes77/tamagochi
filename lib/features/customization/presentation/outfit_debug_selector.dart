import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';

class OutfitDebugSelector extends PositionComponent
    with HasGameReference, TapCallbacks {
  OutfitDebugSelector({required this.nti})
    : super(size: Vector2(_selectorWidth, _selectorHeight));

  final Nti nti;

  static const int _columnCount = 2;
  static const double _padding = 9;
  static const double _gap = 7;
  static const double _buttonWidth = 126;
  static const double _buttonHeight = 34;
  static const double _selectorWidth =
      _padding * 2 + _buttonWidth * _columnCount + _gap;
  static const double _selectorHeight = _padding * 2 + _buttonHeight * 2 + _gap;

  @override
  void onMount() {
    super.onMount();
    position = Vector2(
      (game.size.x - size.x) / 2,
      math.max(130, game.size.y - 178),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final panelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.x, size.y),
      const Radius.circular(16),
    );
    canvas.drawRRect(panelRect, Paint()..color = const Color(0xE6261C31));

    for (var index = 0; index < NtiOutfit.values.length; index++) {
      final outfit = NtiOutfit.values[index];
      final rect = _buttonRect(index);
      final isSelected = nti.outfit == outfit;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()
          ..color = isSelected
              ? const Color(0xFF8B5CF6)
              : const Color(0xFFF8F6FC),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()
          ..color = isSelected
              ? const Color(0xFFE8DCFF)
              : const Color(0xFF7E57C2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 3 : 1.5,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: outfit.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF332442),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width - 8);

      textPainter.paint(
        canvas,
        Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final point = event.localPosition.toOffset();

    for (var index = 0; index < NtiOutfit.values.length; index++) {
      if (_buttonRect(index).contains(point)) {
        unawaited(nti.wear(NtiOutfit.values[index]));
        return true;
      }
    }

    return false;
  }

  Rect _buttonRect(int index) {
    final column = index % _columnCount;
    final row = index ~/ _columnCount;

    return Rect.fromLTWH(
      _padding + column * (_buttonWidth + _gap),
      _padding + row * (_buttonHeight + _gap),
      _buttonWidth,
      _buttonHeight,
    );
  }
}
