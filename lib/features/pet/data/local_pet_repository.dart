import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/storage_notice.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class LocalPetRepository implements PetRepository {
  LocalPetRepository({
    required this.storage,
    required this.clock,
    required this.noticeCenter,
    this.rules = const PetRules(),
  });

  static const String recoveryFailureMessage =
      'No fue posible recuperar parte del progreso.';

  final JsonFileStorage storage;
  final AppClock clock;
  final StorageNoticeCenter noticeCenter;
  final PetRules rules;

  @override
  Future<PetState?> load() async {
    final result = await storage.read();
    switch (result.status) {
      case JsonStorageReadStatus.missing:
        return null;
      case JsonStorageReadStatus.resetRequired:
        final initial = PetState.initial(
          nowUtc: clock.nowUtc(),
          rules: rules,
        );
        await save(initial);
        noticeCenter.publish(
          const StorageNotice(
            code: 'pet_progress_reset_after_failed_recovery',
            message: recoveryFailureMessage,
            moduleKey: 'pet',
          ),
        );
        return initial;
      case JsonStorageReadStatus.current:
      case JsonStorageReadStatus.migrated:
      case JsonStorageReadStatus.temporaryRecovered:
      case JsonStorageReadStatus.backupRecovered:
      case JsonStorageReadStatus.partiallyRecovered:
        return PetState.fromJson(result.payload!, rules: rules);
    }
  }

  @override
  Future<void> save(PetState state) {
    return storage.write(state.toJson());
  }
}
