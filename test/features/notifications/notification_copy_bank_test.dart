import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/notifications/domain/notification_copy_bank.dart';
import 'package:flutter_application_1/features/notifications/domain/pet_notification_plan.dart';

void main() {
  const bank = NotificationCopyBank();

  test('mantiene el branding y los copies aprobados', () {
    expect(NotificationCopyBank.title, 'My NTI');
    expect(
      bank.bodyFor(
        PetNotificationCopyKind.lastReminder,
        NotificationCopyVariant.b,
      ),
      'Oye… sólo venía a recordarte que sigo esperándote 💜',
    );
    expect(
      bank.bodyFor(
        PetNotificationCopyKind.hunger,
        NotificationCopyVariant.a,
      ),
      '¿Guardaste algo para mí? 👀',
    );
  });
}
