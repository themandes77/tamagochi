import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/storage_notice.dart';
import 'package:flutter_application_1/features/store/domain/store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class LocalStoreRepository implements StoreRepository {
  LocalStoreRepository({
    required this.storage,
    required this.noticeCenter,
  });

  static const String recoveryFailureMessage =
      'No fue posible recuperar parte del progreso.';

  final JsonFileStorage storage;
  final StorageNoticeCenter noticeCenter;

  @override
  Future<StoreSnapshot?> load() async {
    final result = await storage.read();
    switch (result.status) {
      case JsonStorageReadStatus.missing:
        return null;
      case JsonStorageReadStatus.resetRequired:
        final initial = StoreSnapshot.initial();
        await save(initial);
        noticeCenter.publish(
          const StorageNotice(
            code: 'store_progress_reset_after_failed_recovery',
            message: recoveryFailureMessage,
            moduleKey: 'store',
          ),
        );
        return initial;
      case JsonStorageReadStatus.current:
      case JsonStorageReadStatus.migrated:
      case JsonStorageReadStatus.temporaryRecovered:
      case JsonStorageReadStatus.backupRecovered:
      case JsonStorageReadStatus.partiallyRecovered:
        return StoreSnapshot.fromJson(result.payload!);
    }
  }

  @override
  Future<void> save(StoreSnapshot snapshot) {
    return storage.write(snapshot.toJson());
  }
}
