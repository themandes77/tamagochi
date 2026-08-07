import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/coins.dart';

class CoinBalanceHud {
  static const double width = 94;
  static const double height = 34;
  static const double margin = 12;

  Sprite? _frameSprite;
  Sprite? _coinSprite;

  FutureOr<void> load() async {
    _frameSprite = await Sprite.load('ui/coin_balance_frame_v1.png');
    _coinSprite = await Sprite.load('ui/coin_star_v1.png');
  }

  void render(Canvas canvas, Vector2 gameSize) {
    final left = gameSize.x - width - margin;
    const top = margin;

    _frameSprite?.render(
      canvas,
      position: Vector2(left, top),
      size: Vector2(width, height),
    );

    const starSize = 22.0;
    _coinSprite?.render(
      canvas,
      position: Vector2(left + 4, top + (height - starSize) / 2),
      size: Vector2.all(starSize),
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
      Offset(left + 33, top + (height - balance.height) / 2),
    );
  }
}
