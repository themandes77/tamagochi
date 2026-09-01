import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';

class JournalStoragePolicy implements JsonStoragePolicy {
  JournalStoragePolicy({JsonMigrationRegistry? migrations})
    : migrations = migrations ?? _defaultMigrations();

  final JsonMigrationRegistry migrations;

  @override
  String get moduleKey => 'transactionJournal';

  @override
  int get currentSchemaVersion => migrations.currentVersion;

  @override
  Map<String, Object?> migrate({
    required int fromVersion,
    required Map<String, Object?> payload,
  }) {
    return migrations.migrate(fromVersion: fromVersion, payload: payload);
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    final transactions = payload['transactions'];
    if (transactions is! List) {
      throw const FormatException('transactions debe ser una lista.');
    }
    for (final value in transactions) {
      JournalTransaction.fromJson(
        requireStringObjectMap(value, description: 'transaction'),
      );
    }
  }

  @override
  Map<String, Object?>? recoverPartial({
    required List<JsonRecoveryCandidate> candidates,
    required DateTime nowUtc,
  }) {
    final ordered = <JsonRecoveryCandidate>[
      ...candidates.where((item) => item.source == JsonRecoverySource.current),
      ...candidates.where((item) => item.source == JsonRecoverySource.backup),
      ...candidates.where(
        (item) => item.source == JsonRecoverySource.temporary,
      ),
    ];

    final recovered = <String, JournalTransaction>{};
    for (final candidate in ordered) {
      final candidatePayload = _normalizeCandidatePayload(candidate);
      final transactions = candidatePayload?['transactions'];
      if (transactions is! List) {
        continue;
      }
      for (final value in transactions) {
        try {
          final transaction = JournalTransaction.fromJson(
            requireStringObjectMap(value, description: 'transaction'),
          );
          recovered.putIfAbsent(transaction.transactionId, () => transaction);
        } catch (_) {
          continue;
        }
      }
    }

    if (recovered.isEmpty) {
      return null;
    }
    return <String, Object?>{
      'transactions': recovered.values
          .map((transaction) => transaction.toJson())
          .toList(growable: false),
    };
  }

  Map<String, Object?>? _normalizeCandidatePayload(
    JsonRecoveryCandidate candidate,
  ) {
    final payload = candidate.payload;
    if (payload == null) {
      return null;
    }

    final version = candidate.schemaVersion;
    if (version == null || version == currentSchemaVersion) {
      return payload;
    }

    try {
      return migrate(fromVersion: version, payload: payload);
    } catch (_) {
      return null;
    }
  }

  static JsonMigrationRegistry _defaultMigrations() {
    return JsonMigrationRegistry(
      currentVersion: 3,
      steps: <int, JsonMigrationStep>{
        1: _migrateV1ToV2,
        2: _migrateV2ToV3,
      },
    );
  }

  static JsonPayload _migrateV1ToV2(JsonPayload payload) {
    final values = payload['transactions'];
    if (values is! List) {
      return Map<String, Object?>.from(payload);
    }

    final migratedTransactions = <Object?>[];
    for (final value in values) {
      if (value is! Map) {
        migratedTransactions.add(value);
        continue;
      }
      final transaction = Map<String, Object?>.from(value.cast<String, Object?>());
      final participants = transaction['participants'];
      if (participants is List) {
        transaction['participants'] = participants.map<Object?>((participant) {
          if (participant is! Map) {
            return participant;
          }
          final record = Map<String, Object?>.from(
            participant.cast<String, Object?>(),
          );
          record.putIfAbsent('beforePayload', () => null);
          return record;
        }).toList(growable: false);
      }
      migratedTransactions.add(transaction);
    }

    return <String, Object?>{
      ...payload,
      'transactions': migratedTransactions,
    };
  }
  static JsonPayload _migrateV2ToV3(JsonPayload payload) {
    final values = payload['transactions'];
    if (values is! List) {
      return Map<String, Object?>.from(payload);
    }

    final migratedTransactions = <Object?>[];
    for (final value in values) {
      if (value is! Map) {
        migratedTransactions.add(value);
        continue;
      }
      final transaction = Map<String, Object?>.from(
        value.cast<String, Object?>(),
      );
      final participants = transaction['participants'];
      if (participants is List) {
        transaction['participants'] = participants.map<Object?>((participant) {
          if (participant is! Map) {
            return participant;
          }
          final record = Map<String, Object?>.from(
            participant.cast<String, Object?>(),
          );
          final beforeChecksum = record['beforeChecksum'];
          if (beforeChecksum is String && beforeChecksum.isNotEmpty) {
            record.putIfAbsent(
              'durableBeforeChecksum',
              () => beforeChecksum,
            );
          }
          return record;
        }).toList(growable: false);
      }
      migratedTransactions.add(transaction);
    }

    return <String, Object?>{
      ...payload,
      'transactions': migratedTransactions,
    };
  }

}
