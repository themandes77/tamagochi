import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

/// Estado exclusivamente visual de NTI en Home.
///
/// No modifica reglas de Pet ni guarda información. Convierte las necesidades
/// continuas 0..10 en intensidades 0..1 para que cara, postura, movimiento y
/// efectos puedan combinarse sin introducir estados persistentes o colas.
class NtiCareVisualState {
  const NtiCareVisualState({
    required this.activity,
    required this.hungerIntensity,
    required this.cleanlinessIntensity,
    required this.energyIntensity,
    required this.funIntensity,
    required this.criticalNeedCount,
  });

  const NtiCareVisualState.idle()
    : activity = PetActivity.idle,
      hungerIntensity = 0,
      cleanlinessIntensity = 0,
      energyIntensity = 0,
      funIntensity = 0,
      criticalNeedCount = 0;

  final PetActivity activity;
  final double hungerIntensity;
  final double cleanlinessIntensity;
  final double energyIntensity;
  final double funIntensity;
  final int criticalNeedCount;

  bool get isMultiCritical => criticalNeedCount >= 2;
  bool get isEating => activity == PetActivity.eating;
  bool get isCleaning => activity == PetActivity.cleaning;
  bool get isSleeping => activity == PetActivity.sleeping;

  double get distressIntensity {
    if (!isMultiCritical) {
      return 0;
    }
    final strongest = <double>[
      hungerIntensity,
      cleanlinessIntensity,
      energyIntensity,
      funIntensity,
    ].reduce((left, right) => left > right ? left : right);
    // Multicrítico aparece con dos necesidades <= 1, pero entra/sale de forma
    // visualmente suave en Nti. Aquí sólo damos una severidad moderada: nunca
    // se busca una lectura alarmante o de "casi muerto".
    return (0.62 + strongest * 0.38).clamp(0.0, 1.0).toDouble();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NtiCareVisualState &&
            activity == other.activity &&
            hungerIntensity == other.hungerIntensity &&
            cleanlinessIntensity == other.cleanlinessIntensity &&
            energyIntensity == other.energyIntensity &&
            funIntensity == other.funIntensity &&
            criticalNeedCount == other.criticalNeedCount;
  }

  @override
  int get hashCode => Object.hash(
    activity,
    hungerIntensity,
    cleanlinessIntensity,
    energyIntensity,
    funIntensity,
    criticalNeedCount,
  );
}

class NtiCareVisualResolver {
  const NtiCareVisualResolver._();

  /// Umbral visual aprobado para que una necesidad empiece a expresarse.
  static const double lowThreshold = 3.0;

  /// Umbral visual aprobado para considerar una necesidad crítica.
  static const double criticalThreshold = 1.0;

  static NtiCareVisualState resolve({
    required PetState state,
    required PetActivity activity,
  }) {
    final values = <double>[
      state.hunger,
      state.cleanliness,
      state.energy,
      state.fun,
    ];

    return NtiCareVisualState(
      activity: activity,
      hungerIntensity: intensityFor(state.hunger),
      cleanlinessIntensity: intensityFor(state.cleanliness),
      energyIntensity: intensityFor(state.energy),
      funIntensity: intensityFor(state.fun),
      criticalNeedCount: values
          .where((value) => value <= criticalThreshold)
          .length,
    );
  }

  /// Interpolación continua 3 -> 0. A 3 o más la necesidad no altera a NTI;
  /// conforme baja, la expresión crece gradualmente hasta intensidad 1 en 0.
  static double intensityFor(double value) {
    if (!value.isFinite || value >= lowThreshold) {
      return 0;
    }
    if (value <= 0) {
      return 1;
    }
    return ((lowThreshold - value) / lowThreshold).clamp(0.0, 1.0).toDouble();
  }
}
