import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter_application_1/actors/player.dart';

class NtiTamagochi extends FlameGame{

  @override
  FutureOr<void> onLoad() async{
    await images.loadAllImages();

    add(Player());
  }
}