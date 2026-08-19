import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';

class MinigameSelector extends PositionComponent
    with TapCallbacks, DragCallbacks {
  MinigameSelector({this.onPlaySaltoEstelar, this.onPlayRecoleccion});

  final VoidCallback? onPlaySaltoEstelar;
  final VoidCallback? onPlayRecoleccion;

  static const double _referenceCardWidth = 400;
  static const double _topInset = 24;
  static const double _contentTopGap = 12;
  static const double _contentBottomGap = 16;
  static const double _cardSpacing = -10;
  static const double _upcomingSpacing = -40;

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

  double _scrollOffset = 0;
  bool _draggingContent = false;

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
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    _scrollOffset = _scrollOffset.clamp(0.0, _maxScrollOffset);
  }

  @override
  void render(Canvas canvas) {
    _backgroundSprite?.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(size.x, size.y),
    );

    // Header y controles permanecen fijos. Sólo las cards pueden desplazarse
    // cuando el alto disponible de verdad no alcanza.
    _drawHeader(canvas);
    _drawBackButton(canvas);
    _drawCoinBalance(canvas);

    final viewport = _contentViewport;
    canvas.save();
    canvas.clipRect(viewport);
    canvas.translate(0, -_scrollOffset);
    _drawSaltoEstelar(canvas);
    _drawRecoleccion(canvas);
    _drawUpcoming(canvas);
    canvas.restore();
  }

  double get _headerHeight =>
      (size.x * 428 / 2048).clamp(58.0, 110.0).toDouble();

  double get _controlSize => (size.x * 0.125).clamp(40.0, 48.0).toDouble();

  double get _cardWidth => min(size.x * 0.96, _referenceCardWidth);

  double get _cardScale => (_cardWidth / _referenceCardWidth).clamp(0.5, 1.0);

  double get _cardHeight => _cardWidth * 1024 / 1536;

  double get _contentTop => _topInset + _headerHeight + _contentTopGap;

  Rect get _contentViewport =>
      Rect.fromLTWH(0, _contentTop, size.x, max(0.0, size.y - _contentTop));

  Rect get _backRect {
    final control = _controlSize;
    return Rect.fromLTWH(
      12,
      _topInset - 14 + (_headerHeight - control) / 2,
      control,
      control,
    );
  }

  Rect get _coinFrameRect {
    final height = (34 * _cardScale).clamp(30.0, 34.0).toDouble();
    final width = (94 * _cardScale).clamp(82.0, 94.0).toDouble();
    return Rect.fromLTWH(
      size.x - width - 12,
      _topInset - 14 + (_headerHeight - height) / 2,
      width,
      height,
    );
  }

  Rect get _saltoCardRect => Rect.fromLTWH(
    (size.x - _cardWidth) / 2,
    _contentTop,
    _cardWidth,
    _cardHeight,
  );

  Rect get _saltoContentRect {
    final width = min(size.x * 0.9, 360.0);
    final height = width * 1024 / 1536;
    return Rect.fromLTWH((size.x - width) / 2, _contentTop, width, height);
  }

  Rect get _recoleccionCardRect =>
      _saltoCardRect.translate(0, _cardHeight + _cardSpacing * _cardScale);

  Rect get _recoleccionContentRect {
    final content = _saltoContentRect;
    return content.translate(0, content.height + _cardSpacing * _cardScale);
  }

  Rect get _upcomingCardRect {
    final previous = _recoleccionCardRect;
    final width = _cardWidth * 0.88;
    final height = width * 700 / 1024;
    return Rect.fromLTWH(
      (size.x - width) / 2,
      previous.bottom + _upcomingSpacing * _cardScale,
      width,
      height,
    );
  }

  double get _naturalContentBottom =>
      _upcomingCardRect.bottom + _contentBottomGap * _cardScale;

  double get _maxScrollOffset =>
      max(0.0, _naturalContentBottom - _contentViewport.bottom);

  Rect _visibleRect(Rect naturalRect) =>
      naturalRect.translate(0, -_scrollOffset);

  // El arte dedica aproximadamente el 56% izquierdo a ilustración y el resto
  // a información. Un eje al 75% centra título, recompensa y JUGAR dentro de
  // esa zona sin empujarlos contra el borde derecho.
  double _infoCenterX(Rect card) => card.left + card.width * 0.75;

  Rect _playRectFor(Rect card, {required double bottomInset}) {
    final scale = _cardScale;
    final width = 120 * scale;
    final height = width * 375 / 666;
    return Rect.fromCenter(
      center: Offset(
        _infoCenterX(card),
        card.bottom - bottomInset * scale - height / 2,
      ),
      width: width,
      height: height,
    );
  }

  Rect _rewardRectFor(Rect card, Rect play) {
    final scale = _cardScale;
    final width = 90 * scale;
    final height = width * 375 / 666;
    return Rect.fromCenter(
      center: Offset(_infoCenterX(card), play.top - height / 2 + 25 * scale),
      width: width,
      height: height,
    );
  }

  // Salto Estelar tiene el título en dos líneas; subimos ligeramente el
  // bloque de acciones para equilibrar el espacio vertical de su zona de info.
  // Recolección conserva su posición aprobada.
  Rect get _saltoPlayRect => _playRectFor(_saltoContentRect, bottomInset: 35);
  Rect get _saltoRewardRect =>
      _rewardRectFor(_saltoContentRect, _saltoPlayRect);

  Rect get _recoleccionPlayRect =>
      _playRectFor(_recoleccionContentRect, bottomInset: 45);

  Rect get _recoleccionRewardRect =>
      _rewardRectFor(_recoleccionContentRect, _recoleccionPlayRect);

  void _drawHeader(Canvas canvas) {
    _headerSprite?.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2(size.x, _headerHeight + _topInset),
    );

    final titleWidth = min(size.x * 0.62, 280.0);
    final titleHeight = titleWidth * 1024 / 1536;
    _titleSprite?.render(
      canvas,
      position: Vector2(
        (size.x - titleWidth) / 2,
        _topInset + (_headerHeight - titleHeight) / 2,
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

    final starSize = min(22.0 * _cardScale, frame.height - 8);
    _coinStarSprite?.render(
      canvas,
      position: Vector2(
        frame.left + 4,
        frame.top + (frame.height - starSize) / 2,
      ),
      size: Vector2(starSize, starSize),
    );

    final fontSize = (16 * _cardScale).clamp(13.0, 16.0).toDouble();
    final balance = TextPainter(
      text: TextSpan(
        text: '${CoinStore.instance.balance}',
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: max(24.0, frame.width - 34));
    balance.paint(
      canvas,
      Offset(frame.left + 30, frame.top + (frame.height - balance.height) / 2),
    );
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
    final scale = _cardScale;
    final title = TextPainter(
      text: TextSpan(
        text: 'Salto\nEstelar',
        style: TextStyle(
          color: const Color(0xff493374),
          fontFamily: 'Fredoka',
          fontSize: 25 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150 * scale);
    title.paint(
      canvas,
      Offset(_infoCenterX(content) - title.width / 2, content.top + 60 * scale),
    );

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
    final scale = _cardScale;
    final title = TextPainter(
      text: TextSpan(
        text: 'Recolección',
        style: TextStyle(
          color: const Color(0xff493374),
          fontFamily: 'Fredoka',
          fontSize: 22 * scale,
          fontWeight: FontWeight.w700,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 150 * scale);
    title.paint(
      canvas,
      Offset(_infoCenterX(content) - title.width / 2, content.top + 90 * scale),
    );

    final play = _recoleccionPlayRect;
    final reward = _recoleccionRewardRect;
    _rewardSprite?.render(
      canvas,
      position: Vector2(reward.left, reward.top),
      size: Vector2(reward.width, reward.height),
    );
    _playSprite?.render(
      canvas,
      position: Vector2(play.left, play.top),
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

    if (!_contentViewport.contains(local)) {
      return false;
    }

    if (_visibleRect(_saltoPlayRect).contains(local)) {
      onPlaySaltoEstelar?.call();
      return true;
    }

    if (_visibleRect(_recoleccionPlayRect).contains(local)) {
      onPlayRecoleccion?.call();
      return true;
    }

    return false;
  }

  @override
  bool onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    final canScroll = _maxScrollOffset > 0;
    _draggingContent =
        canScroll && _contentViewport.contains(event.localPosition.toOffset());
    return _draggingContent;
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    if (!_draggingContent) {
      return false;
    }
    _scrollOffset = (_scrollOffset - event.localDelta.y)
        .clamp(0.0, _maxScrollOffset)
        .toDouble();
    return true;
  }

  @override
  bool onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    final wasDragging = _draggingContent;
    _draggingContent = false;
    return wasDragging;
  }

  @override
  bool onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    final wasDragging = _draggingContent;
    _draggingContent = false;
    return wasDragging;
  }
}
