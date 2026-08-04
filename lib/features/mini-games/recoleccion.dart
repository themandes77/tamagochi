import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';

class _FallingItem {
  double x;
  double y;
  double speed;
  double phase;
  final Sprite sprite;
  final double size;

  _FallingItem(this.x, this.y, this.speed, this.sprite, this.size) : phase = 0;
}

class Recoleccion extends PositionComponent
    with DragCallbacks, TapCallbacks, HasGameReference {
  static const double playerWidth = 54;
  static const double playerHeight = 68;
  static const double groundHeight = 90;
  static const double itemRadius = 18;
  static const double spawnInterval = 0.65;

  final Random _random = Random();
  final List<_FallingItem> _items = [];
  final List<Sprite> _elementSprites = [];
  Sprite? _ntiSprite;
  Sprite? _coinSprite;

  late double px;
  late double py;
  double _spawnTimer = 0;
  double _dragX = 0;
  int _collected = 0;
  bool _started = false;

  double get _groundY => size.y - groundHeight;

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _ntiSprite = await Sprite.load('nti.png');
    _coinSprite = await Sprite.load('ui/coin_star_v1.png');
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
    final useCoin = _random.nextDouble() < 0.35;
    final sprite = useCoin
        ? _coinSprite
        : _elementSprites[_random.nextInt(_elementSprites.length)];
    if (sprite == null) return;

    _items.add(
      _FallingItem(
        itemRadius + _random.nextDouble() * (size.x - itemRadius * 2),
        -itemRadius,
        155 + _random.nextDouble() * 100 + min(_collected * 2.0, 150),
        sprite,
        itemRadius * 2,
      ),
    );
  }

  @override
  void update(double dt) {
    if (!_started) return;

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
        item.y = _groundY + item.size;
        _collected++;
        CoinStore.instance.add(1);
      }
    }

    _items.removeWhere((item) => item.y - item.size / 2 > _groundY);
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

    _drawHud(canvas);

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

  void _drawHud(Canvas canvas) {
    final score = TextPainter(
      text: TextSpan(
        text: 'Monedas: $_collected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    score.paint(canvas, const Offset(20, 20));
    final hint = TextPainter(
      text: const TextSpan(
        text: 'Sin límite',
        style: TextStyle(color: Colors.white70, fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    hint.paint(canvas, Offset(size.x - hint.width - 20, 24));
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
    _start();
    _moveTo(event.localPosition.x);
    return true;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    _moveTo(_dragX + event.localDelta.x);
    return true;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    _start();
    _moveTo(event.localPosition.x);
    return true;
  }
}
