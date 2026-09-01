import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/mini-games/coin_balance_hud.dart';

class MinigameTopBanner {
  static const double _visibleTop = 8.0;
  static const double _spriteVisibleTopFactor = 331 / 1024;
  static const double _spriteVisibleBottomFactor = 602 / 1024;
  final double gameNameFontSize;
  final double scoreFontSize;
  final double widthScale;
  final double gameNameCenterFactor;
  final CoinBalanceHud _coinBalanceHud;
  Sprite? _bannerSprite;

  MinigameTopBanner({
    this.gameNameFontSize = 13,
    this.scoreFontSize = 15,
    this.widthScale = 1.08,
    this.gameNameCenterFactor = 0.27,
    double coinFontSize = 16,
  }) : _coinBalanceHud = CoinBalanceHud(fontSize: coinFontSize);

  FutureOr<void> load() async {
    _bannerSprite = await Sprite.load(
      'minigame-elements/mingame_top_banner_v1.png',
    );
    await _coinBalanceHud.load();
  }

  double bottom(Vector2 gameSize) {
    final bannerWidth = gameSize.x * widthScale;
    final bannerHeight = bannerWidth * 1024 / 1536;
    final bannerY = _bannerY(bannerHeight);
    return bannerY + bannerHeight * _spriteVisibleBottomFactor;
  }

  void render(
    Canvas canvas,
    Vector2 gameSize, {
    required String gameName,
    required int score,
  }) {
    final banner = _bannerSprite;
    if (banner == null) return;

    final bannerWidth = gameSize.x * widthScale;
    final bannerHeight = bannerWidth * 1024 / 1536;
    final bannerX = (gameSize.x - bannerWidth) / 2;
    final bannerY = _bannerY(bannerHeight);
    banner.render(
      canvas,
      position: Vector2(bannerX, bannerY),
      size: Vector2(bannerWidth, bannerHeight),
    );

    final contentY = bannerY + bannerHeight * 0.454;
    final textScale = (gameSize.x / 390).clamp(0.85, 1.4);
    _drawText(
      canvas,
      gameName,
      centerX: bannerX + bannerWidth * gameNameCenterFactor,
      centerY: contentY,
      fontSize: gameNameFontSize * textScale,
    );
    _drawText(
      canvas,
      'Puntuación\n$score',
      centerX: bannerX + bannerWidth * 0.49,
      centerY: contentY,
      fontSize: scoreFontSize * textScale,
    );
    _coinBalanceHud.render(
      canvas,
      gameSize,
      left: bannerX + bannerWidth * 0.79 - CoinBalanceHud.width / 2,
      top: contentY - CoinBalanceHud.height / 2,
    );
  }

  double _bannerY(double bannerHeight) {
    // El PNG incluye ~32% de padding transparente arriba. El offset negativo
    // es intencional: anclamos el borde VISUAL del banner a una posición
    // estable dentro del SafeArea, independientemente del ancho del teléfono.
    return _visibleTop - bannerHeight * _spriteVisibleTopFactor;
  }

  void _drawText(
    Canvas canvas,
    String text, {
    required double centerX,
    required double centerY,
    required double fontSize,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF493374),
          fontFamily: 'Fredoka',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 0.95,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(centerX - painter.width / 2, centerY - painter.height / 2),
    );
  }
}
