import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/mini-games/minigame_selector.dart';
import 'package:flutter_application_1/features/mini-games/recoleccion.dart';
import 'package:flutter_application_1/features/mini-games/trepa_nubes.dart';
import 'package:flutter_application_1/gui.dart';

class NtiTamagochi extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  var nti = Nti();
  var toolBar = ToolBar();
  double _tickAccumulator = 0;
  static const double tickInterval = 2;

  void openSelector() {
    add(
      MinigameSelector(
        onPlaySaltoEstelar: () {
          removeWhere((c) => c is MinigameSelector);
          add(TrepaNubes());
        },
        onPlayRecoleccion: () {
          removeWhere((c) => c is MinigameSelector);
          add(Recoleccion());
        },
      ),
    );
  }

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    nti.toolBar = toolBar;
    add(nti);
    add(toolBar);
    add(Hud(nti));
    add(CoinDisplay());
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
