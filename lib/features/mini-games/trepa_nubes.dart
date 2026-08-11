import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/integration/minigames/nti_minigame_avatar.dart';

enum _PlatformType { normal, moving, dissolving }

class _Platform {
  double x, y, w, h;
  bool scored;
  _PlatformType type;
  double vx;
  double baseX;
  double range;
  bool dissolving;
  double dissolveTimer;

  _Platform(this.x, this.y, this.w, this.h,
      {this.type = _PlatformType.normal})
      : scored = false,
        vx = 0,
        baseX = x,
        range = 0,
        dissolving = false,
        dissolveTimer = 0;
}

class _Coin {
  final _Platform platform;
  double x, y;
  static const double radius = 10;
  bool collected;
  double phase;
  _Coin(this.platform, this.x)
      : y = platform.y - radius,
        collected = false,
        phase = 0;
}

class TrepaNubes extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference {
  TrepaNubes({required this.ntiOutfit});

  final NtiOutfit ntiOutfit;
  static const double baseGravity = 1200;
  static const double jumpVel = -520;
  static const double basePlatW = 64;
  static const double minPlatW = 28;
  static const double platH = 14;
  static const double playerW = 48;
  static const double playerH = 60;
  static const double platGap = 60;
  static const double gapVariance = 20;
  static const double baseScrollSpeed = 80;
  static const double movingRange = 60;
  static const double movingSpeed = 70;
  static const double dissolveTime = 0.45;
  static const double movingChance = 0.15;
  static const double dissolveChance = 0.15;
  double get _currentGravity => baseGravity + (score / 10) * 20;
  double get _currentPlatW => max(minPlatW, basePlatW - (score / 8) * 2);
  double get _currentScrollSpeed => baseScrollSpeed + (score / 50) * 5;

  late double px, py;
  double pvy = 0;
  double camY = 0;
  int score = 0;
  int _earnedCoins = 0;
  bool gameOver = false;
  bool _started = false;
  bool _dragging = false;
  double _dragX = 0;
  final Random _random = Random();
  final List<_Platform> _platforms = [];
  final List<_Coin> _coins = [];
  int _coinsCollected = 0;
  int _platformsSinceCoin = 0;
  int _nextCoinInterval = 0;
  _Platform? _standingOn;
  late final NtiMinigameAvatar _ntiAvatar;

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _ntiAvatar = NtiMinigameAvatar(outfit: ntiOutfit);
    await _ntiAvatar.load();
    _nextCoinInterval = 50 + _random.nextInt(21);

    _platforms.add(_Platform(size.x / 2 - basePlatW / 2, size.y - 40, basePlatW, platH));

    for (int i = 0; i < 12; i++) {
      _addPlatformAbove(size.y - 40 - (i + 1) * platGap, randomType: i >= 3);
    }

    px = size.x / 2 - playerW / 2;
    py = size.y - 40 - playerH;
  }

  _Platform _makePlatform(double x, double y, double w, {bool randomType = true}) {
    if (!randomType) {
      return _Platform(x, y, w, platH);
    }
    final roll = _random.nextDouble();
    if (roll < dissolveChance) {
      return _Platform(x, y, w, platH, type: _PlatformType.dissolving);
    }
    if (roll < dissolveChance + movingChance) {
      final maxRange = min(movingRange, (size.x - w) / 2);
      final safeX = maxRange * 2 > size.x - w
          ? (size.x - w) / 2
          : maxRange + _random.nextDouble() * (size.x - w - maxRange * 2);
      final p = _Platform(safeX, y, w, platH, type: _PlatformType.moving);
      p.vx = (movingSpeed * 0.6 + _random.nextDouble() * movingSpeed * 0.8) *
          (_random.nextBool() ? 1 : -1);
      p.range = maxRange;
      return p;
    }
    return _Platform(x, y, w, platH);
  }

  void _addPlatformAbove(double referenceY, {bool randomType = true}) {
    final w = _currentPlatW;
    double x = _random.nextDouble() * (size.x - w);
    double y = referenceY - _random.nextDouble() * gapVariance;
    final plat = _makePlatform(x, y, w, randomType: randomType);
    _platforms.add(plat);

    // Keep the interval from building up while the active-coin cap is full.
    if (_coins.length >= 3) return;

    _platformsSinceCoin++;
    if (plat.type == _PlatformType.normal &&
        _platformsSinceCoin >= _nextCoinInterval) {
      final coinX = plat.x + _Coin.radius +
          _random.nextDouble() * (plat.w - _Coin.radius * 2);
      _coins.add(_Coin(plat, coinX));
      _platformsSinceCoin = 0;
      _nextCoinInterval = 50 + _random.nextInt(21);
    }
  }

  @override
  void update(double dt) {
    _ntiAvatar.update(dt);
    if (gameOver || !_started) return;

    for (final plat in _platforms) {
      if (plat.type == _PlatformType.moving) {
        final prevX = plat.x;
        plat.x += plat.vx * dt;
        if (plat.x < plat.baseX - plat.range) {
          plat.x = plat.baseX - plat.range;
          plat.vx = -plat.vx;
        } else if (plat.x > plat.baseX + plat.range) {
          plat.x = plat.baseX + plat.range;
          plat.vx = -plat.vx;
        }
        plat.x = plat.x.clamp(0.0, size.x - plat.w);
        if (identical(_standingOn, plat) &&
            py + playerH >= plat.y - 6 &&
            py + playerH <= plat.y + 6 &&
            px + playerW > plat.x &&
            px < plat.x + plat.w) {
          px = (px + (plat.x - prevX)).clamp(0, size.x - playerW);
          py = plat.y - playerH;
        }
      }
      if (plat.type == _PlatformType.dissolving && plat.dissolving) {
        plat.dissolveTimer -= dt;
      }
    }

    pvy += _currentGravity * dt;

    py += pvy * dt;

    if (pvy > 0) {
      _standingOn = null;
      final playerBottom = py + playerH;
      for (final plat in _platforms) {
        if (playerBottom <= plat.y + 2 &&
            playerBottom + pvy * dt >= plat.y - 2 &&
            px + playerW > plat.x &&
            px < plat.x + plat.w) {
          py = plat.y - playerH;
          pvy = jumpVel;
          _standingOn = plat;
          if (plat.type == _PlatformType.dissolving && !plat.dissolving) {
            plat.dissolving = true;
            plat.dissolveTimer = dissolveTime;
          }
          if (!plat.scored) {
            score++;
            plat.scored = true;
          }
          break;
        }
      }
    }

    camY -= _currentScrollSpeed * dt;

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

    _platforms.removeWhere((p) {
      final remove = p.y > camY + size.y ||
          p.y + p.h < camY ||
          (p.type == _PlatformType.dissolving && p.dissolving && p.dissolveTimer <= 0);
      if (remove && identical(_standingOn, p)) {
        _standingOn = null;
      }
      return remove;
    });

    for (final coin in _coins) {
      coin.phase += dt * 3;
      final dx = (px + playerW / 2) - coin.x;
      final dy = (py + playerH / 2) - coin.y;
      final r = _Coin.radius + playerW / 2;
      if (dx * dx + dy * dy <= r * r) {
        coin.collected = true;
        _coinsCollected++;
        CoinStore.instance.add(1);
      }
    }
    _coins.removeWhere((c) =>
        c.collected ||
        !_platforms.contains(c.platform) ||
        c.y > camY + size.y + 20);

    if (py - camY > size.y + 50) {
      gameOver = true;
      _earnedCoins = min(50, score ~/ 20);
      CoinStore.instance.add(_earnedCoins);
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

      if (plat.type == _PlatformType.dissolving && plat.dissolving) {
        final progress = (plat.dissolveTimer / dissolveTime).clamp(0.0, 1.0);
        final h = plat.h * progress;
        if (h <= 0) continue;
        final y = screenY + (plat.h - h);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(plat.x, y, plat.w, h),
            const Radius.circular(5),
          ),
          Paint()..color = const Color(0xFFe64a19).withOpacity(0.6 + 0.4 * progress),
        );
        continue;
      }

      Color c1, c2;
      switch (plat.type) {
        case _PlatformType.moving:
          c1 = const Color(0xFFa5d8ff);
          c2 = const Color(0xFF4d9de0);
          break;
        case _PlatformType.dissolving:
          c1 = const Color(0xFFffcc80);
          c2 = const Color(0xFFe64a19);
          break;
        case _PlatformType.normal:
          c1 = const Color(0xFFe0e0e0);
          c2 = const Color(0xFF90a4ae);
          break;
      }

      final gradient2 = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c1, c2],
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

    for (final coin in _coins) {
      final screenY = coin.y - camY + sin(coin.phase) * 2;
      if (screenY < -_Coin.radius * 2 || screenY > size.y + _Coin.radius * 2) continue;
      final center = Offset(coin.x, screenY);
      canvas.drawCircle(center, _Coin.radius, Paint()..color = const Color(0xFFf6c445));
      canvas.drawCircle(center, _Coin.radius, Paint()
        ..color = const Color(0xFFb8860b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      final coinTp = TextPainter(
        text: TextSpan(
          text: '\$',
          style: const TextStyle(color: Color(0xFFb8860b), fontSize: 12, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      coinTp.paint(canvas, center - Offset(coinTp.width / 2, coinTp.height / 2));
    }

    final playerScreenY = py - camY;
    _ntiAvatar.render(
      canvas,
      position: Vector2(px, playerScreenY),
      size: Vector2(playerW, playerH),
    );

    final scoreTp = TextPainter(
      text: TextSpan(
        text: '$score',
        style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreTp.paint(canvas, Offset((size.x - scoreTp.width) / 2, 16));

    final coinCountIcon = Offset(size.x - 52, 30);
    canvas.drawCircle(coinCountIcon, 13, Paint()..color = const Color(0xFFf6c445));
    canvas.drawCircle(coinCountIcon, 13, Paint()
      ..color = const Color(0xFFb8860b)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    final coinCountTp = TextPainter(
      text: TextSpan(
        text: '$_coinsCollected',
        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    coinCountTp.paint(canvas, Offset(
      size.x - 52 - coinCountTp.width - 14,
      30 - coinCountTp.height / 2,
    ));

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
          text: 'Game Over\nScore: $score\nMonedas: +$_earnedCoins\n\nTap to exit',
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
