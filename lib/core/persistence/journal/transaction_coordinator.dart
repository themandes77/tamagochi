import 'dart:async';

import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/checksum_service.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';

class TransactionConflictException implements Exception {
  const TransactionConflictException({
    required this.transactionId,
    required this.participantKey,
  });

  final String transactionId;
  final String participantKey;

  @override
  String toString() {
    return 'La transacción $transactionId encontró un conflicto en '
        '$participantKey.';
  }
}

class CrossModuleTransactionCoordinator {
  CrossModuleTransactionCoordinator({
    required this.repository,
    required Iterable<TransactionParticipant> participants,
    required this.checksumService,
    required this.clock,
  }) : _participants = <String, TransactionParticipant>{
         for (final participant in participants)
           participant.participantKey: participant,
       };

  final TransactionJournalRepository repository;
  final Map<String, TransactionParticipant> _participants;
  final ChecksumService checksumService;
  final AppClock clock;

  Future<void> _operationTail = Future<void>.value();

  Future<void> execute({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
  }) {
    return _enqueue<void>(
      () => _executeInternal(
        transactionId: transactionId,
        type: type,
        targetPayloads: targetPayloads,
      ),
    );
  }

  Future<void> _executeInternal({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
  }) async {
    if (transactionId.trim().isEmpty || type.trim().isEmpty) {
      throw ArgumentError('transactionId y type no pueden estar vacíos.');
    }
    if (targetPayloads.isEmpty) {
      throw ArgumentError.value(
        targetPayloads,
        'targetPayloads',
        'La transacción requiere al menos un participante.',
      );
    }

    final existingTransactions = await repository.loadAll();
    JournalTransaction? existing;
    for (final transaction in existingTransactions) {
      if (transaction.transactionId == transactionId) {
        existing = transaction;
        break;
      }
    }
    if (existing != null) {
      _validateRepeatedRequest(existing, type, targetPayloads);
      await _resume(existing);
      return;
    }

    final now = clock.nowUtc();
    final records = <String, JournalParticipantRecord>{};
    for (final entry in targetPayloads.entries) {
      final participant = _requireParticipant(entry.key);
      participant.validatePayload(entry.value);
      final beforePayload = await participant.readPayload();
      participant.validatePayload(beforePayload);

      // El journal solo puede reconciliar contra una línea base que ya exista
      // de forma duradera. Guardar el mismo estado antes de abrir la operación
      // evita que una fotografía únicamente en memoria produzca un falso
      // conflicto después de reiniciar la aplicación.
      await participant.writePayload(beforePayload);
      final durableBeforePayload = await participant.readPayload();
      final durableBeforeChecksum = checksumService.checksumCanonical(
        durableBeforePayload,
      );

      records[entry.key] = JournalParticipantRecord(
        participantKey: entry.key,
        beforeChecksum: durableBeforeChecksum,
        targetChecksum: checksumService.checksumCanonical(entry.value),
        targetPayload: deepCopyStringObjectMap(entry.value),
      );
    }

    final transaction = JournalTransaction(
      transactionId: transactionId,
      type: type,
      createdAt: now,
      updatedAt: now,
      participants: records,
    );
    await repository.upsert(transaction);
    await _resume(transaction);
  }

  Future<void> recoverPending() {
    return _enqueue<void>(_recoverPendingInternal);
  }

  Future<void> _recoverPendingInternal() async {
    final transactions = await repository.loadAll();
    for (final transaction in transactions) {
      if (transaction.status == JournalTransactionStatus.completed) {
        await repository.remove(transaction.transactionId);
        continue;
      }
      await _resume(transaction);
    }
  }

  Future<void> _resume(JournalTransaction transaction) async {
    var current = transaction;

    for (final participantEntry in current.participants.entries) {
      final key = participantEntry.key;
      var record = participantEntry.value;
      final participant = _requireParticipant(key);
      final actualPayload = await participant.readPayload();
      final actualChecksum = checksumService.checksumCanonical(actualPayload);

      if (actualChecksum == record.targetChecksum) {
        if (record.status != JournalParticipantStatus.applied) {
          record = record.copyWith(
            status: JournalParticipantStatus.applied,
            appliedAt: clock.nowUtc(),
          );
          current = _replaceParticipant(current, record);
          await repository.upsert(current);
        }
        continue;
      }

      if (actualChecksum != record.beforeChecksum) {
        record = record.copyWith(status: JournalParticipantStatus.conflict);
        current = _replaceParticipant(
          current,
          record,
          status: JournalTransactionStatus.conflict,
        );
        await repository.upsert(current);
        throw TransactionConflictException(
          transactionId: current.transactionId,
          participantKey: key,
        );
      }

      participant.validatePayload(record.targetPayload);
      await participant.writePayload(record.targetPayload);
      final verifiedPayload = await participant.readPayload();
      final verifiedChecksum = checksumService.checksumCanonical(
        verifiedPayload,
      );
      if (verifiedChecksum != record.targetChecksum) {
        throw StateError(
          'El participante $key no alcanzó el estado objetivo de la '
          'transacción ${current.transactionId}.',
        );
      }

      record = record.copyWith(
        status: JournalParticipantStatus.applied,
        appliedAt: clock.nowUtc(),
      );
      current = _replaceParticipant(current, record);
      await repository.upsert(current);
    }

    final allApplied = current.participants.values.every(
      (record) => record.status == JournalParticipantStatus.applied,
    );
    if (!allApplied) {
      return;
    }

    current = current.copyWith(
      status: JournalTransactionStatus.completed,
      updatedAt: clock.nowUtc(),
    );
    await repository.upsert(current);
    await repository.remove(current.transactionId);
  }

  JournalTransaction _replaceParticipant(
    JournalTransaction transaction,
    JournalParticipantRecord replacement, {
    JournalTransactionStatus? status,
  }) {
    final participants = Map<String, JournalParticipantRecord>.from(
      transaction.participants,
    );
    participants[replacement.participantKey] = replacement;
    return transaction.copyWith(
      participants: participants,
      status: status,
      updatedAt: clock.nowUtc(),
    );
  }

  void _validateRepeatedRequest(
    JournalTransaction existing,
    String type,
    Map<String, Map<String, Object?>> targetPayloads,
  ) {
    if (existing.type != type ||
        existing.participants.length != targetPayloads.length) {
      throw StateError(
        'El transactionId ${existing.transactionId} ya pertenece a otra '
        'operación.',
      );
    }

    for (final entry in targetPayloads.entries) {
      final record = existing.participants[entry.key];
      final requestedChecksum = checksumService.checksumCanonical(entry.value);
      if (record == null || record.targetChecksum != requestedChecksum) {
        throw StateError(
          'El transactionId ${existing.transactionId} fue reutilizado con '
          'un objetivo diferente.',
        );
      }
    }
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

  TransactionParticipant _requireParticipant(String key) {
    final participant = _participants[key];
    if (participant == null) {
      throw StateError('No existe un participante transaccional para $key.');
    }
    return participant;
  }
}
