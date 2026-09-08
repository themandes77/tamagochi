import 'package:flutter_application_1/features/pet/domain/pet_need.dart';

enum PetNotificationStage { need, critical, reminder }

enum PetNotificationCopyKind {
  hunger,
  cleanliness,
  energy,
  fun,
  multiple,
  critical,
  lastReminder,
}

class PetNotificationPlan {
  const PetNotificationPlan({
    required this.id,
    required this.stage,
    required this.copyKind,
    required this.scheduledAtLocal,
    this.primaryNeed,
  });

  final int id;
  final PetNotificationStage stage;
  final PetNotificationCopyKind copyKind;
  final DateTime scheduledAtLocal;
  final PetNeed? primaryNeed;

  PetNotificationPlan copyWith({
    int? id,
    PetNotificationStage? stage,
    PetNotificationCopyKind? copyKind,
    DateTime? scheduledAtLocal,
    PetNeed? primaryNeed,
    bool clearPrimaryNeed = false,
  }) {
    return PetNotificationPlan(
      id: id ?? this.id,
      stage: stage ?? this.stage,
      copyKind: copyKind ?? this.copyKind,
      scheduledAtLocal: scheduledAtLocal ?? this.scheduledAtLocal,
      primaryNeed: clearPrimaryNeed ? null : (primaryNeed ?? this.primaryNeed),
    );
  }
}
