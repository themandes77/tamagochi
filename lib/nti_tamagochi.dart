import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/customization/presentation/outfit_debug_selector.dart';
import 'package:flutter_application_1/features/customization/presentation/room_background.dart';
import 'package:flutter_application_1/features/customization/presentation/theme_debug_selector.dart';
import 'package:flutter_application_1/features/store/presentation/store_access_button.dart';
import 'package:flutter_application_1/gui.dart';

class NtiTamagochi extends FlameGame {
  NtiTamagochi({
    NtiOutfit initialOutfit = NtiOutfit.original,
    ThemeOption? initialTheme,
  }) : nti = Nti(outfit: initialOutfit),
       _initialTheme = initialTheme ?? defaultThemeOptions.first;

  static const storeOverlayId = 'store';

  final ThemeOption _initialTheme;

  @override
  Color backgroundColor() => const Color(0xFFeeeeee);

  final Nti nti;
  var toolBar = ToolBar();
  late final RoomBackground roomBackground = RoomBackground(
    theme: _initialTheme,
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

  Future<void> applyCustomization({
    required NtiOutfit outfit,
    required ThemeOption theme,
  }) async {
    if (!isLoaded) {
      return;
    }
    if (nti.outfit != outfit) {
      await nti.wear(outfit);
    }
    await roomBackground.setTheme(theme);
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
