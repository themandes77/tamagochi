import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';

class JournalStoragePolicy implements JsonStoragePolicy {
  JournalStoragePolicy({JsonMigrationRegistry? migrations})
    : migrations = migrations ?? JsonMigrationRegistry(currentVersion: 1);

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
      final transactions = candidate.payload?['transactions'];
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
}
