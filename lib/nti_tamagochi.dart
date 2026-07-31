import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/presentation/outfit_debug_selector.dart';
import 'package:flutter_application_1/features/customization/presentation/room_background.dart';
import 'package:flutter_application_1/features/customization/presentation/theme_debug_selector.dart';
import 'package:flutter_application_1/features/store/presentation/store_access_button.dart';
import 'package:flutter_application_1/gui.dart';

class NtiTamagochi extends FlameGame {
  static const storeOverlayId = 'store';

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  var nti = Nti();
  var toolBar = ToolBar();
  late final RoomBackground roomBackground = RoomBackground(
    theme: defaultThemeOptions.first,
  );
  late final StoreAccessButton storeAccessButton = StoreAccessButton(
    onPressed: openStore,
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
    add(storeAccessButton);
    if (kDebugMode) {
      add(ThemeDebugSelector(background: roomBackground));
      add(OutfitDebugSelector(nti: nti));
    }
  }

  void openStore() {
    if (overlays.isActive(storeOverlayId)) {
      return;
    }
    pauseEngine();
    overlays.add(storeOverlayId);
  }

  void closeStore() {
    overlays.remove(storeOverlayId);
    resumeEngine();
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
