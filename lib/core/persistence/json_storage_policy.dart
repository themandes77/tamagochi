import 'package:flutter_application_1/core/persistence/storage_migration.dart';

enum JsonRecoverySource { current, temporary, backup }

class JsonRecoveryCandidate {
  const JsonRecoveryCandidate({
    required this.source,
    required this.rawText,
    this.payload,
    this.schemaVersion,
    this.failureCode,
  });

  final JsonRecoverySource source;
  final String rawText;
  final JsonPayload? payload;
  final int? schemaVersion;
  final String? failureCode;
}

abstract interface class JsonStoragePolicy {
  String get moduleKey;

  int get currentSchemaVersion;

  JsonPayload migrate({
    required int fromVersion,
    required JsonPayload payload,
  });

  void validatePayload(JsonPayload payload);

  JsonPayload? recoverPartial({
    required List<JsonRecoveryCandidate> candidates,
    required DateTime nowUtc,
  });
}
