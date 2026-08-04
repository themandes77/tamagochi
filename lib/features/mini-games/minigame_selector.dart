import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';

class MinigameSelector extends PositionComponent with TapCallbacks {
  final VoidCallback? onPlaySaltoEstelar;
  final VoidCallback? onPlayRecoleccion;

  static const double backButtonSize = 48;
  static const double topInset = 24;
  static const double controlLift = 14;
  static const double cardSpacing = -10;
  static const double upcomingSpacing = -40;

  Sprite? _headerSprite;
  Sprite? _backgroundSprite;
  Sprite? _titleSprite;
  Sprite? _backSprite;
  Sprite? _coinFrameSprite;
  Sprite? _coinStarSprite;
  Sprite? _saltoEstelarSprite;
  Sprite? _recoleccionSprite;
  Sprite? _upcomingSprite;
  Sprite? _playSprite;
  Sprite? _rewardSprite;

  MinigameSelector({this.onPlaySaltoEstelar, this.onPlayRecoleccion});

  @override
  FutureOr<void> onLoad() async {
    size = findGame()!.size;
    _backgroundSprite = await Sprite.load(
      'backgrounds/minigames_background_v1.png',
    );
    _headerSprite = await Sprite.load('ui/store_header_panel_v1.png');
    _titleSprite = await Sprite.load('ui/minijuegos_titulo_v1.png');
    _backSprite = await Sprite.load('ui/store_back_button_v1.png');
    _coinFrameSprite = await Sprite.load('ui/coin_balance_frame_v1.png');
    _coinStarSprite = await Sprite.load('ui/coin_star_v1.png');
    _saltoEstelarSprite = await Sprite.load('ui/salto_estelar.png');
    _recoleccionSprite = await Sprite.load('ui/recoleccion.png');
    _upcomingSprite = await Sprite.load('ui/proximament.png');
    _playSprite = await Sprite.load('ui/play_button.png');
    _rewardSprite = await Sprite.load('ui/reward_label.png');
  }

  @override
  void render(Canvas canvas) {
    _backgroundSprite?.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(size.x, size.y),
    );

    _drawHeader(canvas);
    _drawBackButton(canvas);
    _drawCoinBalance(canvas);

    _drawSaltoEstelar(canvas);
    _drawRecoleccion(canvas);
    _drawUpcoming(canvas);
  }

  double get _headerHeight => size.x * 428 / 2048;

  Rect get _backRect => Rect.fromLTWH(
    12,
    topInset - controlLift + (_headerHeight - backButtonSize) / 2,
    backButtonSize,
    backButtonSize,
  );

  Rect get _coinFrameRect => Rect.fromLTWH(
    size.x - 106,
    topInset - controlLift + (_headerHeight - 34) / 2,
    94,
    34,
  );

  void _drawHeader(Canvas canvas) {
    _headerSprite?.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(size.x, _headerHeight + topInset),
    );

    final titleWidth = min(size.x * 0.62, 280.0);
    final titleHeight = titleWidth * 1024 / 1536;
    _titleSprite?.render(
      canvas,
      position: Vector2(
        (size.x - titleWidth) / 2,
        topInset + (_headerHeight - titleHeight) / 2,
      ),
      size: Vector2(titleWidth, titleHeight),
    );
  }

  void _drawBackButton(Canvas canvas) {
    final rect = _backRect;
    _backSprite?.render(
      canvas,
      position: Vector2(rect.left, rect.top),
      size: Vector2(rect.width, rect.height),
    );
  }

  void _drawCoinBalance(Canvas canvas) {
    final frame = _coinFrameRect;
    _coinFrameSprite?.render(
      canvas,
      position: Vector2(frame.left, frame.top),
      size: Vector2(frame.width, frame.height),
    );

    const starSize = 22.0;
    _coinStarSprite?.render(
      canvas,
      position: Vector2(
        frame.left + 4,
        frame.top + (frame.height - starSize) / 2,
      ),
      size: Vector2(starSize, starSize),
    );

    final balance = TextPainter(
      text: TextSpan(
        text: '${CoinStore.instance.balance}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    balance.paint(
      canvas,
      Offset(frame.left + 33, frame.top + (frame.height - balance.height) / 2),
    );
  }

  double get _saltoCardWidth => min(size.x * 0.96, 400.0);

  Rect get _saltoContentRect {
    final width = min(size.x * 0.9, 360.0);
    final height = width * 1024 / 1536;
    return Rect.fromLTWH(
      (size.x - width) / 2,
      topInset + _headerHeight + 12,
      width,
      height,
    );
  }

  Rect get _saltoCardRect {
    final width = _saltoCardWidth;
    final height = width * 1024 / 1536;
    return Rect.fromLTWH(
      (size.x - width) / 2,
      topInset + _headerHeight + 12,
      width,
      height,
    );
  }

  Rect get _recoleccionCardRect {
    final card = _saltoCardRect;
    return card.translate(0, card.height + cardSpacing);
  }

  Rect get _recoleccionContentRect {
    final content = _saltoContentRect;
    return content.translate(0, content.height + cardSpacing);
  }

  Rect get _upcomingCardRect {
    final previous = _recoleccionCardRect;
    final width = _saltoCardWidth * 0.88;
    final height = width * 700 / 1024;
    return Rect.fromLTWH(
      (size.x - width) / 2,
      previous.bottom + upcomingSpacing,
      width,
      height,
    );
  }

  Rect _playRectFor(Rect card) {
    const width = 120.0;
    const height = width * 375 / 666;
    return Rect.fromLTWH(
      card.right - width - 10,
      card.bottom - height - 25,
      width,
      height,
    );
  }

  Rect _rewardRectFor(Rect play) {
    const width = 90.0;
    const height = width * 375 / 666;
    return Rect.fromLTWH(
      play.right - width - 17,
      play.top - height + 25,
      width,
      height,
    );
  }

  Rect get _saltoPlayRect {
    return _playRectFor(_saltoContentRect);
  }

  Rect get _saltoRewardRect {
    return _rewardRectFor(_saltoPlayRect);
  }

  Rect get _recoleccionPlayRect {
    final card = _recoleccionCardRect;
    const width = 120.0;
    const height = width * 375 / 666;
    return Rect.fromLTWH(
      card.right - width - 28,
      card.bottom - height - 45,
      width,
      height,
    );
  }

  Rect get _recoleccionRewardRect {
    return _rewardRectFor(_recoleccionPlayRect);
  }

  void _drawSaltoEstelar(Canvas canvas) {
    final card = _saltoCardRect;
    final content = _saltoContentRect;
    _saltoEstelarSprite?.render(
      canvas,
      position: Vector2(card.left, card.top),
      size: Vector2(card.width, card.height),
    );

    canvas.save();
    canvas.clipRect(card);

    final title = TextPainter(
      text: const TextSpan(
        text: 'Salto\nEstelar',
        style: TextStyle(
          color: Color(0xff493374),
          fontFamily: 'Fredoka',
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    title.paint(canvas, Offset(content.right - 110, content.top + 60));

    final reward = _saltoRewardRect;
    _rewardSprite?.render(
      canvas,
      position: Vector2(reward.left, reward.top),
      size: Vector2(reward.width, reward.height),
    );

    final play = _saltoPlayRect;
    _playSprite?.render(
      canvas,
      position: Vector2(play.left, play.top),
      size: Vector2(play.width, play.height),
    );
    canvas.restore();
  }

  void _drawRecoleccion(Canvas canvas) {
    final card = _recoleccionCardRect;
    final content = _recoleccionContentRect;
    _recoleccionSprite?.render(
      canvas,
      position: Vector2(card.left, card.top),
      size: Vector2(card.width, card.height),
    );

    canvas.save();
    canvas.clipRect(card);

    final title = TextPainter(
      text: const TextSpan(
        text: 'Recolección',
        style: TextStyle(
          color: Color(0xff493374),
          fontFamily: 'Fredoka',
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150);
    title.paint(canvas, Offset(content.right - 147, content.top + 90));

    final play = _recoleccionPlayRect;
    final reward = _recoleccionRewardRect;
    _rewardSprite?.render(
      canvas,
      position: Vector2(reward.left - 10, reward.top),
      size: Vector2(reward.width, reward.height),
    );
    _playSprite?.render(
      canvas,
      position: Vector2(play.left - 10, play.top),
      size: Vector2(play.width, play.height),
    );
    canvas.restore();
  }

  void _drawUpcoming(Canvas canvas) {
    final card = _upcomingCardRect;
    _upcomingSprite?.render(
      canvas,
      position: Vector2(card.left, card.top),
      size: Vector2(card.width, card.height),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final local = event.localPosition.toOffset();

    if (_backRect.contains(local)) {
      removeFromParent();
      return true;
    }

    if (_saltoPlayRect.contains(local)) {
      onPlaySaltoEstelar?.call();
      return true;
    }

    if (_recoleccionPlayRect.contains(local)) {
      onPlayRecoleccion?.call();
      return true;
    }

    return false;
  }
}
