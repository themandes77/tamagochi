import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/home/application/care_tool.dart';
import 'package:flutter_application_1/features/home/application/home_notice.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/pet/domain/care_action_result.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required this.petController,
    required this.lifecycleCoordinator,
  }) {
    petController.addListener(_forwardPetChange);
  }

  final PetController petController;
  final PetLifecycleCoordinator lifecycleCoordinator;

  CareTool _selectedTool = CareTool.none;
  bool _needsExpanded = true;
  bool _cleaningGestureHadContact = false;

  CareTool get selectedTool => _selectedTool;
  bool get needsExpanded => _needsExpanded;
  PetState get petState => petController.state;
  PetActivity get activity => petController.activity;
  double get health => petController.health;
  bool get isEating => activity == PetActivity.eating;
  bool get isCleaning => activity == PetActivity.cleaning;
  bool get isResting => activity == PetActivity.sleeping;
  bool get isPlaying => activity == PetActivity.playing;
  bool get canNavigateFromHome => !isEating && !isResting && !isPlaying;
  bool get canUseCareActions => !isEating && !isResting && !isPlaying;
  bool get canToggleResting => !isEating && !isPlaying;

  void toggleNeedsExpanded() {
    _needsExpanded = !_needsExpanded;
    notifyListeners();
  }

  Future<void> toggleTool(CareTool tool) async {
    if (tool == CareTool.none || !canUseCareActions) {
      return;
    }

    if (isCleaning) {
      await finishCleaningGesture();
    }

    _selectedTool = _selectedTool == tool ? CareTool.none : tool;
    notifyListeners();
  }

  HomeNotice? handlePetTap() {
    if (_selectedTool != CareTool.food) {
      return null;
    }

    final result = lifecycleCoordinator.startFeeding();
    return switch (result) {
      CareActionResult.alreadySatisfied => HomeNotice.alreadySatisfied,
      _ => null,
    };
  }

  HomeActionResult beginCleaningContact() {
    if (_selectedTool != CareTool.soap) {
      return const HomeActionResult.rejected();
    }

    if (isCleaning) {
      _cleaningGestureHadContact = true;
      return const HomeActionResult.accepted();
    }

    final result = lifecycleCoordinator.startCleaning();
    switch (result) {
      case CareActionResult.started:
        _cleaningGestureHadContact = true;
        return const HomeActionResult.accepted();
      case CareActionResult.alreadySatisfied:
        return const HomeActionResult.rejected(HomeNotice.alreadyClean);
      case CareActionResult.completed:
      case CareActionResult.interrupted:
      case CareActionResult.notNeeded:
      case CareActionResult.notEnoughEnergy:
      case CareActionResult.blockedByActivity:
      case CareActionResult.notInterruptible:
      case CareActionResult.noActiveAction:
        return const HomeActionResult.rejected();
    }
  }

  void suspendCleaningContact() {
    if (isCleaning) {
      petController.stopCleaning();
    }
  }

  Future<void> finishCleaningGesture() async {
    final shouldSave = _cleaningGestureHadContact;
    _cleaningGestureHadContact = false;
    if (isCleaning) {
      await lifecycleCoordinator.stopCleaning();
      return;
    }
    if (shouldSave) {
      await lifecycleCoordinator.saveCheckpoint();
    }
  }

  Future<bool> prepareForNavigation() async {
    if (!canNavigateFromHome) {
      return false;
    }
    await finishCleaningGesture();
    _clearSelectedTool();
    return true;
  }

  Future<void> prepareForPauseOverlay() async {
    await finishCleaningGesture();
  }

  Future<HomeActionResult> prepareForGameSelection() async {
    final allowed = await prepareForNavigation();
    if (!allowed) {
      return const HomeActionResult.rejected();
    }
    return const HomeActionResult.accepted();
  }

  Future<HomeActionResult> tryStartPlaying({
    required GameCostPolicy costPolicy,
  }) async {
    final result = await lifecycleCoordinator.startPlaying(
      costPolicy: costPolicy,
    );
    return switch (result) {
      CareActionResult.started => const HomeActionResult.accepted(),
      CareActionResult.notEnoughEnergy =>
        const HomeActionResult.rejected(HomeNotice.needsRest),
      _ => const HomeActionResult.rejected(),
    };
  }

  Future<void> cancelPlaying() async {
    if (isPlaying) {
      await lifecycleCoordinator.cancelPlaying();
    }
  }

  Future<HomeNotice?> toggleResting() async {
    if (isResting) {
      await lifecycleCoordinator.stopResting();
      return null;
    }
    if (!canToggleResting) {
      return null;
    }

    if (isCleaning) {
      await finishCleaningGesture();
    }
    _clearSelectedTool();

    final result = lifecycleCoordinator.startResting();
    return switch (result) {
      CareActionResult.notNeeded => HomeNotice.restNotNeeded,
      _ => null,
    };
  }

  void resetTransientUiForPause() {
    _cleaningGestureHadContact = false;
    _clearSelectedTool();
  }

  void _clearSelectedTool() {
    if (_selectedTool == CareTool.none) {
      return;
    }
    _selectedTool = CareTool.none;
    notifyListeners();
  }

  void _forwardPetChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    petController.removeListener(_forwardPetChange);
    super.dispose();
  }
}
