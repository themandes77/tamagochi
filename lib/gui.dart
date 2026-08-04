import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/coins.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';

enum Tool { none, soap, food, games }
const double btnSize = 64;

class ToolBar extends PositionComponent with HasGameReference, TapCallbacks {
  Tool selected = Tool.soap;
  late Sprite soapSprite;
  late Sprite foodSprite;
  late Sprite gameSprite;
  static const double gap = 16;

  @override
    Future<void> onLoad() async {
      soapSprite = await Sprite.load('soap.png');
      foodSprite = await Sprite.load('fridge.png');
      gameSprite = await Sprite.load('controller.png');
      size = Vector2(btnSize * 3 + gap * 2, btnSize);
    }

  @override
    void onMount() {
      super.onMount();
      final gameSize = findGame()!.size;
      position = Vector2((gameSize.x - size.x) / 2, gameSize.y - size.y - 10);
    }

  @override
    void render(Canvas canvas) {
      super.render(canvas);

      _drawToolButton(canvas, 0, soapSprite, Tool.soap);
      _drawToolButton(canvas, 1, foodSprite, Tool.food);
      _drawToolButton(canvas, 2, gameSprite, Tool.games);
    }

  void _drawToolButton(Canvas canvas, int index, Sprite sprite, Tool tool) {
    final x = index * (btnSize + gap);
    final rect = Rect.fromLTWH(x, 0, btnSize, btnSize);

    canvas.drawRect(
        rect,
        Paint()..color = Colors.white,
        );

    if (selected == tool) {
      canvas.drawRect(
          rect,
          Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
          );
    }

    sprite.render(
        canvas,
        size: Vector2.all(btnSize - 8),
        position: Vector2(x + 4, 4),
        );
  }

  @override
    bool onTapDown(TapDownEvent event) {
      final local = event.localPosition.toOffset();
      for (var i = 0; i < 3; i++) {
        final x = i * (btnSize + gap);
        final rect = Rect.fromLTWH(x, 0, btnSize, btnSize);
        if (rect.contains(local)) {
          if (i == 2) {
            (findGame() as NtiTamagochi).openSelector();
            return true;
          }
          final tool = [Tool.soap, Tool.food, Tool.games][i];
          selected = tool;
          return true;
        }
      }
      return false;
    }
}

class Hud extends PositionComponent with HasGameReference, TapCallbacks {
  final Nti nt;
  bool collapsed = false;

  Hud(this.nt);

  @override
    void onMount() {
      super.onMount();
      _updateSize();
      _updatePosition();
    }

  void toggle() {
    collapsed = !collapsed;
    _updateSize();
    _updatePosition();
  }

  void _updateSize() {
    size = collapsed ? Vector2(200, 20) : Vector2(200, 88);
  }

  void _updatePosition() {
    final gameSize = findGame()!.size;
    position = Vector2((gameSize.x - size.x) / 2, 40);
  }

  @override
    void render(Canvas canvas) {
      super.render(canvas);

      _drawBar(canvas, 0, nt.hunger / 10, Colors.green);
      if (!collapsed) {
        _drawBar(canvas, 1, nt.cleanliness / 10, Colors.orange);
        _drawBar(canvas, 2, nt.energy / 10, Colors.yellow);
      }

      _drawToggleButton(canvas);
    }

  void _drawBar(Canvas canvas, int index, double fill, Color color) {
    final y = index * 22.0;
    canvas.drawRect(
        Rect.fromLTWH(0, y, 200, 18),
        Paint()..color = Colors.grey,
        );
    canvas.drawRect(
        Rect.fromLTWH(0, y, 200 * fill, 18),
        Paint()..color = color,
        );
    final percent = '${(fill * 100).toInt()}%';
    final tp = TextPainter(
        text: TextSpan(
          text: percent,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        textDirection: TextDirection.ltr,
        )..layout();
    tp.paint(canvas, Offset(180 - tp.width / 2, y + 3));
  }

  void _drawToggleButton(Canvas canvas) {
    final btnY = collapsed ? 0.0 : 66.0;
    canvas.drawRect(
        Rect.fromLTWH(0, btnY, 200, 20),
        Paint()..color = Colors.white,
        );

    final tp = TextPainter(
        text: TextSpan(
          text: collapsed ? '▼ Expand' : '▲ Collapse',
          style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
        textDirection: TextDirection.ltr,
        )..layout();
    tp.paint(canvas, Offset(100 - tp.width / 2, btnY + 3));
  }

  @override
    bool onTapDown(TapDownEvent event) {
      final btnY = collapsed ? 0.0 : 66.0;
      final btnRect = Rect.fromLTWH(0, btnY, 200, 20);
      if (btnRect.contains(event.localPosition.toOffset())) {
        toggle();
        return true;
      }
      return false;
    }
}

class CoinDisplay extends PositionComponent with HasGameReference {
  static const double boxWidth = 120;
  static const double boxHeight = 32;
  static const double coinRadius = 12;

  @override
    void onMount() {
      super.onMount();
      size = Vector2(boxWidth, boxHeight);
      final gameSize = findGame()!.size;
      position = Vector2(gameSize.x - boxWidth - 10, 8);
    }

  @override
    void update(double dt) {
      super.update(dt);
      final store = CoinStore.instance;
      if (store.message != null &&
          DateTime.now().difference(store.messageTime!).inSeconds >= 2) {
        store.message = null;
      }
    }

  @override
    void render(Canvas canvas) {
      final center = Offset(coinRadius + 4, boxHeight / 2);
      canvas.drawCircle(center, coinRadius, Paint()..color = const Color(0xFFf6c445));
      canvas.drawCircle(
          center,
          coinRadius,
          Paint()
          ..color = const Color(0xFFb8860b)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
          );

      final tp = TextPainter(
          text: TextSpan(
            text: '${CoinStore.instance.balance}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
              ),
            ),
          textDirection: TextDirection.ltr,
          )..layout();
      tp.paint(canvas, Offset(coinRadius * 2 + 10, (boxHeight - tp.height) / 2));

      final msg = CoinStore.instance.message;
      if (msg != null) {
        final msgTp = TextPainter(
            text: TextSpan(
              text: msg,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            textDirection: TextDirection.ltr,
            )..layout();
        final mw = msgTp.width + 16;
        final mx = size.x - mw - 4;
        canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(mx, boxHeight + 4, mw, msgTp.height + 8),
              const Radius.circular(8),
              ),
            Paint()..color = Colors.black87,
            );
        msgTp.paint(canvas, Offset(mx + 8, boxHeight + 8));
      }
    }
}
