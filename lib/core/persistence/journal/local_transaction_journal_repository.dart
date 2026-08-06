import 'dart:async';

import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/json_file_storage.dart';

class LocalTransactionJournalRepository
    implements TransactionJournalRepository {
  LocalTransactionJournalRepository({required this.storage});

  final JsonFileStorage storage;
  Future<void> _operationTail = Future<void>.value();

  @override
  Future<List<JournalTransaction>> loadAll() {
    return _enqueue<List<JournalTransaction>>(_loadAllInternal);
  }

  @override
  Future<void> upsert(JournalTransaction transaction) {
    return _enqueue<void>(() async {
      final transactions = await _loadAllInternal();
      final byId = <String, JournalTransaction>{
        for (final item in transactions) item.transactionId: item,
      };
      byId[transaction.transactionId] = transaction;
      await _saveAll(byId.values.toList(growable: false));
    });
  }

  @override
  Future<void> remove(String transactionId) {
    return _enqueue<void>(() async {
      final transactions = await _loadAllInternal();
      transactions.removeWhere(
        (transaction) => transaction.transactionId == transactionId,
      );
      await _saveAll(transactions);
    });
  }

  Future<List<JournalTransaction>> _loadAllInternal() async {
    final result = await storage.read();
    if (result.status == JsonStorageReadStatus.missing ||
        result.status == JsonStorageReadStatus.resetRequired) {
      await _saveAll(<JournalTransaction>[]);
      return <JournalTransaction>[];
    }

    final values = result.payload?['transactions'];
    if (values is! List) {
      throw const FormatException('transactions debe ser una lista.');
    }
    return values
        .map(
          (value) => JournalTransaction.fromJson(
            requireStringObjectMap(value, description: 'transaction'),
          ),
        )
        .toList(growable: true);
  }

  Future<void> _saveAll(List<JournalTransaction> transactions) {
    return storage.write(<String, Object?>{
      'transactions': transactions
          .map((transaction) => transaction.toJson())
          .toList(growable: false),
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}
