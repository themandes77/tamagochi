import 'package:flutter_application_1/features/pet/domain/pet_need.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetDecayCalculator {
  const PetDecayCalculator();

  PetState apply({
    required PetState state,
    required Duration elapsed,
    required PetRules rules,
    Set<PetNeed> pausedNeeds = const <PetNeed>{},
  }) {
    if (elapsed < Duration.zero) {
      throw ArgumentError.value(
        elapsed,
        'elapsed',
        'El tiempo transcurrido no puede ser negativo.',
      );
    }
    if (elapsed == Duration.zero) {
      return state;
    }

    final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;

    double decay(double value, PetNeed need) {
      if (pausedNeeds.contains(need)) {
        return value;
      }
      return rules.clampNeed(value - rules.decayPerSecondFor(need) * seconds);
    }

    return state.copyWith(
      hunger: decay(state.hunger, PetNeed.hunger),
      cleanliness: decay(state.cleanliness, PetNeed.cleanliness),
      energy: decay(state.energy, PetNeed.energy),
      fun: decay(state.fun, PetNeed.fun),
      rules: rules,
    );
  }
}
