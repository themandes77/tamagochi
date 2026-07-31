import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_overlay.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();

  final storeController = StoreController(
    repository: InMemoryStoreRepository(),
  );
  await storeController.initialize();

  final game = NtiTamagochi(
    initialOutfit: storeController.selectedOutfit,
    initialTheme: storeController.selectedTheme,
  );
  storeController.addListener(() {
    unawaited(
      game.applyCustomization(
        outfit: storeController.selectedOutfit,
        theme: storeController.selectedTheme,
      ),
    );
  });

  runApp(NtiApp(game: game, storeController: storeController));
}

class NtiApp extends StatelessWidget {
  const NtiApp({required this.game, required this.storeController, super.key});

  final NtiTamagochi game;
  final StoreController storeController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NT Tamagochi',
      home: GameWidget<NtiTamagochi>(
        game: game,
        overlayBuilderMap: {
          NtiTamagochi.storeOverlayId: (context, game) {
            return StoreOverlay(
              controller: storeController,
              onClose: game.closeStore,
            );
          },
        },
      ),
    );
  }
}
