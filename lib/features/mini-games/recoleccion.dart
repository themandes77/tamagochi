import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/features/mini-games/coin_balance_hud.dart';
import 'package:flutter_application_1/features/mini-games/minigame_top_banner.dart';

enum _ItemType { fruit, coin, like, dislike }

class _FallingItem {
  double x;
  double y;
  double speed;
  double phase;
  final Sprite sprite;
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
  static const double playerWidth = 54;
  static const double playerHeight = 68;
  static const double groundHeight = 90;
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
  );
  Sprite? _ntiSprite;
  Sprite? _coinSprite;
  Sprite? _heartSprite;
  Sprite? _likeSprite;
  Sprite? _dislikeSprite;

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

  double get _groundY => size.y - groundHeight;

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _ntiSprite = await Sprite.load('nti.png');
    _coinSprite = await Sprite.load('ui/coin_star_v1.png');
    _heartSprite = await Sprite.load('ui/heart.png');
    _likeSprite = await Sprite.load('minigame-elements/like.png');
    _dislikeSprite = await Sprite.load('minigame-elements/dislike.png');
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
      sprite = _dislikeSprite;
    } else if (roll < dislikeChance + likeChance) {
      type = _ItemType.like;
      sprite = _likeSprite;
    } else if (roll < dislikeChance + likeChance + coinChance) {
      type = _ItemType.coin;
      sprite = _coinSprite;
    } else {
      type = _ItemType.fruit;
      sprite = _elementSprites[_random.nextInt(_elementSprites.length)];
    }
    if (sprite == null) return;

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

    _drawGround(canvas);

    for (final item in _items) {
      final screenY = item.y + sin(item.phase) * 3;
      item.sprite.render(
        canvas,
        position: Vector2(item.x - item.size / 2, screenY - item.size / 2),
        size: Vector2.all(item.size),
      );
    }

    _ntiSprite?.render(
      canvas,
      position: Vector2(px, py),
      size: Vector2(playerWidth, playerHeight),
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
    final groundRect = Rect.fromLTWH(0, _groundY, size.x, groundHeight);
    final groundGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [const Color(0xFF6d9f52), const Color(0xFF365c3a)],
    );
    canvas.drawRect(
      groundRect,
      Paint()..shader = groundGradient.createShader(groundRect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, _groundY, size.x, 6),
      Paint()..color = const Color(0xFF9ed36a),
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
