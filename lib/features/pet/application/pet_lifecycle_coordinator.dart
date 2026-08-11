import 'dart:async';

import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/domain/care_action_result.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/features/pet/domain/pet_advance_outcome.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetLifecycleCoordinator {
  PetLifecycleCoordinator({
    required this.controller,
    required this.repository,
    required this.clock,
    this.rules = const PetRules(),
  });

  final PetController controller;
  final PetRepository repository;
  final AppClock clock;
  final PetRules rules;

  DateTime? _wallCursor;
  bool _durableStateLoaded = false;
  bool _initialized = false;
  Future<void> _saveTail = Future<void>.value();
  Future<void> _exclusiveMutationTail = Future<void>.value();
  bool _exclusiveMutationActive = false;
  Duration _deferredElapsed = Duration.zero;

  bool get isInitialized => _initialized;
  bool get isDurableStateLoaded => _durableStateLoaded;

  /// Compatibilidad para pruebas/hosts simples que no usan journal externo.
  ///
  /// El bootstrap real usa explícitamente las dos fases para recuperar primero
  /// las transacciones pendientes y aplicar después el deterioro offline.
  Future<void> initialize() async {
    await loadDurableState();
    await activateRuntimeAfterRecovery();
  }

  /// Carga exactamente el estado durable de Pet sin modificarlo.
  ///
  /// No aplica deterioro offline, no cambia lastSavedAt y no crea un nuevo
  /// checkpoint. Así el journal puede comparar sus checksums contra la misma
  /// línea base que existía cuando se interrumpió una transacción.
  Future<void> loadDurableState() async {
    if (_durableStateLoaded) {
      return;
    }
    final now = clock.nowUtc();
    final loaded = await repository.load();
    final state = loaded ?? PetState.initial(nowUtc: now, rules: rules);
    controller.replaceState(state);
    _wallCursor = state.lastSavedAt.toUtc();
    _durableStateLoaded = true;
  }

  /// Activa el runtime una vez que el journal quedó reconciliado.
  ///
  /// El deterioro offline se calcula sobre el estado final recuperado (before
  /// o target, según corresponda), nunca sobre un estado que luego el journal
  /// deba reemplazar.
  Future<void> activateRuntimeAfterRecovery() async {
    if (_initialized) {
      return;
    }
    if (!_durableStateLoaded) {
      throw StateError(
        'Pet debe cargar su estado durable antes de activar el runtime.',
      );
    }

    final now = clock.nowUtc();
    final state = controller.state;
    final offlineElapsed = _positiveDifference(now, state.lastSavedAt);
    controller.applyOfflineDecay(offlineElapsed);
    controller.updateLastSavedAt(now);
    _wallCursor = now;
    _initialized = true;
    await _enqueueSave();
  }

  CareActionResult startFeeding() {
    _requireInitialized();
    return controller.startFeeding();
  }

  CareActionResult startCleaning() {
    _requireInitialized();
    return controller.startCleaning();
  }

  Future<CareActionResult> stopCleaning() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    _syncToWallClock();
    final result = controller.stopCleaning();
    if (result == CareActionResult.interrupted) {
      await _enqueueSave();
    }
    return result;
  }

  CareActionResult startResting() {
    _requireInitialized();
    return controller.startResting();
  }

  Future<CareActionResult> stopResting() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    _syncToWallClock();
    final result = controller.stopResting();
    if (result == CareActionResult.interrupted) {
      await _enqueueSave();
    }
    return result;
  }

  Future<CareActionResult> startPlaying({
    required GameCostPolicy costPolicy,
  }) async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    _syncToWallClock();
    final result = controller.startPlaying(costPolicy: costPolicy);
    if (result == CareActionResult.started) {
      await _enqueueSave();
    }
    return result;
  }

  Future<CareActionResult> finishPlaying({
    required double funGained,
  }) async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    final result = controller.finishPlaying(funGained: funGained);
    if (result == CareActionResult.completed) {
      await saveCheckpoint();
    }
    return result;
  }

  Future<CareActionResult> cancelPlaying() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    final result = controller.cancelPlaying();
    if (result == CareActionResult.interrupted) {
      await saveCheckpoint();
    }
    return result;
  }

  PetAdvanceOutcome advance(Duration elapsed) {
    _requireInitialized();
    if (elapsed < Duration.zero) {
      throw ArgumentError.value(
        elapsed,
        'elapsed',
        'El tiempo transcurrido no puede ser negativo.',
      );
    }
    if (elapsed == Duration.zero) {
      return const PetAdvanceOutcome();
    }

    // Durante una mutación transaccional no permitimos que el ticker cambie
    // el payload de Pet. El tiempo no se pierde: se acumula y se aplica apenas
    // termina la sección exclusiva. El cursor sí avanza para que el reloj de
    // pared y el ticker sigan sobre una misma línea temporal.
    if (_exclusiveMutationActive) {
      _deferredElapsed += elapsed;
      _wallCursor = (_wallCursor ?? clock.nowUtc()).add(elapsed);
      return const PetAdvanceOutcome();
    }

    final outcome = controller.advance(elapsed);
    _wallCursor = (_wallCursor ?? clock.nowUtc()).add(elapsed);
    if (outcome.requiresCheckpoint) {
      unawaited(_enqueueSave());
    }
    return outcome;
  }

  /// Ejecuta una mutación que necesita una fotografía estable de Pet.
  ///
  /// El ticker puede seguir emitiendo frames, pero sus deltas se difieren
  /// mientras [operation] trabaja. Antes de abrir la sección exclusiva se
  /// sincroniza y persiste una línea base durable; al salir se reaplica todo
  /// el tiempo diferido sobre el estado resultante de la operación.
  Future<T> runExclusiveMutation<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _exclusiveMutationTail = _exclusiveMutationTail.then((_) async {
      _requireInitialized();

      // Ningún save anterior puede quedar mutando lastSavedAt mientras la
      // transacción toma su baseline.
      await _saveTail;
      _syncToWallClock();

      _exclusiveMutationActive = true;
      _deferredElapsed = Duration.zero;
      try {
        // La línea base debe existir en disco antes de que el journal calcule
        // checksums. _enqueueSave sabe no mover _wallCursor durante el lock.
        await _enqueueSave();
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        final deferred = _deferredElapsed;
        _deferredElapsed = Duration.zero;
        _exclusiveMutationActive = false;

        if (deferred > Duration.zero) {
          final outcome = controller.advance(deferred);
          if (outcome.requiresCheckpoint) {
            unawaited(_enqueueSave());
          }
        }
      }
    });
    return completer.future;
  }

  Future<void> saveCheckpoint() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    _syncToWallClock();
    await _enqueueSave();
  }

  Future<void> pause() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    _syncToWallClock();
    controller.resetTransientState();
    await _enqueueSave();
  }

  Future<void> resume() async {
    _requireInitialized();
    await _waitForExclusiveMutation();
    final now = clock.nowUtc();
    final elapsed = _positiveDifference(now, controller.state.lastSavedAt);
    controller.applyOfflineDecay(elapsed);
    controller.updateLastSavedAt(now);
    _wallCursor = now;
    await _enqueueSave();
  }

  Future<void> flushPendingSaves() async {
    await _waitForExclusiveMutation();
    await _saveTail;
  }

  Future<void> _waitForExclusiveMutation() async {
    await _exclusiveMutationTail;
  }

  void _syncToWallClock() {
    if (_exclusiveMutationActive) {
      return;
    }
    final now = clock.nowUtc();
    final cursor = _wallCursor ?? now;
    final delta = _positiveDifference(now, cursor);
    if (delta > Duration.zero) {
      controller.advance(delta);
    }
    _wallCursor = now;
  }

  Future<void> _enqueueSave() {
    final completer = Completer<void>();
    _saveTail = _saveTail.then((_) async {
      try {
        final now = clock.nowUtc();
        controller.updateLastSavedAt(now);
        if (!_exclusiveMutationActive) {
          _wallCursor = now;
        }
        await repository.save(controller.state);
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Duration _positiveDifference(DateTime later, DateTime earlier) {
    final difference = later.toUtc().difference(earlier.toUtc());
    return difference.isNegative ? Duration.zero : difference;
  }

  void _requireInitialized() {
    if (!_initialized) {
      throw StateError(
        'PetLifecycleCoordinator debe inicializarse antes de utilizarse.',
      );
    }
  }
}
