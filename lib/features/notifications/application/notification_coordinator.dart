import 'dart:math';

import 'package:flutter_application_1/app/settings/app_preferences.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/features/notifications/domain/notification_copy_bank.dart';
import 'package:flutter_application_1/features/notifications/domain/pet_notification_plan.dart';
import 'package:flutter_application_1/features/notifications/domain/pet_notification_planner.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';
import 'package:flutter_application_1/integration/notifications/local_notification_service.dart';

class NotificationCoordinator {
  NotificationCoordinator({
    required this.preferencesController,
    required this.service,
    this.planner = const PetNotificationPlanner(),
    this.copyBank = const NotificationCopyBank(),
    Random? random,
  }) : _random = random ?? Random();

  final AppPreferencesController preferencesController;
  final LocalNotificationService service;
  final PetNotificationPlanner planner;
  final NotificationCopyBank copyBank;
  final Random _random;

  bool _initialized = false;

  bool get shouldOfferPrePrompt =>
      preferencesController.notificationPromptDecision ==
      NotificationPromptDecision.notAsked;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    try {
      await service.initialize();
      _initialized = true;
    } catch (_) {
      // Notificaciones son un extra de engagement, nunca una dependencia para
      // que My NTI arranque o conserve su estado.
    }
  }

  Future<void> acceptPrePromptAndRequestPermission() async {
    if (!shouldOfferPrePrompt) {
      return;
    }
    await preferencesController.setNotificationPromptDecision(
      NotificationPromptDecision.accepted,
    );
    try {
      await service.requestPermission();
    } catch (_) {
      // Si el SO o fabricante rechaza/falla, respetamos silencio y no
      // perseguimos al usuario con más prompts.
    }
  }

  Future<void> declinePrePrompt() {
    return preferencesController.setNotificationPromptDecision(
      NotificationPromptDecision.declined,
    );
  }

  Future<void> onForeground() async {
    try {
      await service.clearAll();
    } catch (_) {
      // No impedir resume/offline-decay por un fallo del subsistema nativo.
    }
  }

  Future<void> scheduleForBackground({
    required PetState state,
    required PetRules rules,
    required DateTime nowLocal,
  }) async {
    if (preferencesController.notificationPromptDecision !=
        NotificationPromptDecision.accepted) {
      return;
    }

    try {
      await service.clearAll();
      if (!await service.areNotificationsEnabled()) {
        return;
      }

      final plans = planner.plan(
        state: state,
        rules: rules,
        nowLocal: nowLocal,
      );
      final scheduled = <ScheduledLocalNotification>[];
      final usedVariants = <PetNotificationCopyKind, NotificationCopyVariant>{};

      for (final plan in plans) {
        final variant = _nextVariantFor(plan.copyKind);
        usedVariants[plan.copyKind] = variant;
        scheduled.add(
          ScheduledLocalNotification(
            id: plan.id,
            title: NotificationCopyBank.title,
            body: copyBank.bodyFor(plan.copyKind, variant),
            scheduledAtLocal: plan.scheduledAtLocal,
            payload: 'home:${plan.stage.name}:${plan.copyKind.name}',
          ),
        );
      }

      await service.scheduleAll(scheduled);
      await preferencesController.setNotificationLastVariants(
        <String, String>{
          for (final entry in usedVariants.entries)
            entry.key.name: entry.value.name,
        },
      );
    } catch (_) {
      // El scheduler nunca debe bloquear la salida/background de la app.
    }
  }

  NotificationCopyVariant _nextVariantFor(PetNotificationCopyKind kind) {
    final previous = preferencesController.notificationLastVariants[kind.name];
    if (previous == NotificationCopyVariant.a.name) {
      return NotificationCopyVariant.b;
    }
    if (previous == NotificationCopyVariant.b.name) {
      return NotificationCopyVariant.a;
    }
    if (kind == PetNotificationCopyKind.lastReminder) {
      return NotificationCopyVariant.b;
    }
    return _random.nextBool()
        ? NotificationCopyVariant.a
        : NotificationCopyVariant.b;
  }
}
