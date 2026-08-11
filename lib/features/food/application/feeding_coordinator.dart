import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/food/domain/food_item.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';

/// Resultado funcional de intentar alimentar a NTI con una comida seleccionada.
enum FoodFeedStatus {
  success,
  tooFull,
  outOfStock,
  itemNotFound,
  blocked,
  noSelection,
  staleSelection,
}

class FoodFeedResult {
  const FoodFeedResult({
    required this.status,
    this.food,
    this.remainingQuantity = 0,
  });

  final FoodFeedStatus status;
  final FoodItem? food;
  final int remainingQuantity;

  bool get consumed => status == FoodFeedStatus.success;
}

/// Coordina la única operación que cruza Pet + Store: consumir alimento.
///
/// La comida se valida primero y luego Pet + inventario se escriben mediante el
/// journal transaccional existente. Así no puede persistirse hambre sin restar
/// inventario, ni inventario sin aplicar saciedad.
class FeedingCoordinator {
  FeedingCoordinator({
    required this.petController,
    required this.petLifecycleCoordinator,
    required this.storeController,
    required this.transactionCoordinator,
    required this.clock,
  });

  static const double fullnessThreshold = 9.5;

  final PetController petController;
  final PetLifecycleCoordinator petLifecycleCoordinator;
  final StoreController storeController;
  final CrossModuleTransactionCoordinator transactionCoordinator;
  final AppClock clock;

  Future<void> _operationTail = Future<void>.value();
  int _transactionSequence = 0;

  Future<FoodFeedResult> consume(String? foodId) {
    final completer = Completer<FoodFeedResult>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await _consumeInternal(foodId));
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<FoodFeedResult> _consumeInternal(String? foodId) async {
    final totalWatch = Stopwatch()..start();
    var storeFlush = Duration.zero;
    var petBaseline = Duration.zero;
    var transaction = Duration.zero;

    if (foodId == null) {
      return const FoodFeedResult(status: FoodFeedStatus.noSelection);
    }

    final food = storeController.foodById(foodId);
    if (food == null) {
      return const FoodFeedResult(status: FoodFeedStatus.itemNotFound);
    }
    if (petController.isBusy) {
      return FoodFeedResult(status: FoodFeedStatus.blocked, food: food);
    }

    // Espera cualquier compra/checkpoint del Store antes de construir los
    // objetivos de la transacción de alimentación.
    final storeFlushWatch = Stopwatch()..start();
    await storeController.flushPendingSaves();
    storeFlush = storeFlushWatch.elapsed;

    if (storeController.foodQuantity(food.id) <= 0) {
      return FoodFeedResult(status: FoodFeedStatus.outOfStock, food: food);
    }

    // Pet cambia continuamente por el ticker. La transacción necesita una
    // fotografía estable para que el checksum no interprete el deterioro
    // normal como una escritura concurrente. PetLifecycleCoordinator difiere
    // esos frames durante esta sección y los recupera al terminar.
    final exclusiveEntryWatch = Stopwatch()..start();
    try {
      return await petLifecycleCoordinator.runExclusiveMutation(() async {
        // Entrar a este callback significa que Pet ya esperó saves anteriores,
        // sincronizó reloj y persistió su baseline durable. Esta medición nos
        // deja ver cuánto cuesta exactamente esa preparación.
        petBaseline = exclusiveEntryWatch.elapsed;

        if (petController.isBusy) {
          return FoodFeedResult(status: FoodFeedStatus.blocked, food: food);
        }
        if (storeController.foodQuantity(food.id) <= 0) {
          return FoodFeedResult(status: FoodFeedStatus.outOfStock, food: food);
        }
        if (petController.state.hunger >= fullnessThreshold) {
          return FoodFeedResult(status: FoodFeedStatus.tooFull, food: food);
        }

        final petTarget = petController.state.copyWith(
          hunger: petController.state.hunger + food.satiety,
          rules: petController.rules,
        );
        final storeTarget = storeController.snapshotAfterFoodConsumption(food.id);

        final transactionId =
            'feed_${clock.nowUtc().microsecondsSinceEpoch}_${_transactionSequence++}';

        final transactionWatch = Stopwatch()..start();
        await transactionCoordinator.execute(
          transactionId: transactionId,
          type: 'consume_food',
          targetPayloads: <String, Map<String, Object?>>{
            'pet': petTarget.toJson(),
            'store': storeTarget.toJson(),
          },
          // Store ya esperó saves pendientes y Pet acaba de checkpointar su
          // baseline dentro de runExclusiveMutation. Evitamos durabilizar por
          // segunda vez exactamente los mismos estados.
          baselineAlreadyDurable: true,
        );
        transaction = transactionWatch.elapsed;

        return FoodFeedResult(
          status: FoodFeedStatus.success,
          food: food,
          remainingQuantity: storeController.foodQuantity(food.id),
        );
      });
    } finally {
      totalWatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[NTI PERF][FEED ${food.id}] total=${totalWatch.elapsedMilliseconds}ms '
          '| storeFlush=${storeFlush.inMilliseconds}ms '
          '| petBaseline=${petBaseline.inMilliseconds}ms '
          '| transaction=${transaction.inMilliseconds}ms',
        );
      }
    }
  }
}
