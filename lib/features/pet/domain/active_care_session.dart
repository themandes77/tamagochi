import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';
import 'package:flutter_application_1/features/pet/domain/pet_need.dart';

class ActiveCareSession {
  const ActiveCareSession({
    required this.activity,
    required this.isInterruptible,
    this.elapsed = Duration.zero,
  }) : assert(activity != PetActivity.idle),
       assert(activity != PetActivity.playing),
       assert(elapsed >= Duration.zero);

  final PetActivity activity;
  final bool isInterruptible;
  final Duration elapsed;

  PetNeed get targetNeed {
    return switch (activity) {
      PetActivity.eating => PetNeed.hunger,
      PetActivity.cleaning => PetNeed.cleanliness,
      PetActivity.sleeping => PetNeed.energy,
      PetActivity.idle || PetActivity.playing =>
        throw StateError('$activity no representa una acción de cuidado.'),
    };
  }

  ActiveCareSession advance(Duration delta) {
    if (delta < Duration.zero) {
      throw ArgumentError.value(
        delta,
        'delta',
        'El tiempo transcurrido no puede ser negativo.',
      );
    }
    return ActiveCareSession(
      activity: activity,
      isInterruptible: isInterruptible,
      elapsed: elapsed + delta,
    );
  }
}
