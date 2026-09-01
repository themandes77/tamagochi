import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/notifications/domain/pet_notification_plan.dart';
import 'package:flutter_application_1/features/notifications/domain/pet_notification_planner.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

void main() {
  const planner = PetNotificationPlanner();
  const rules = PetRules();

  test('desde lleno agrupa necesidades cercanas y crea tres etapas', () {
    final now = DateTime(2026, 8, 28, 10);
    final state = PetState.initial(nowUtc: now.toUtc(), rules: rules);

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans, hasLength(3));
    expect(plans[0].stage, PetNotificationStage.need);
    expect(plans[0].copyKind, PetNotificationCopyKind.multiple);
    expect(plans[0].scheduledAtLocal, DateTime(2026, 8, 28, 15));

    expect(plans[1].stage, PetNotificationStage.critical);
    expect(plans[1].scheduledAtLocal, DateTime(2026, 8, 28, 18));

    expect(plans[2].stage, PetNotificationStage.reminder);
    // 18 h desde 10:00 cae a las 04:00 y quiet hours lo pasa a 08:15.
    expect(plans[2].scheduledAtLocal, DateTime(2026, 8, 29, 8, 15));
  });

  test('si ya está crítico no dispara dos avisos juntos', () {
    final now = DateTime(2026, 8, 28, 10);
    final state = PetState(
      hunger: 1,
      cleanliness: 1,
      energy: 1,
      fun: 1,
      lastSavedAt: now.toUtc(),
      rules: rules,
    );

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans.first.stage, PetNotificationStage.critical);
    expect(plans.first.scheduledAtLocal, DateTime(2026, 8, 28, 12));
    expect(plans.where((item) => item.stage == PetNotificationStage.need), isEmpty);
  });

  test('si ya estaba bajo ninguna etapa avisa antes de dos horas', () {
    final now = DateTime(2026, 8, 28, 10);
    final state = PetState(
      hunger: 3,
      cleanliness: 10,
      energy: 10,
      fun: 10,
      lastSavedAt: now.toUtc(),
      rules: rules,
    );

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans.first.stage, PetNotificationStage.critical);
    expect(
      plans.first.scheduledAtLocal.isBefore(DateTime(2026, 8, 28, 12)),
      isFalse,
    );
  });

  test('al fusionar no adelanta una etapa crítica', () {
    final now = DateTime(2026, 8, 28, 10);
    final state = PetState(
      hunger: 5,
      cleanliness: 10,
      energy: 10,
      fun: 10,
      lastSavedAt: now.toUtc(),
      rules: rules,
    );

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans.first.stage, PetNotificationStage.critical);
    expect(plans.first.scheduledAtLocal, DateTime(2026, 8, 28, 13));
  });

  test('quiet hours fusiona etapas cercanas y conserva la crítica', () {
    final now = DateTime(2026, 8, 28, 21);
    final state = PetState.initial(nowUtc: now.toUtc(), rules: rules);

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans.first.stage, PetNotificationStage.critical);
    expect(plans.first.scheduledAtLocal, DateTime(2026, 8, 29, 8, 15));
    expect(plans.length, lessThanOrEqualTo(3));
  });

  test('usa copy específico cuando sólo una necesidad cruza pronto', () {
    final now = DateTime(2026, 8, 28, 10);
    final state = PetState(
      hunger: 6,
      cleanliness: 10,
      energy: 10,
      fun: 10,
      lastSavedAt: now.toUtc(),
      rules: rules,
    );

    final plans = planner.plan(state: state, rules: rules, nowLocal: now);

    expect(plans.first.stage, PetNotificationStage.need);
    expect(plans.first.copyKind, PetNotificationCopyKind.hunger);
    expect(plans.first.scheduledAtLocal, DateTime(2026, 8, 28, 11));
  });
}
