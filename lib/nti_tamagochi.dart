import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/level.dart';

class NtiTamagochi extends FlameGame{
  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  @override
  FutureOr<void> onLoad() async{
    await images.loadAllImages();

    add(Player());
    add(Level());
  }
}