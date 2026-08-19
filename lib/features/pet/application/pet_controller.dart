import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/pet/domain/active_care_session.dart';
import 'package:flutter_application_1/features/pet/domain/care_action_result.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/features/pet/domain/game_start_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';
import 'package:flutter_application_1/features/pet/domain/pet_advance_outcome.dart';
import 'package:flutter_application_1/features/pet/domain/pet_decay_calculator.dart';
import 'package:flutter_application_1/features/pet/domain/pet_need.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetController extends ChangeNotifier {
  PetController({
    required PetState initialState,
    this.rules = const PetRules(),
    this.decayCalculator = const PetDecayCalculator(),
  }) : _state = initialState.copyWith(rules: rules);

  final PetRules rules;
  final PetDecayCalculator decayCalculator;

  PetState _state;
  PetActivity _activity = PetActivity.idle;
  ActiveCareSession? _activeCareSession;

  PetState get state => _state;
  PetActivity get activity => _activity;
  ActiveCareSession? get activeCareSession => _activeCareSession;
  double get health => _state.healthFor(rules);
  bool get isBusy => _activity != PetActivity.idle;

  CareActionResult startFeeding() {
    if (isBusy) {
      return CareActionResult.blockedByActivity;
    }
    if (rules.isAtMaximum(_state.hunger)) {
      return CareActionResult.alreadySatisfied;
    }
    _beginCare(PetActivity.eating, isInterruptible: false);
    return CareActionResult.started;
  }

  CareActionResult startCleaning() {
    if (isBusy) {
      return CareActionResult.blockedByActivity;
    }
    if (rules.isAtMaximum(_state.cleanliness)) {
      return CareActionResult.alreadySatisfied;
    }
    _beginCare(PetActivity.cleaning, isInterruptible: true);
    return CareActionResult.started;
  }

  CareActionResult stopCleaning() {
    if (_activity != PetActivity.cleaning) {
      return CareActionResult.noActiveAction;
    }
    return _interruptActiveCare();
  }

  CareActionResult startResting() {
    if (isBusy) {
      return CareActionResult.blockedByActivity;
    }
    if (!rules.canStartRest(_state.energy)) {
      return CareActionResult.notNeeded;
    }
    _beginCare(PetActivity.sleeping, isInterruptible: true);
    return CareActionResult.started;
  }

  CareActionResult stopResting() {
    if (_activity != PetActivity.sleeping) {
      return CareActionResult.noActiveAction;
    }
    return _interruptActiveCare();
  }

  bool canStartPlaying(GameCostPolicy costPolicy) {
    return GameStartRules.hasEnoughEnergy(
      currentEnergy: _state.energy,
      costPolicy: costPolicy,
    );
  }

  CareActionResult startPlaying({required GameCostPolicy costPolicy}) {
    if (isBusy) {
      return CareActionResult.blockedByActivity;
    }
    if (!canStartPlaying(costPolicy)) {
      return CareActionResult.notEnoughEnergy;
    }

    _state = _state.copyWith(
      cleanliness: _state.cleanliness - costPolicy.cleanlinessCost,
      energy: _state.energy - costPolicy.energyCost,
      rules: rules,
    );
    _activity = PetActivity.playing;
    notifyListeners();
    return CareActionResult.started;
  }

  CareActionResult finishPlaying({required double funGained}) {
    if (_activity != PetActivity.playing) {
      return CareActionResult.noActiveAction;
    }
    if (!funGained.isFinite ||
        funGained < 0.0 ||
        funGained > rules.maximumFunRewardPerGame) {
      throw ArgumentError.value(
        funGained,
        'funGained',
        'La diversión debe estar entre 0 y '
            '${rules.maximumFunRewardPerGame}.',
      );
    }
    _state = _state.copyWith(fun: _state.fun + funGained, rules: rules);
    _activity = PetActivity.idle;
    notifyListeners();
    return CareActionResult.completed;
  }

  CareActionResult cancelPlaying() {
    if (_activity != PetActivity.playing) {
      return CareActionResult.noActiveAction;
    }
    _activity = PetActivity.idle;
    notifyListeners();
    return CareActionResult.interrupted;
  }

  PetAdvanceOutcome advance(Duration elapsed) {
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

    var remaining = elapsed;
    var stateChanged = false;
    final completed = <PetActivity>[];

    while (remaining > Duration.zero) {
      final session = _activeCareSession;
      if (session == null) {
        final next = decayCalculator.apply(
          state: _state,
          elapsed: remaining,
          rules: rules,
        );
        stateChanged = stateChanged || next != _state;
        _state = next;
        remaining = Duration.zero;
        continue;
      }

      final step = _stepDuration(session, remaining);
      if (step == Duration.zero) {
        _completeCare(session.activity);
        completed.add(session.activity);
        continue;
      }

      _advanceCare(session, step);
      stateChanged = true;
      remaining -= step;

      if (_careReachedCompletion(session.activity)) {
        _completeCare(session.activity);
        completed.add(session.activity);
      }
    }

    if (stateChanged || completed.isNotEmpty) {
      notifyListeners();
    }
    return PetAdvanceOutcome(
      stateChanged: stateChanged,
      completedActivities: List<PetActivity>.unmodifiable(completed),
    );
  }

  void applyOfflineDecay(Duration elapsed) {
    if (elapsed < Duration.zero) {
      throw ArgumentError.value(
        elapsed,
        'elapsed',
        'El tiempo offline no puede ser negativo.',
      );
    }
    resetTransientState(notify: false);
    if (elapsed > Duration.zero) {
      _state = decayCalculator.apply(
        state: _state,
        elapsed: elapsed,
        rules: rules,
      );
    }
    notifyListeners();
  }

  PetActivity? resetTransientState({bool notify = true}) {
    final previous = _activity == PetActivity.idle ? null : _activity;
    _activeCareSession = null;
    _activity = PetActivity.idle;
    if (previous != null && notify) {
      notifyListeners();
    }
    return previous;
  }

  void replaceState(PetState state) {
    _state = state.copyWith(rules: rules);
    _activeCareSession = null;
    _activity = PetActivity.idle;
    notifyListeners();
  }

  void updateLastSavedAt(DateTime value) {
    _state = _state.copyWith(lastSavedAt: value.toUtc(), rules: rules);
    notifyListeners();
  }

  void _beginCare(PetActivity activity, {required bool isInterruptible}) {
    _activity = activity;
    _activeCareSession = ActiveCareSession(
      activity: activity,
      isInterruptible: isInterruptible,
    );
    notifyListeners();
  }

  CareActionResult _interruptActiveCare() {
    final session = _activeCareSession;
    if (session == null) {
      return CareActionResult.noActiveAction;
    }
    if (!session.isInterruptible) {
      return CareActionResult.notInterruptible;
    }
    _activeCareSession = null;
    _activity = PetActivity.idle;
    notifyListeners();
    return CareActionResult.interrupted;
  }

  Duration _stepDuration(ActiveCareSession session, Duration remaining) {
    final untilCompletion = switch (session.activity) {
      PetActivity.eating => rules.feedDuration - session.elapsed,
      PetActivity.cleaning => rules.recoveryDurationFrom(
        currentValue: _state.cleanliness,
        fullRecoveryDuration: rules.cleanFullRecoveryDuration,
      ),
      PetActivity.sleeping => rules.recoveryDurationFrom(
        currentValue: _state.energy,
        fullRecoveryDuration: rules.restFullRecoveryDuration,
      ),
      PetActivity.idle || PetActivity.playing => Duration.zero,
    };

    if (untilCompletion <= Duration.zero) {
      return Duration.zero;
    }
    return untilCompletion < remaining ? untilCompletion : remaining;
  }

  void _advanceCare(ActiveCareSession session, Duration elapsed) {
    final pausedNeed = session.targetNeed;
    _state = decayCalculator.apply(
      state: _state,
      elapsed: elapsed,
      rules: rules,
      pausedNeeds: <PetNeed>{pausedNeed},
    );

    switch (session.activity) {
      case PetActivity.eating:
        break;
      case PetActivity.cleaning:
        _state = _state.copyWith(
          cleanliness:
              _state.cleanliness +
              rules.recoveryAmountFor(
                elapsed: elapsed,
                fullRecoveryDuration: rules.cleanFullRecoveryDuration,
              ),
          rules: rules,
        );
        break;
      case PetActivity.sleeping:
        _state = _state.copyWith(
          energy:
              _state.energy +
              rules.recoveryAmountFor(
                elapsed: elapsed,
                fullRecoveryDuration: rules.restFullRecoveryDuration,
              ),
          rules: rules,
        );
        break;
      case PetActivity.idle || PetActivity.playing:
        throw StateError('${session.activity} no es una acción de cuidado.');
    }

    _activeCareSession = session.advance(elapsed);
  }

  bool _careReachedCompletion(PetActivity activity) {
    final session = _activeCareSession;
    if (session == null) {
      return true;
    }
    return switch (activity) {
      PetActivity.eating => session.elapsed >= rules.feedDuration,
      PetActivity.cleaning => rules.isAtMaximum(_state.cleanliness),
      PetActivity.sleeping => rules.isAtMaximum(_state.energy),
      PetActivity.idle || PetActivity.playing => true,
    };
  }

  void _completeCare(PetActivity activity) {
    if (activity == PetActivity.eating) {
      _state = _state.copyWith(
        hunger: _state.hunger + rules.feedRecovery,
        rules: rules,
      );
    }
    _activeCareSession = null;
    _activity = PetActivity.idle;
  }
}
