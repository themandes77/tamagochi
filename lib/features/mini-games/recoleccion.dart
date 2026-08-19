import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/mini-games/coin_balance_hud.dart';
import 'package:flutter_application_1/features/mini-games/minigame_top_banner.dart';
import 'package:flutter_application_1/integration/minigames/nti_minigame_avatar.dart';

enum _ItemType { fruit, coin, like, dislike }

class _FallingItem {
  double x;
  double y;
  double speed;
  double phase;
  final Sprite? sprite;
  final double size;
  final _ItemType type;
  bool caught;

  _FallingItem(
    this.x,
    this.y,
    this.speed,
    this.sprite,
    this.size, {
    required this.type,
  }) : phase = 0,
       caught = false;
}

class Recoleccion extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference {
  Recoleccion({required this.ntiOutfit});

  final NtiOutfit ntiOutfit;

  static const double playerWidth = 54;
  static const double playerHeight = 68;
  // La plataforma y el suelo lógico comparten ahora la misma superficie.
  // Bajamos ambos juntos para que NTI esté realmente apoyado junto al borde
  // inferior, sin desfasar sprite e hitbox.
  static const double platformVisualHeight = 44;
  static const double platformSideMargin = 12;
  static const double itemRadius = 18;
  static const double spawnInterval = 0.65;
  static const double coinChance = 0.10;
  static const double likeChance = 0.10;
  static const double dislikeChance = 0.10;

  final Random _random = Random();
  final List<_FallingItem> _items = [];
  final List<Sprite> _elementSprites = [];
  final MinigameTopBanner _topBanner = MinigameTopBanner(
    gameNameFontSize: 13,
    scoreFontSize: 18,
    coinFontSize: 20,
    gameNameCenterFactor: 0.255,
  );
  late final NtiMinigameAvatar _ntiAvatar;
  Sprite? _backgroundSprite;
  Sprite? _platformSprite;
  Sprite? _coinSprite;
  Sprite? _heartSprite;

  late double px;
  late double py;
  double _spawnTimer = 0;
  double _dragX = 0;
  int _score = 0;
  int _earnedCoins = 0;
  int _pendingCoins = 0;
  int _lives = 3;
  bool _started = false;
  bool _gameOver = false;

  /// Contrato de solo lectura para el host de integración.
  /// No altera reglas, economía ni flujo interno del minijuego.
  int get score => _score;
  bool get gameOver => _gameOver;

  // La plataforma nace exactamente desde el borde inferior del viewport.
  // El groundY baja con ella: no existe separación entre presentación y física.
  double get _groundY => size.y - platformVisualHeight;

  // Los PNG integrados de NTI conservan unos pocos píxeles transparentes en
  // la base. Compensamos sólo ese padding de render; la hitbox permanece en py.
  // Ajuste visual de +2 px tras prueba en emulador para apoyar mejor el arte.
  static const double ntiVisualGroundOffset = 9;

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _ntiAvatar = NtiMinigameAvatar(outfit: ntiOutfit);
    await _ntiAvatar.load();
    try {
      _backgroundSprite = await Sprite.load(
        'backgrounds/recoleccion_background_v1.png',
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.recoleccion_art',
          context: ErrorDescription(
            'al cargar el fondo dedicado de Recolección',
          ),
        ),
      );
    }
    try {
      _platformSprite = await Sprite.load(
        'minigame-elements/recoleccion_platform_v1.png',
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.recoleccion_art',
          context: ErrorDescription(
            'al cargar la plataforma dedicada de Recolección',
          ),
        ),
      );
    }
    _coinSprite = await Sprite.load('ui/coin_star_v1.png');
    _heartSprite = await Sprite.load('ui/heart.png');
    await _topBanner.load();
    _elementSprites.addAll([
      await Sprite.load('minigame-elements/Apple.png'),
      await Sprite.load('minigame-elements/Banana.png'),
      await Sprite.load('minigame-elements/Grapes.png'),
      await Sprite.load('minigame-elements/Strawberry.png'),
    ]);
    px = (size.x - playerWidth) / 2;
    py = _groundY - playerHeight;
  }

  void _start() {
    _started = true;
  }

  void _moveTo(double x) {
    _dragX = x;
    px = (_dragX - playerWidth / 2).clamp(0.0, size.x - playerWidth);
  }

  void _spawnItem() {
    final roll = _random.nextDouble();
    late final _ItemType type;
    late final Sprite? sprite;
    if (roll < dislikeChance) {
      type = _ItemType.dislike;
      sprite = null;
    } else if (roll < dislikeChance + likeChance) {
      type = _ItemType.like;
      sprite = null;
    } else if (roll < dislikeChance + likeChance + coinChance) {
      type = _ItemType.coin;
      sprite = _coinSprite;
    } else {
      type = _ItemType.fruit;
      sprite = _elementSprites[_random.nextInt(_elementSprites.length)];
    }
    if (sprite == null && type != _ItemType.like && type != _ItemType.dislike) {
      return;
    }

    _items.add(
      _FallingItem(
        itemRadius + _random.nextDouble() * (size.x - itemRadius * 2),
        -itemRadius,
        155 + _random.nextDouble() * 100 + min(_score * 2.0, 150),
        sprite,
        itemRadius * 2,
        type: type,
      ),
    );
  }

  @override
  void update(double dt) {
    _ntiAvatar.update(dt);
    if (!_started || _gameOver) return;

    _spawnTimer += dt;
    while (_spawnTimer >= spawnInterval) {
      _spawnTimer -= spawnInterval;
      _spawnItem();
    }

    final playerRect = Rect.fromLTWH(px, py, playerWidth, playerHeight);
    for (final item in _items) {
      item.phase += dt * 3;
      item.y += item.speed * dt;
      final itemRect = Rect.fromCircle(
        center: Offset(item.x, item.y),
        radius: item.size / 2,
      );
      if (playerRect.overlaps(itemRect)) {
        item.caught = true;
        item.y = _groundY + item.size;
        switch (item.type) {
          case _ItemType.coin:
            CoinStore.instance.add(1);
            break;
          case _ItemType.fruit:
          case _ItemType.like:
            _score++;
            if (_score % 20 == 0) {
              _earnedCoins++;
              _pendingCoins++;
            }
            break;
          case _ItemType.dislike:
            _lives = max(0, _lives - 1);
            break;
        }
      }
    }

    final missedItems = _items
        .where(
          (item) =>
              item.type == _ItemType.fruit &&
              !item.caught &&
              item.y - item.size / 2 > _groundY,
        )
        .length;
    if (missedItems > 0) {
      _lives = max(0, _lives - missedItems);
    }
    _items.removeWhere((item) => item.y - item.size / 2 > _groundY);
    if (_lives == 0) {
      CoinStore.instance.add(_pendingCoins);
      _pendingCoins = 0;
      _gameOver = true;
      _items.clear();
    }
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final backgroundSprite = _backgroundSprite;
    if (backgroundSprite != null) {
      backgroundSprite.render(canvas, position: Vector2.zero(), size: size);
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

    _drawGround(canvas);

    for (final item in _items) {
      final screenY = item.y + sin(item.phase) * 3;
      switch (item.type) {
        case _ItemType.like:
          _drawEmoji(canvas, '💜', item.x, screenY, item.size);
          break;
        case _ItemType.dislike:
          _drawEmoji(canvas, '💔', item.x, screenY, item.size);
          break;
        case _ItemType.fruit:
        case _ItemType.coin:
          final sprite = item.sprite;
          if (sprite != null) {
            sprite.render(
              canvas,
              position: Vector2(
                item.x - item.size / 2,
                screenY - item.size / 2,
              ),
              size: Vector2.all(item.size),
            );
          }
          break;
      }
    }

    _ntiAvatar.render(
      canvas,
      position: Vector2(px, py),
      size: Vector2(playerWidth, playerHeight),
      visualOffsetY: ntiVisualGroundOffset,
    );

    _topBanner.render(canvas, size, gameName: 'Recolección', score: _score);
    _drawLives(canvas);

    if (!_started) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);
      _drawCenteredText(canvas, 'Recolección', size.y / 2 - 60, 36);
      _drawCenteredText(
        canvas,
        'Drag to start',
        size.y / 2,
        20,
        color: Colors.white70,
      );
    }

    if (_gameOver) {
      canvas.drawRect(rect, Paint()..color = Colors.black54);
      _drawCenteredText(canvas, 'Fin de la partida', size.y / 2 - 90, 34);
      _drawCenteredText(canvas, 'Puntuación: $_score', size.y / 2 - 30, 22);
      _drawCenteredText(
        canvas,
        'Monedas ganadas: $_earnedCoins',
        size.y / 2 + 5,
        20,
        color: Colors.white70,
      );
      _drawCenteredText(
        canvas,
        'Toca para salir',
        size.y / 2 + 45,
        20,
        color: Colors.white70,
      );
    }
  }

  void _drawGround(Canvas canvas) {
    final visualWidth = max(0.0, size.x - platformSideMargin * 2);
    const visualHeight = platformVisualHeight;
    final platform = _platformSprite;
    if (platform != null) {
      platform.render(
        canvas,
        position: Vector2(platformSideMargin, _groundY),
        size: Vector2(visualWidth, visualHeight),
      );
      return;
    }

    // Fallback técnico solamente: conserva la superficie visual sin tocar el
    // suelo lógico si por alguna razón el asset no puede cargarse.
    final fallback = RRect.fromRectAndRadius(
      Rect.fromLTWH(platformSideMargin, _groundY, visualWidth, visualHeight),
      const Radius.circular(14),
    );
    canvas.drawRRect(fallback, Paint()..color = const Color(0xFF8C5AC7));
    canvas.drawRRect(
      fallback,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFE7B454),
    );
  }

  void _drawEmoji(
    Canvas canvas,
    String emoji,
    double centerX,
    double centerY,
    double hitboxSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: hitboxSize * 0.92, height: 1),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(centerX - painter.width / 2, centerY - painter.height / 2),
    );
  }

  void _drawLives(Canvas canvas) {
    const heartSize = 26.0;
    const gap = 4.0;
    final totalWidth = _lives * heartSize + max(0, _lives - 1) * gap;
    final startX = size.x - CoinBalanceHud.margin - totalWidth;
    final top = _topBanner.bottom(size) + 4;

    for (var i = 0; i < _lives; i++) {
      _heartSprite?.render(
        canvas,
        position: Vector2(startX + i * (heartSize + gap), top),
        size: Vector2.all(heartSize),
      );
    }
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    double y,
    double fontSize, {
    Color color = Colors.white,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.x - 32);
    tp.paint(canvas, Offset((size.x - tp.width) / 2, y));
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_gameOver) return true;
    _start();
    _moveTo(event.localPosition.x);
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (_gameOver) return true;
    _moveTo(_dragX + event.localDelta.x);
    return true;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (_gameOver) {
      removeFromParent();
      CoinStore.instance.add(_earnedCoins);
      return true;
    }
    _start();
    _moveTo(event.localPosition.x);
    return true;
  }
}
