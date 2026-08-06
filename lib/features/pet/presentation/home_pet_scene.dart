import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/presentation/pet_avatar_component.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

class HomePetScene extends FlameGame {
  HomePetScene({
    required this.petController,
    required this.storeController,
    required this.onPetTap,
    required this.onCleaningContactStarted,
    required this.onCleaningContactStopped,
    required this.onCleaningGestureEnded,
    required this.isCleaningToolSelected,
    required this.isCleaningActive,
  });

  final PetController petController;
  final StoreController storeController;
  final VoidCallback onPetTap;
  final bool Function() onCleaningContactStarted;
  final VoidCallback onCleaningContactStopped;
  final Future<void> Function() onCleaningGestureEnded;
  final bool Function() isCleaningToolSelected;
  final bool Function() isCleaningActive;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(
      PetAvatarComponent(
        controller: petController,
        storeController: storeController,
        onPetTap: onPetTap,
        onCleaningContactStarted: onCleaningContactStarted,
        onCleaningContactStopped: onCleaningContactStopped,
        onCleaningGestureEnded: onCleaningGestureEnded,
        isCleaningToolSelected: isCleaningToolSelected,
        isCleaningActive: isCleaningActive,
      ),
    );
  }
}
