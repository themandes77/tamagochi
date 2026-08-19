import 'package:flutter_application_1/features/pet/domain/pet_need.dart';

class PetRules {
  const PetRules({
    this.needMinimum = 0.0,
    this.needMaximum = 10.0,
    this.initialHunger = 10.0,
    this.initialCleanliness = 10.0,
    this.initialEnergy = 10.0,
    this.initialFun = 10.0,
    this.feedRecovery = 3.0,
    this.feedDuration = const Duration(seconds: 1),
    this.cleanFullRecoveryDuration = const Duration(seconds: 6),
    this.restFullRecoveryDuration = const Duration(seconds: 10),
    this.restStartThreshold = 9.0,
    this.maximumFunRewardPerGame = 3.0,
    this.lowNeedThreshold = 2.0,
    this.lowNeedPenalty = 0.1,
    this.emptyNeedPenalty = 0.2,
    this.hungerDepletionDuration = const Duration(hours: 10),
    this.cleanlinessDepletionDuration = const Duration(hours: 10),
    this.energyDepletionDuration = const Duration(hours: 12),
    this.funDepletionDuration = const Duration(hours: 12),
  }) : assert(needMaximum > needMinimum),
       assert(initialHunger >= needMinimum && initialHunger <= needMaximum),
       assert(
         initialCleanliness >= needMinimum && initialCleanliness <= needMaximum,
       ),
       assert(initialEnergy >= needMinimum && initialEnergy <= needMaximum),
       assert(initialFun >= needMinimum && initialFun <= needMaximum),
       assert(feedRecovery >= 0.0),
       assert(restStartThreshold >= needMinimum),
       assert(restStartThreshold <= needMaximum),
       assert(maximumFunRewardPerGame >= 0.0),
       assert(lowNeedThreshold >= needMinimum),
       assert(lowNeedThreshold <= needMaximum),
       assert(lowNeedPenalty >= 0.0),
       assert(emptyNeedPenalty >= 0.0);

  final double needMinimum;
  final double needMaximum;
  final double initialHunger;
  final double initialCleanliness;
  final double initialEnergy;
  final double initialFun;

  final double feedRecovery;
  final Duration feedDuration;
  final Duration cleanFullRecoveryDuration;
  final Duration restFullRecoveryDuration;
  final double restStartThreshold;
  final double maximumFunRewardPerGame;

  final double lowNeedThreshold;
  final double lowNeedPenalty;
  final double emptyNeedPenalty;

  final Duration hungerDepletionDuration;
  final Duration cleanlinessDepletionDuration;
  final Duration energyDepletionDuration;
  final Duration funDepletionDuration;

  void validate() {
    _requirePositiveDuration(feedDuration, 'feedDuration');
    _requirePositiveDuration(
      cleanFullRecoveryDuration,
      'cleanFullRecoveryDuration',
    );
    _requirePositiveDuration(
      restFullRecoveryDuration,
      'restFullRecoveryDuration',
    );
    _requirePositiveDuration(
      hungerDepletionDuration,
      'hungerDepletionDuration',
    );
    _requirePositiveDuration(
      cleanlinessDepletionDuration,
      'cleanlinessDepletionDuration',
    );
    _requirePositiveDuration(
      energyDepletionDuration,
      'energyDepletionDuration',
    );
    _requirePositiveDuration(funDepletionDuration, 'funDepletionDuration');
  }

  double get needRange => needMaximum - needMinimum;

  double clampNeed(num value) {
    return value.toDouble().clamp(needMinimum, needMaximum).toDouble();
  }

  bool isAtMaximum(double value) => value >= needMaximum;

  bool canStartRest(double energy) => energy <= restStartThreshold;

  double healthFor({
    required double hunger,
    required double cleanliness,
    required double energy,
    required double fun,
  }) {
    final values = <double>[
      clampNeed(hunger),
      clampNeed(cleanliness),
      clampNeed(energy),
      clampNeed(fun),
    ];
    final average =
        values.reduce((left, right) => left + right) / values.length;
    final penalty = values.fold<double>(
      0.0,
      (total, value) => total + criticalPenaltyFor(value),
    );
    return clampNeed(average - penalty);
  }

  double criticalPenaltyFor(double value) {
    final normalized = clampNeed(value);
    if (normalized <= needMinimum) {
      return emptyNeedPenalty;
    }
    if (normalized <= lowNeedThreshold) {
      return lowNeedPenalty;
    }
    return 0.0;
  }

  Duration depletionDurationFor(PetNeed need) {
    return switch (need) {
      PetNeed.hunger => hungerDepletionDuration,
      PetNeed.cleanliness => cleanlinessDepletionDuration,
      PetNeed.energy => energyDepletionDuration,
      PetNeed.fun => funDepletionDuration,
    };
  }

  double decayPerSecondFor(PetNeed need) {
    return needRange / _seconds(depletionDurationFor(need));
  }

  double recoveryAmountFor({
    required Duration elapsed,
    required Duration fullRecoveryDuration,
  }) {
    if (elapsed <= Duration.zero) {
      return 0.0;
    }
    return needRange * (_seconds(elapsed) / _seconds(fullRecoveryDuration));
  }

  Duration recoveryDurationFrom({
    required double currentValue,
    required Duration fullRecoveryDuration,
  }) {
    final normalized = clampNeed(currentValue);
    final missingRatio = (needMaximum - normalized) / needRange;
    final microseconds = (fullRecoveryDuration.inMicroseconds * missingRatio)
        .ceil();
    return Duration(microseconds: microseconds);
  }

  static void _requirePositiveDuration(Duration duration, String name) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        name,
        'Debe ser mayor que Duration.zero.',
      );
    }
  }

  double _seconds(Duration duration) {
    return duration.inMicroseconds / Duration.microsecondsPerSecond;
  }
}
