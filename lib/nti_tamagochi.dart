import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/presentation/outfit_debug_selector.dart';
import 'package:flutter_application_1/features/customization/presentation/room_background.dart';
import 'package:flutter_application_1/features/customization/presentation/theme_debug_selector.dart';
import 'package:flutter_application_1/gui.dart';

class NtiTamagochi extends FlameGame {
  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  var nti = Nti();
  var toolBar = ToolBar();
  late final RoomBackground roomBackground = RoomBackground(
    theme: defaultThemeOptions.first,
  );
  double _tickAccumulator = 0;
  static const double tickInterval = 2;

  @override
  FutureOr<void> onLoad() async {
    await images.loadAllImages();

    nti.toolBar = toolBar;
    add(roomBackground);
    add(nti);
    add(toolBar);
    add(Hud(nti));
    if (kDebugMode) {
      add(ThemeDebugSelector(background: roomBackground));
      add(OutfitDebugSelector(nti: nti));
    }
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
