import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';

class AppExitCoordinator {
  const AppExitCoordinator({
    required this.petLifecycleCoordinator,
    required this.preferencesController,
    required this.transactionCoordinator,
  });

  final PetLifecycleCoordinator petLifecycleCoordinator;
  final AppPreferencesController preferencesController;
  final CrossModuleTransactionCoordinator transactionCoordinator;

  Future<void> saveBeforeExit() async {
    await petLifecycleCoordinator.saveCheckpoint();
    await petLifecycleCoordinator.flushPendingSaves();
    await preferencesController.persist();
    await preferencesController.flushPendingSaves();
    await transactionCoordinator.recoverPending();
  }
}
