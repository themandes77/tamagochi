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
  bool _initialized = false;
  Future<void> _saveTail = Future<void>.value();

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    final now = clock.nowUtc();
    final loaded = await repository.load();
    final state = loaded ?? PetState.initial(nowUtc: now, rules: rules);
    controller.replaceState(state);

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
    final result = controller.finishPlaying(funGained: funGained);
    if (result == CareActionResult.completed) {
      await saveCheckpoint();
    }
    return result;
  }

  Future<CareActionResult> cancelPlaying() async {
    _requireInitialized();
    final result = controller.cancelPlaying();
    if (result == CareActionResult.interrupted) {
      await saveCheckpoint();
    }
    return result;
  }

  PetAdvanceOutcome advance(Duration elapsed) {
    _requireInitialized();
    final outcome = controller.advance(elapsed);
    _wallCursor = (_wallCursor ?? clock.nowUtc()).add(elapsed);
    if (outcome.requiresCheckpoint) {
      unawaited(_enqueueSave());
    }
    return outcome;
  }

  Future<void> saveCheckpoint() async {
    _requireInitialized();
    _syncToWallClock();
    await _enqueueSave();
  }

  Future<void> pause() async {
    _requireInitialized();
    _syncToWallClock();
    controller.resetTransientState();
    await _enqueueSave();
  }

  Future<void> resume() async {
    _requireInitialized();
    final now = clock.nowUtc();
    final elapsed = _positiveDifference(now, controller.state.lastSavedAt);
    controller.applyOfflineDecay(elapsed);
    controller.updateLastSavedAt(now);
    _wallCursor = now;
    await _enqueueSave();
  }

  Future<void> flushPendingSaves() async {
    await _saveTail;
  }

  void _syncToWallClock() {
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
        _wallCursor = now;
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
