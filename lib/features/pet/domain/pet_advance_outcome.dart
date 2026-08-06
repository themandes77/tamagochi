import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';

class PetAdvanceOutcome {
  const PetAdvanceOutcome({
    this.stateChanged = false,
    this.completedActivities = const <PetActivity>[],
  });

  final bool stateChanged;
  final List<PetActivity> completedActivities;

  bool get requiresCheckpoint => completedActivities.isNotEmpty;
}
