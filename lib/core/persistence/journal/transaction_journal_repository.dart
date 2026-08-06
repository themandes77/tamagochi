import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';

abstract interface class TransactionJournalRepository {
  Future<List<JournalTransaction>> loadAll();

  Future<void> upsert(JournalTransaction transaction);

  Future<void> remove(String transactionId);
}
