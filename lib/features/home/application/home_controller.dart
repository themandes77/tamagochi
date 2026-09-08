import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
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
    required this.feedingCoordinator,
  }) {
    petController.addListener(_forwardPetChange);
  }

  final PetController petController;
  final PetLifecycleCoordinator lifecycleCoordinator;
  final FeedingCoordinator feedingCoordinator;

  CareTool _selectedTool = CareTool.none;
  String? _selectedFoodId;
  bool _needsExpanded = true;
  bool _cleaningGestureHadContact = false;
  int _foodSelectionRevision = 0;
  Future<void> _foodTapTail = Future<void>.value();

  CareTool get selectedTool => _selectedTool;
  String? get selectedFoodId => _selectedFoodId;
  bool get hasSelectedFood => _selectedFoodId != null;
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

    if (tool != CareTool.food) {
      await feedingCoordinator.flushPendingMaterializations();
    }

    if (isCleaning) {
      await finishCleaningGesture();
    }

    if (tool != CareTool.food) {
      _selectedFoodId = null;
    }
    _selectedTool = _selectedTool == tool ? CareTool.none : tool;
    notifyListeners();
  }

  /// Prepara el Home para mostrar el inventario de comida sin alterar una
  /// comida que ya estuviera seleccionada.
  Future<bool> prepareForFoodInventory() async {
    if (!canUseCareActions) {
      return false;
    }
    if (isCleaning) {
      await finishCleaningGesture();
    }
    if (_selectedTool == CareTool.soap) {
      _selectedTool = CareTool.none;
      notifyListeners();
    }
    return true;
  }

  /// Si el alimento seleccionado ya no tiene unidades disponibles, limpia la
  /// selección antes de mostrar el inventario. Mantiene la UI coherente incluso
  /// si el inventario cambió por recovery u otra operación externa.
  void clearFoodSelectionIfUnavailable(int Function(String foodId) quantityFor) {
    final selectedFoodId = _selectedFoodId;
    if (selectedFoodId == null || quantityFor(selectedFoodId) > 0) {
      return;
    }
    _clearSelectedTool();
  }

  void toggleFoodSelection(String foodId) {
    if (foodId.isEmpty || !canUseCareActions) {
      return;
    }
    _foodSelectionRevision++;
    if (_selectedFoodId == foodId) {
      _selectedFoodId = null;
      _selectedTool = CareTool.none;
    } else {
      _selectedFoodId = foodId;
      _selectedTool = CareTool.food;
    }
    notifyListeners();
  }

  Future<FoodFeedResult> handleSelectedFoodTap() {
    final foodId = _selectedFoodId;
    final revision = _foodSelectionRevision;
    final completer = Completer<FoodFeedResult>();

    // Serializamos el gesto completo (validación + consumo + actualización de
    // selección), no solo la escritura. Así cada tap puede ser válido, pero
    // siempre ve el resultado real del tap anterior.
    _foodTapTail = _foodTapTail.then((_) async {
      try {
        if (!_isFoodSelectionCurrent(foodId, revision)) {
          completer.complete(
            const FoodFeedResult(status: FoodFeedStatus.staleSelection),
          );
          return;
        }

        final result = await feedingCoordinator.consume(foodId);
        final selectionStillCurrent = _isFoodSelectionCurrent(
          foodId,
          revision,
        );

        if (selectionStillCurrent) {
          final shouldClear = switch (result.status) {
            FoodFeedStatus.tooFull ||
            FoodFeedStatus.outOfStock ||
            FoodFeedStatus.itemNotFound ||
            FoodFeedStatus.noSelection => true,
            FoodFeedStatus.success => result.remainingQuantity <= 0,
            FoodFeedStatus.blocked || FoodFeedStatus.staleSelection => false,
          };

          if (shouldClear) {
            _clearSelectedTool();
          }
        }

        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  bool _isFoodSelectionCurrent(String? foodId, int revision) {
    return foodId != null &&
        _foodSelectionRevision == revision &&
        _selectedFoodId == foodId &&
        _selectedTool == CareTool.food;
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
        _clearSelectedTool();
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

  /// Ruta de interacción del Home: cierra primero el estado lógico de limpieza
  /// y deja el checkpoint en la cola durable. El feedback visual no debe
  /// esperar al disco para responder al gesto del usuario.
  Future<void> finishCleaningGestureForInteraction() async {
    final shouldSave = _cleaningGestureHadContact;
    _cleaningGestureHadContact = false;
    if (isCleaning) {
      await lifecycleCoordinator.stopCleaningForInteraction();
      return;
    }
    if (shouldSave) {
      unawaited(lifecycleCoordinator.saveCheckpoint());
    }
  }

  Future<bool> prepareForNavigation() async {
    if (!canNavigateFromHome) {
      return false;
    }
    await feedingCoordinator.flushPendingMaterializations();
    await finishCleaningGesture();
    _clearSelectedTool();
    return true;
  }

  Future<void> prepareForPauseOverlay() async {
    await feedingCoordinator.flushPendingMaterializations();
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
    await feedingCoordinator.flushPendingMaterializations();
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

  Future<void> finishPlaying({required double funGained}) async {
    if (!isPlaying) {
      return;
    }
    await lifecycleCoordinator.finishPlaying(funGained: funGained);
  }

  Future<void> cancelPlaying() async {
    if (isPlaying) {
      await lifecycleCoordinator.cancelPlaying();
    }
  }

  Future<HomeNotice?> toggleResting() async {
    await feedingCoordinator.flushPendingMaterializations();
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
    final hadSelection =
        _selectedTool != CareTool.none || _selectedFoodId != null;
    if (_selectedFoodId != null || _selectedTool == CareTool.food) {
      _foodSelectionRevision++;
    }
    _selectedTool = CareTool.none;
    _selectedFoodId = null;
    if (hadSelection) {
      notifyListeners();
    }
  }

  void _forwardPetChange() {
    if (_selectedTool == CareTool.soap &&
        petController.rules.isAtMaximum(petController.state.cleanliness)) {
      _cleaningGestureHadContact = false;
      _clearSelectedTool();
      return;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    petController.removeListener(_forwardPetChange);
    super.dispose();
  }
}
