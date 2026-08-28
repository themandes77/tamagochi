import 'package:flutter_application_1/features/notifications/domain/pet_notification_plan.dart';

enum NotificationCopyVariant { a, b }

class NotificationCopyBank {
  const NotificationCopyBank();

  static const String title = 'My NTI';

  String bodyFor(
    PetNotificationCopyKind kind,
    NotificationCopyVariant variant,
  ) {
    return switch ((kind, variant)) {
      (PetNotificationCopyKind.hunger, NotificationCopyVariant.a) =>
        '¿Guardaste algo para mí? 👀',
      (PetNotificationCopyKind.hunger, NotificationCopyVariant.b) =>
        'Oye… ¿no tendrás algo rico por ahí?',
      (PetNotificationCopyKind.cleanliness, NotificationCopyVariant.a) =>
        'Oyeee… creo que me toca un bañito 🫧',
      (PetNotificationCopyKind.cleanliness, NotificationCopyVariant.b) =>
        '¿Me ayudas a quedar bonito otra vez? ✨',
      (PetNotificationCopyKind.energy, NotificationCopyVariant.a) =>
        '¿Una siestita? Prometo despertar rápido.',
      (PetNotificationCopyKind.energy, NotificationCopyVariant.b) =>
        'Tengo sueñito… ¿me acompañas un rato? 💤',
      (PetNotificationCopyKind.fun, NotificationCopyVariant.a) =>
        'Oyeee… ¿jugamos tantito? 🎮',
      (PetNotificationCopyKind.fun, NotificationCopyVariant.b) =>
        'Estoy empezando a aburrirme por aquí 👀',
      (PetNotificationCopyKind.multiple, NotificationCopyVariant.a) =>
        'Oye… creo que hoy sí necesito que vengas 😅',
      (PetNotificationCopyKind.multiple, NotificationCopyVariant.b) =>
        '¿Vienes a verme? Creo que se me juntaron varias cosas.',
      (PetNotificationCopyKind.critical, NotificationCopyVariant.a) =>
        'Ejem… ¿te acuerdas de mí? Necesito una manita por acá 👀',
      (PetNotificationCopyKind.critical, NotificationCopyVariant.b) =>
        'Oye… cuando puedas, ¿vienes a cuidarme un poquito?',
      (PetNotificationCopyKind.lastReminder, NotificationCopyVariant.a) =>
        'Sigo por aquí 👀 ¿vienes a verme?',
      (PetNotificationCopyKind.lastReminder, NotificationCopyVariant.b) =>
        'Oye… sólo venía a recordarte que sigo esperándote 💜',
    };
  }
}
