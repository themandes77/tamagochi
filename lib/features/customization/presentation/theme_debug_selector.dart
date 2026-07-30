import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/presentation/room_background.dart';

class ThemeDebugSelector extends PositionComponent
    with HasGameReference, TapCallbacks {
  ThemeDebugSelector({required this.background})
    : super(size: Vector2(_selectorWidth, _selectorHeight), priority: 100);

  final RoomBackground background;

  static const double _padding = 8;
  static const double _gap = 6;
  static const double _buttonWidth = 76;
  static const double _buttonHeight = 34;
  static const double _selectorWidth =
      _padding * 2 + _buttonWidth * 4 + _gap * 3;
  static const double _selectorHeight = _padding * 2 + _buttonHeight;

  @override
  void onMount() {
    super.onMount();
    position = Vector2((game.size.x - size.x) / 2, 136);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(16),
      ),
      Paint()..color = const Color(0xD9261C31),
    );

    for (var index = 0; index < defaultThemeOptions.length; index++) {
      final theme = defaultThemeOptions[index];
      final rect = _buttonRect(index);
      final isSelected = background.theme.id == theme.id;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()
          ..color = isSelected
              ? Color(theme.accentColorValue)
              : const Color(0xFFF8F6FC),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(11)),
        Paint()
          ..color = isSelected
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF7E57C2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.5 : 1.5,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: theme.displayName,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF332442),
            fontSize: 10,
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

    for (var index = 0; index < defaultThemeOptions.length; index++) {
      if (_buttonRect(index).contains(point)) {
        unawaited(background.setTheme(defaultThemeOptions[index]));
        return true;
      }
    }

    return false;
  }

  Rect _buttonRect(int index) {
    return Rect.fromLTWH(
      _padding + index * (_buttonWidth + _gap),
      _padding,
      _buttonWidth,
      _buttonHeight,
    );
  }
}
