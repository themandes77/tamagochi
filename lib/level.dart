
import 'dart:async';
import 'package:flame/components.dart';

class Level extends World{
  @override
  FutureOr<void> onLoad() async {
    final soap = await Sprite.load("soap.png");
    final component = SpriteComponent(
      sprite: soap,
      size: Vector2.all(499),
      anchor: Anchor.center,
    );
    component.position = Vector2(200, 600);
    add(component);
  
    return super.onLoad();
  }
}