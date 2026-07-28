import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/gui.dart';

class NtiTamagochi extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  var nti = Nti();
  var toolBar = ToolBar();
  double _tickAccumulator = 0;
  static const double tickInterval = 2;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    nti.toolBar = toolBar;
    add(nti);
    add(toolBar);
    add(Hud(nti));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _tickAccumulator += dt;
    if (_tickAccumulator >= tickInterval) {
      nti.tick();
      _tickAccumulator -= tickInterval;
    }
  }
}
