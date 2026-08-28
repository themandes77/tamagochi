import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/storage_directory_provider.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';

/// Web-safe storage used by the browser preview.
///
/// The native app keeps using [JsonFileStorage]. Browser sessions keep their
/// data in memory so unsupported `dart:io` and `path_provider` APIs are never
/// invoked while the app is being reviewed from Safari.
class InMemoryJsonFileStorage extends JsonFileStorage {
  InMemoryJsonFileStorage({
    required super.fileName,
    required super.policy,
    required super.checksumService,
    required super.clock,
  }) : super(directoryProvider: const ApplicationSupportDirectoryProvider());

  JsonPayload? _payload;

  @override
  Future<JsonStorageReadResult> read() async {
    final payload = _payload;
    if (payload == null) {
      return const JsonStorageReadResult(status: JsonStorageReadStatus.missing);
    }
    return JsonStorageReadResult(
      status: JsonStorageReadStatus.current,
      payload: deepCopyStringObjectMap(payload),
    );
  }

  @override
  Future<void> write(JsonPayload payload) async {
    final snapshot = deepCopyStringObjectMap(payload);
    policy.validatePayload(snapshot);
    _payload = snapshot;
  }

  @override
  Future<void> deleteAll() async {
    _payload = null;
  }
}
