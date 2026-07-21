import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';

enum PlayerState { idle }

class Player extends SpriteAnimationGroupComponent with HasGameReference<NtiTamagochi> {
  late final SpriteAnimation idleAnimation;
  final double stepTime = 0.05;

  @override
  FutureOr<void> onLoad() async {
      final sprite = await Sprite.load("nti.png");
      final component = SpriteComponent(
        sprite: sprite,
        size: Vector2(224,280),
        anchor: Anchor.center,
      );
      component.position = Vector2(200, 400);
      add(component);
    
    return super.onLoad();
  }
}