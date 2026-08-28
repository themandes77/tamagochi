import 'package:flutter_application_1/features/notifications/domain/pet_notification_plan.dart';
import 'package:flutter_application_1/features/pet/domain/pet_need.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

/// Planifica recordatorios locales sin timers ni polling.
///
/// El cálculo ocurre únicamente cuando My NTI pasa a segundo plano. Se limita
/// a cuatro necesidades y dos umbrales, y entrega como máximo tres momentos al
/// sistema operativo.
class PetNotificationPlanner {
  const PetNotificationPlanner({
    this.needThreshold = 5.0,
    this.criticalThreshold = 2.0,
    this.groupingWindow = const Duration(minutes: 90),
    this.minimumGap = const Duration(hours: 2),
    this.alreadyLowDelay = const Duration(hours: 2),
    this.finalReminderDelay = const Duration(hours: 18),
    this.quietStartHour = 22,
    this.quietEndHour = 8,
    this.quietDeliveryMinute = 15,
  });

  static const int needNotificationId = 7101;
  static const int criticalNotificationId = 7102;
  static const int reminderNotificationId = 7103;

  final double needThreshold;
  final double criticalThreshold;
  final Duration groupingWindow;
  final Duration minimumGap;
  final Duration alreadyLowDelay;
  final Duration finalReminderDelay;
  final int quietStartHour;
  final int quietEndHour;
  final int quietDeliveryMinute;

  List<PetNotificationPlan> plan({
    required PetState state,
    required PetRules rules,
    required DateTime nowLocal,
  }) {
    final needCrossings = _crossings(
      state: state,
      rules: rules,
      threshold: needThreshold,
      nowLocal: nowLocal,
    );
    final criticalCrossings = _crossings(
      state: state,
      rules: rules,
      threshold: criticalThreshold,
      nowLocal: nowLocal,
    );

    var candidates = <PetNotificationPlan>[
      _needPlan(needCrossings),
      _criticalPlan(criticalCrossings),
      PetNotificationPlan(
        id: reminderNotificationId,
        stage: PetNotificationStage.reminder,
        copyKind: PetNotificationCopyKind.lastReminder,
        scheduledAtLocal: nowLocal.add(finalReminderDelay),
      ),
    ];

    // Si nti ya salió de la app con alguna necesidad en el primer umbral, no
    // lo hacemos llamar al usuario casi de inmediato aunque el siguiente
    // umbral matemático esté a pocos minutos. La primera oportunidad de
    // reenganche queda a dos horas como mínimo.
    if (_hasNeedAtOrBelow(state, needThreshold)) {
      final earliest = nowLocal.add(alreadyLowDelay);
      candidates = <PetNotificationPlan>[
        for (final candidate in candidates)
          candidate.stage == PetNotificationStage.reminder ||
                  !candidate.scheduledAtLocal.isBefore(earliest)
              ? candidate
              : candidate.copyWith(scheduledAtLocal: earliest),
      ];
    }

    final outsideQuietHours = candidates
        .map(_moveOutsideQuietHours)
        .toList(growable: false);
    return _mergeCloseNotifications(outsideQuietHours);
  }


  bool _hasNeedAtOrBelow(PetState state, double threshold) {
    return PetNeed.values.any((need) => _valueForNeed(state, need) <= threshold);
  }

  PetNotificationPlan _needPlan(List<_NeedCrossing> crossings) {
    final first = crossings.first;
    final grouped = crossings
        .where(
          (item) =>
              item.at.difference(first.at).abs() <= groupingWindow,
        )
        .toList(growable: false);

    if (grouped.length >= 2) {
      return PetNotificationPlan(
        id: needNotificationId,
        stage: PetNotificationStage.need,
        copyKind: PetNotificationCopyKind.multiple,
        scheduledAtLocal: first.at,
      );
    }

    return PetNotificationPlan(
      id: needNotificationId,
      stage: PetNotificationStage.need,
      copyKind: _copyKindForNeed(first.need),
      scheduledAtLocal: first.at,
      primaryNeed: first.need,
    );
  }

  PetNotificationPlan _criticalPlan(List<_NeedCrossing> crossings) {
    return PetNotificationPlan(
      id: criticalNotificationId,
      stage: PetNotificationStage.critical,
      copyKind: PetNotificationCopyKind.critical,
      scheduledAtLocal: crossings.first.at,
      primaryNeed: crossings.first.need,
    );
  }

  List<_NeedCrossing> _crossings({
    required PetState state,
    required PetRules rules,
    required double threshold,
    required DateTime nowLocal,
  }) {
    final crossings = <_NeedCrossing>[
      for (final need in PetNeed.values)
        _NeedCrossing(
          need: need,
          at: nowLocal.add(
            _durationUntilThreshold(
              currentValue: _valueForNeed(state, need),
              threshold: threshold,
              depletionDuration: rules.depletionDurationFor(need),
              needRange: rules.needRange,
            ),
          ),
        ),
    ]..sort((left, right) => left.at.compareTo(right.at));

    return crossings;
  }

  Duration _durationUntilThreshold({
    required double currentValue,
    required double threshold,
    required Duration depletionDuration,
    required double needRange,
  }) {
    if (currentValue <= threshold) {
      return alreadyLowDelay;
    }

    final ratio = ((currentValue - threshold) / needRange)
        .clamp(0.0, 1.0)
        .toDouble();
    return Duration(
      microseconds: (depletionDuration.inMicroseconds * ratio).round(),
    );
  }

  PetNotificationPlan _moveOutsideQuietHours(PetNotificationPlan plan) {
    final original = plan.scheduledAtLocal;
    late final DateTime adjusted;

    if (original.hour >= quietStartHour) {
      adjusted = DateTime(
        original.year,
        original.month,
        original.day + 1,
        quietEndHour,
        quietDeliveryMinute,
      );
    } else if (original.hour < quietEndHour) {
      adjusted = DateTime(
        original.year,
        original.month,
        original.day,
        quietEndHour,
        quietDeliveryMinute,
      );
    } else {
      adjusted = original;
    }

    return plan.copyWith(scheduledAtLocal: adjusted);
  }

  List<PetNotificationPlan> _mergeCloseNotifications(
    List<PetNotificationPlan> input,
  ) {
    final ordered = [...input]
      ..sort((left, right) => left.scheduledAtLocal.compareTo(right.scheduledAtLocal));
    final result = <PetNotificationPlan>[];

    for (final current in ordered) {
      if (result.isEmpty) {
        result.add(current);
        continue;
      }

      final previous = result.last;
      final gap = current.scheduledAtLocal.difference(previous.scheduledAtLocal).abs();
      if (gap >= minimumGap) {
        result.add(current);
        continue;
      }

      final winner = _priorityFor(current.stage) > _priorityFor(previous.stage)
          ? current
          : previous;
      // Si dos etapas quedan demasiado juntas, eliminamos la menos urgente,
      // pero nunca adelantamos la urgente antes de que su condición ocurra.
      result[result.length - 1] = winner;
    }

    return List<PetNotificationPlan>.unmodifiable(result.take(3));
  }

  int _priorityFor(PetNotificationStage stage) {
    return switch (stage) {
      PetNotificationStage.critical => 3,
      PetNotificationStage.need => 2,
      PetNotificationStage.reminder => 1,
    };
  }

  double _valueForNeed(PetState state, PetNeed need) {
    return switch (need) {
      PetNeed.hunger => state.hunger,
      PetNeed.cleanliness => state.cleanliness,
      PetNeed.energy => state.energy,
      PetNeed.fun => state.fun,
    };
  }

  PetNotificationCopyKind _copyKindForNeed(PetNeed need) {
    return switch (need) {
      PetNeed.hunger => PetNotificationCopyKind.hunger,
      PetNeed.cleanliness => PetNotificationCopyKind.cleanliness,
      PetNeed.energy => PetNotificationCopyKind.energy,
      PetNeed.fun => PetNotificationCopyKind.fun,
    };
  }
}

class _NeedCrossing {
  const _NeedCrossing({required this.need, required this.at});

  final PetNeed need;
  final DateTime at;
}
