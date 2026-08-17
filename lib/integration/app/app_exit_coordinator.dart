import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

class AppExitCoordinator {
  const AppExitCoordinator({
    required this.feedingCoordinator,
    required this.petLifecycleCoordinator,
    required this.storeController,
    required this.preferencesController,
    required this.transactionCoordinator,
  });

  final FeedingCoordinator feedingCoordinator;
  final PetLifecycleCoordinator petLifecycleCoordinator;
  final StoreController storeController;
  final AppPreferencesController preferencesController;
  final CrossModuleTransactionCoordinator transactionCoordinator;

  Future<void> saveBeforeExit() async {
    await feedingCoordinator.flushPendingMaterializations();
    await petLifecycleCoordinator.saveCheckpoint();
    await petLifecycleCoordinator.flushPendingSaves();
    await storeController.persistRuntimeCoins();
    await storeController.flushPendingSaves();
    await preferencesController.persist();
    await preferencesController.flushPendingSaves();
    await transactionCoordinator.recoverPending();
  }
}
