import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class _Platform {
  double x, y, w, h;
  bool scored;
  _Platform(this.x, this.y, this.w, this.h) : scored = false;
}

class TrepaNubes extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference {
  static const double baseGravity = 1200;
  static const double jumpVel = -520;
  static const double basePlatW = 64;
  static const double minPlatW = 28;
  static const double platH = 14;
  static const double playerW = 48;
  static const double playerH = 60;
  static const double platGap = 60;
  static const double gapVariance = 20;

  double get _currentGravity => baseGravity + (score / 10) * 20;
  double get _currentPlatW => max(minPlatW, basePlatW - (score / 8) * 2);

  late double px, py;
  double pvy = 0;
  double camY = 0;
  int score = 0;
  bool gameOver = false;
  bool _started = false;
  bool _dragging = false;
  double _dragX = 0;
  final Random _random = Random();
  final List<_Platform> _platforms = [];
  Sprite? _ntiSprite;

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _ntiSprite = await Sprite.load('nti.png');

    _platforms.add(_Platform(size.x / 2 - basePlatW / 2, size.y - 40, basePlatW, platH));

    for (int i = 0; i < 12; i++) {
      _addPlatformAbove(size.y - 40 - (i + 1) * platGap);
    }

    px = size.x / 2 - playerW / 2;
    py = size.y - 40 - playerH;
  }

  void _addPlatformAbove(double referenceY) {
    final w = _currentPlatW;
    double x = _random.nextDouble() * (size.x - w);
    double y = referenceY - _random.nextDouble() * gapVariance;
    _platforms.add(_Platform(x, y, w, platH));
  }

  @override
  void update(double dt) {
    if (gameOver || !_started) return;

    pvy += _currentGravity * dt;

    py += pvy * dt;

    if (pvy > 0) {
      final playerBottom = py + playerH;
      for (final plat in _platforms) {
        if (playerBottom <= plat.y + 2 &&
            playerBottom + pvy * dt >= plat.y - 2 &&
            px + playerW > plat.x &&
            px < plat.x + plat.w) {
          py = plat.y - playerH;
          pvy = jumpVel;
          if (!plat.scored) {
            score++;
            plat.scored = true;
          }
          break;
        }
      }
    }

    final screenY = py - camY;
    if (screenY < size.y * 0.35) {
      camY = py - size.y * 0.35;
    }

    final topWorldY = camY;
    if (_platforms.isEmpty || _platforms.map((p) => p.y).reduce(min) > topWorldY - 400) {
      final baseY = _platforms.isEmpty ? camY - 200 : _platforms.map((p) => p.y).reduce(min);
      for (int i = 0; i < 6; i++) {
        _addPlatformAbove(baseY - (i + 1) * platGap);
      }
    }

    final bottomWorldY = camY + size.y + 100;
    _platforms.removeWhere((p) => p.y > bottomWorldY);

    if (py - camY > size.y + 50) {
      gameOver = true;
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e), const Color(0xFF0f3460)],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    for (final plat in _platforms) {
      final screenY = plat.y - camY;
      if (screenY < -plat.h || screenY > size.y) continue;

      final gradient2 = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFe0e0e0), const Color(0xFF90a4ae)],
      );
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(plat.x, screenY, plat.w, plat.h),
        const Radius.circular(5),
      );
      canvas.drawRRect(rrect, Paint()..shader = gradient2.createShader(
        Rect.fromLTWH(plat.x, screenY, plat.w, plat.h),
      ));
      canvas.drawRRect(
        rrect,
        Paint()..color = Colors.white38..style = PaintingStyle.stroke..strokeWidth = 1,
      );
    }

    final playerScreenY = py - camY;
    if (_ntiSprite != null) {
      _ntiSprite!.render(
        canvas,
        position: Vector2(px, playerScreenY),
        size: Vector2(playerW, playerH),
      );
    }

    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset((size.x - scoreTp.width) / 2, 16));

    if (!_started) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);

      final titleTp = TextPainter(
        text: TextSpan(
          text: 'Trepa Nubes',
          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titleTp.paint(canvas, Offset(
        (size.x - titleTp.width) / 2,
        size.y / 2 - 60,
      ));

      final hintTp = TextPainter(
        text: TextSpan(
          text: 'Drag to start',
          style: const TextStyle(color: Colors.white70, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hintTp.paint(canvas, Offset(
        (size.x - hintTp.width) / 2,
        size.y / 2,
      ));
    }

    if (gameOver) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);
      final goTp = TextPainter(
        text: TextSpan(
          text: 'Game Over\nScore: $score\n\nTap to exit',
          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      goTp.paint(canvas, Offset(
        (size.x - goTp.width) / 2,
        (size.y - goTp.height) / 2 - 30,
      ));
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    if (gameOver) return true;
    if (!_started) {
      _started = true;
      pvy = jumpVel;
    }
    _dragging = true;
    _dragX = event.localPosition.x;
    px = (_dragX - playerW / 2).clamp(0, size.x - playerW);
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (gameOver) return true;
    _dragX += event.localDelta.x;
    px = (_dragX - playerW / 2).clamp(0, size.x - playerW);
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    _dragging = false;
    return true;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    _dragging = false;
    return true;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (!_started) {
      _started = true;
      pvy = jumpVel;
      return true;
    }
    if (gameOver) {
      removeFromParent();
      return true;
    }
    return false;
  }
}
