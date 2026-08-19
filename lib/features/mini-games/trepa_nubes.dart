import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/mini-games/minigame_top_banner.dart';
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

  _Platform(this.x, this.y, this.w, this.h, {this.type = _PlatformType.normal})
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
  static const double platH = 14;
  static const double playerW = 60;
  static const double playerH = 75;
  static const double playerCollisionInset = 10;
  static const double platGap = 60;
  static const double gapVariance = 20;
  static const double baseScrollSpeed = 80;
  static const double movingRange = 60;
  static const double movingSpeed = 70;
  static const double dissolveTime = 0.75;
  static const double brittleFallDistance = 90;
  static const double movingChance = 0.15;
  static const double dissolveChance = 0.15;
  static const double platformSpriteAspectRatio = 403 / 1234;
  static const double brittleSpriteAspectRatio = 1024 / 1536;
  static const double brittleSpriteTopInset = 320 / 1024;
  double get _currentGravity => baseGravity + (score / 10) * 20;
  double get _currentScrollSpeed => baseScrollSpeed + (score / 50) * 5;

  late double px, py;
  double pvy = 0;
  double camY = 0;
  int score = 0;
  int _earnedCoins = 0;
  bool gameOver = false;
  bool _started = false;
  double _dragX = 0;
  final Random _random = Random();
  final List<_Platform> _platforms = [];
  final List<_Coin> _coins = [];
  int _platformsSinceCoin = 0;
  int _nextCoinInterval = 0;
  _Platform? _standingOn;
  Sprite? _backgroundSprite;
  Sprite? _platformSprite;
  Sprite? _brittlePlatformSprite;
  late final NtiMinigameAvatar _ntiAvatar;
  Sprite? _coinSprite;
  final MinigameTopBanner _topBanner = MinigameTopBanner(
    gameNameFontSize: 13,
    scoreFontSize: 15,
    coinFontSize: 16,
  );

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _backgroundSprite = await Sprite.load(
      'backgrounds/salto_estelar_background.png',
    );
    _platformSprite = await Sprite.load('ui/store_showcase_platform_v1.png');
    _brittlePlatformSprite = await Sprite.load(
      'minigame-elements/brittle_platform_v1.png',
    );
    _ntiAvatar = NtiMinigameAvatar(outfit: ntiOutfit);
    await _ntiAvatar.load();
    _coinSprite = await Sprite.load('ui/coin_star_v1.png');
    await _topBanner.load();
    _nextCoinInterval = 50 + _random.nextInt(21);

    _platforms.add(
      _Platform(size.x / 2 - basePlatW / 2, size.y - 40, basePlatW, platH),
    );

    for (int i = 0; i < 12; i++) {
      _addPlatformAbove(size.y - 40 - (i + 1) * platGap, randomType: i >= 3);
    }

    px = size.x / 2 - playerW / 2;
    py = size.y - 40 - playerH;
  }

  _Platform _makePlatform(
    double x,
    double y,
    double w, {
    bool randomType = true,
  }) {
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
      p.vx =
          (movingSpeed * 0.6 + _random.nextDouble() * movingSpeed * 0.8) *
          (_random.nextBool() ? 1 : -1);
      p.range = maxRange;
      return p;
    }
    return _Platform(x, y, w, platH);
  }

  void _addPlatformAbove(double referenceY, {bool randomType = true}) {
    const w = basePlatW;
    double x = _random.nextDouble() * (size.x - w);
    double y = referenceY - _random.nextDouble() * gapVariance;
    final plat = _makePlatform(x, y, w, randomType: randomType);
    _platforms.add(plat);

    // Keep the interval from building up while the active-coin cap is full.
    if (_coins.length >= 3) return;

    _platformsSinceCoin++;
    if (plat.type == _PlatformType.normal &&
        _platformsSinceCoin >= _nextCoinInterval) {
      final coinX =
          plat.x +
          _Coin.radius +
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
            px + playerW - playerCollisionInset > plat.x &&
            px + playerCollisionInset < plat.x + plat.w) {
          px = (px + (plat.x - prevX)).clamp(0, size.x - playerW);
          py = plat.y - playerH;
        }
      }
      if (plat.type == _PlatformType.dissolving && plat.dissolving) {
        plat.dissolveTimer -= dt;
      }
    }

    final previousBottom = py + playerH;
    pvy += _currentGravity * dt;
    py += pvy * dt;

    if (pvy > 0) {
      _standingOn = null;
      final currentBottom = py + playerH;
      _Platform? landingPlatform;
      for (final plat in _platforms) {
        if (!plat.dissolving &&
            previousBottom <= plat.y + 2 &&
            currentBottom >= plat.y - 2 &&
            px + playerW - playerCollisionInset > plat.x &&
            px + playerCollisionInset < plat.x + plat.w) {
          if (landingPlatform == null || plat.y < landingPlatform.y) {
            landingPlatform = plat;
          }
        }
      }
      if (landingPlatform != null) {
        final platform = landingPlatform;
        py = platform.y - playerH;
        pvy = jumpVel;
        _standingOn = platform;
        if (platform.type == _PlatformType.dissolving) {
          platform.dissolving = true;
          platform.dissolveTimer = dissolveTime;
        }
        if (!platform.scored) {
          score++;
          platform.scored = true;
        }
      }
    }

    camY -= _currentScrollSpeed * dt;

    final screenY = py - camY;
    if (screenY < size.y * 0.35) {
      camY = py - size.y * 0.35;
    }

    final topWorldY = camY;
    if (_platforms.isEmpty ||
        _platforms.map((p) => p.y).reduce(min) > topWorldY - 400) {
      final baseY = _platforms.isEmpty
          ? camY - 200
          : _platforms.map((p) => p.y).reduce(min);
      for (int i = 0; i < 6; i++) {
        _addPlatformAbove(baseY - (i + 1) * platGap);
      }
    }

    _platforms.removeWhere((p) {
      final remove =
          p.y > camY + size.y ||
          p.y + p.h < camY ||
          (p.type == _PlatformType.dissolving &&
              p.dissolving &&
              p.dissolveTimer <= 0);
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
        CoinStore.instance.add(1);
      }
    }
    _coins.removeWhere(
      (c) =>
          c.collected ||
          !_platforms.contains(c.platform) ||
          c.y > camY + size.y + 20,
    );

    if (py - camY > size.y + 50) {
      gameOver = true;
      _earnedCoins = min(50, score ~/ 20);
      CoinStore.instance.add(_earnedCoins);
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    if (_backgroundSprite != null) {
      _backgroundSprite!.render(canvas, position: Vector2.zero(), size: size);
    } else {
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1a1a2e),
          const Color(0xFF16213e),
          const Color(0xFF0f3460),
        ],
      );
      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
    }

    for (final plat in _platforms) {
      final screenY = plat.y - camY;
      if (screenY < -plat.h || screenY > size.y) continue;
      _drawPlatform(canvas, plat, screenY);
    }

    for (final coin in _coins) {
      final screenY = coin.y - camY + sin(coin.phase) * 2;
      if (screenY < -_Coin.radius * 2 || screenY > size.y + _Coin.radius * 2) {
        continue;
      }
      final center = Offset(coin.x, screenY);
      _coinSprite?.render(
        canvas,
        position: Vector2(center.dx - _Coin.radius, center.dy - _Coin.radius),
        size: Vector2.all(_Coin.radius * 2),
      );
    }

    final playerScreenY = py - camY;
    _ntiAvatar.render(
      canvas,
      position: Vector2(px, playerScreenY),
      size: Vector2(playerW, playerH),
    );

    _topBanner.render(canvas, size, gameName: 'Salto\nEstelar', score: score);

    if (!_started) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);

      final titleTp = TextPainter(
        text: TextSpan(
          text: 'Trepa Nubes',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      titleTp.paint(
        canvas,
        Offset((size.x - titleTp.width) / 2, size.y / 2 - 60),
      );

      final hintTp = TextPainter(
        text: TextSpan(
          text: 'Drag to start',
          style: const TextStyle(color: Colors.white70, fontSize: 20),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      hintTp.paint(canvas, Offset((size.x - hintTp.width) / 2, size.y / 2));
    }

    if (gameOver) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);
      final goTp = TextPainter(
        text: TextSpan(
          text:
              'Game Over\nScore: $score\nMonedas: +$_earnedCoins\n\nTap to exit',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      goTp.paint(
        canvas,
        Offset((size.x - goTp.width) / 2, (size.y - goTp.height) / 2 - 30),
      );
    }
  }

  void _drawPlatform(Canvas canvas, _Platform platform, double screenY) {
    final sprite = platform.type == _PlatformType.dissolving
        ? _brittlePlatformSprite
        : _platformSprite;
    if (sprite == null) return;

    final isBrittle = platform.type == _PlatformType.dissolving;
    final aspectRatio = isBrittle
        ? brittleSpriteAspectRatio
        : platformSpriteAspectRatio;
    final visualHeight = max(platform.h, platform.w * aspectRatio);
    var progress = 1.0;
    if (isBrittle && platform.dissolving) {
      progress = (platform.dissolveTimer / dissolveTime).clamp(0.0, 1.0);
    }

    if (progress <= 0) return;
    final fallProgress = 1 - progress;
    final fallOffset = brittleFallDistance * fallProgress * fallProgress;
    final topInset = isBrittle ? visualHeight * brittleSpriteTopInset : 0.0;
    final y = screenY - topInset + fallOffset;

    if (progress < 1) {
      canvas.saveLayer(
        Rect.fromLTWH(platform.x, y, platform.w, visualHeight),
        Paint()
          ..color = Color.fromARGB((255 * progress).round(), 255, 255, 255),
      );
    }
    sprite.render(
      canvas,
      position: Vector2(platform.x, y),
      size: Vector2(platform.w, visualHeight),
    );
    if (progress < 1) {
      canvas.restore();
    }
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (gameOver) return true;
    if (!_started) {
      _started = true;
      pvy = jumpVel;
    }
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
    super.onDragEnd(event);
    return true;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
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
