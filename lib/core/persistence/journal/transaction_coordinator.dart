import 'dart:async';

import 'package:flutter/foundation.dart';
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

class TransactionRecoveryException implements Exception {
  const TransactionRecoveryException({
    required this.transactionId,
    required this.message,
    this.participantKey,
  });

  final String transactionId;
  final String message;
  final String? participantKey;

  @override
  String toString() {
    final participant = participantKey == null ? '' : ' ($participantKey)';
    return 'No fue posible recuperar la transacción $transactionId'
        '$participant: $message';
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

  /// Ejecuta una transacción entre módulos.
  ///
  /// [baselineAlreadyDurable] solo debe usarse cuando el caller ya garantizó
  /// que la fotografía actual de todos los participantes está persistida. Es
  /// el caso de Alimentar: Store espera sus saves pendientes y Pet abre una
  /// sección exclusiva que checkpointa el baseline antes de entrar aquí.
  ///
  /// El valor por defecto conserva el comportamiento defensivo genérico: cada
  /// participante vuelve a durabilizar su estado antes de crear el journal.
  Future<void> execute({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
    bool baselineAlreadyDurable = false,
  }) {
    return _enqueue<void>(
      () => _executeInternal(
        transactionId: transactionId,
        type: type,
        targetPayloads: targetPayloads,
        baselineAlreadyDurable: baselineAlreadyDurable,
      ),
    );
  }

  Future<void> _executeInternal({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
    required bool baselineAlreadyDurable,
  }) async {
    final perf = _TransactionPerformanceTrace(type);
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

    try {
      final existingTransactions = await repository.loadAll();
      perf.markLookup();
      JournalTransaction? existing;
      for (final transaction in existingTransactions) {
        if (transaction.transactionId == transactionId) {
          existing = transaction;
          break;
        }
      }
      if (existing != null) {
        _validateRepeatedRequest(existing, type, targetPayloads);
        await _resumeWithImmediateRecovery(existing, perf: perf);
        return;
      }

      final now = clock.nowUtc();
      final records = <String, JournalParticipantRecord>{};
      for (final entry in targetPayloads.entries) {
        final participant = _requireParticipant(entry.key);
        participant.validatePayload(entry.value);
        var beforePayload = await participant.readPayload();
        participant.validatePayload(beforePayload);

        if (!baselineAlreadyDurable) {
          // Ruta defensiva para callers genéricos. Alimentar evita este I/O
          // porque ya checkpointó Pet y esperó los saves de Store.
          await participant.writePayload(beforePayload);
          beforePayload = await participant.readPayload();
          participant.validatePayload(beforePayload);
        }

        records[entry.key] = JournalParticipantRecord(
          participantKey: entry.key,
          beforePayload: deepCopyStringObjectMap(beforePayload),
          beforeChecksum: checksumService.checksumCanonical(beforePayload),
          targetChecksum: checksumService.checksumCanonical(entry.value),
          targetPayload: deepCopyStringObjectMap(entry.value),
        );
      }
      perf.markBaseline();

      final transaction = JournalTransaction(
        transactionId: transactionId,
        type: type,
        createdAt: now,
        updatedAt: now,
        participants: records,
      );
      await repository.upsert(transaction);
      perf.markJournalOpened();
      await _resumeWithImmediateRecovery(transaction, perf: perf);
    } finally {
      perf.finish();
    }
  }

  Future<void> recoverPending() {
    return _enqueue<void>(_recoverPendingInternal);
  }

  Future<void> _recoverPendingInternal() async {
    final transactions = await repository.loadAll();
    for (final transaction in transactions) {
      switch (transaction.status) {
        case JournalTransactionStatus.completed:
          await repository.remove(transaction.transactionId);
          break;
        case JournalTransactionStatus.conflict:
          await _recoverConflict(transaction);
          break;
        case JournalTransactionStatus.pending:
          try {
            await _resume(transaction);
          } on TransactionConflictException {
            final updated = await _findTransaction(transaction.transactionId);
            if (updated == null) {
              rethrow;
            }
            await _recoverConflict(updated);
          }
          break;
      }
    }
  }

  Future<void> _resumeWithImmediateRecovery(
    JournalTransaction transaction, {
    _TransactionPerformanceTrace? perf,
  }) async {
    try {
      await _resume(transaction, perf: perf);
    } on TransactionConflictException {
      final updated = await _findTransaction(transaction.transactionId);
      if (updated != null &&
          updated.status == JournalTransactionStatus.conflict) {
        await _recoverConflict(updated);
      }
      rethrow;
    }
  }

  /// Continúa una transacción usando el propio estado durable como evidencia.
  ///
  /// En el camino exitoso no escribimos `participant=applied` ni
  /// `transaction=completed` después de cada paso. El journal ya contiene
  /// before + target; si ocurre un crash, recovery puede distinguir ambos por
  /// checksum y continuar. Esto elimina varias escrituras seguras redundantes.
  ///
  /// Si aparece un conflicto real sí persistimos UNA fotografía de conflicto
  /// con los participantes que ya alcanzaron target, para conservar el
  /// rollback atribuible y la compatibilidad con journals schema 1/2.
  Future<void> _resume(
    JournalTransaction transaction, {
    _TransactionPerformanceTrace? perf,
  }) async {
    var current = transaction;

    for (final participantEntry in current.participants.entries) {
      final key = participantEntry.key;
      var record = current.participants[key]!;
      final participant = _requireParticipant(key);
      final participantWatch = Stopwatch()..start();
      final actualPayload = await participant.readPayload();
      final actualChecksum = checksumService.checksumCanonical(actualPayload);

      if (actualChecksum == record.targetChecksum) {
        if (record.status != JournalParticipantStatus.applied) {
          record = record.copyWith(
            status: JournalParticipantStatus.applied,
            appliedAt: clock.nowUtc(),
          );
          current = _replaceParticipant(current, record);
        }
        participantWatch.stop();
        perf?.markParticipant(key, participantWatch.elapsed);
        continue;
      }

      if (actualChecksum != record.beforeChecksum) {
        // Un journal viejo puede afirmar que este participante sí fue aplicado.
        // Si ahora no coincide con before ni target, no podemos atribuir de
        // forma segura su estado actual a la transacción.
        if (record.status == JournalParticipantStatus.applied) {
          throw TransactionRecoveryException(
            transactionId: current.transactionId,
            participantKey: key,
            message:
                'el participante aplicado cambió a un estado que no coincide '
                'ni con before ni con target; no se sobrescribirá.',
          );
        }

        record = record.copyWith(status: JournalParticipantStatus.conflict);
        current = _replaceParticipant(
          current,
          record,
          status: JournalTransactionStatus.conflict,
        );

        // El happy path no checkpointa estados intermedios. Solo un conflicto
        // necesita esta escritura para dejar evidencia explícita del rollback.
        await repository.upsert(current);
        participantWatch.stop();
        perf?.markParticipant(key, participantWatch.elapsed);
        throw TransactionConflictException(
          transactionId: current.transactionId,
          participantKey: key,
        );
      }

      participant.validatePayload(record.targetPayload);
      await participant.writePayload(record.targetPayload);

      // La verificación posterior se conserva. readPayload consulta el estado
      // runtime de nuestros participantes actuales (no vuelve a guardar nada),
      // por lo que mantiene la garantía sin reintroducir el I/O redundante.
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
      participantWatch.stop();
      perf?.markParticipant(key, participantWatch.elapsed);
    }

    // Si todos los participantes alcanzaron target, el journal puede retirarse
    // directamente. Si la app cae durante esta escritura, al siguiente arranque
    // encontrará de nuevo todos los targets y repetirá este remove de forma
    // idempotente.
    await repository.remove(current.transactionId);
    perf?.markJournalClosed();
  }

  Future<void> _recoverConflict(JournalTransaction transaction) async {
    final appliedRecords = transaction.participants.values
        .where((record) => record.status == JournalParticipantStatus.applied)
        .toList(growable: false);

    // Un conflict persistido con cero participantes applied representa una
    // operación que nunca llegó a cambiar el estado transaccional. Es seguro
    // abortarla. Este es exactamente el patrón de los journals schema 1
    // generados por el conflicto de alimentación encontrado en pruebas.
    if (appliedRecords.isEmpty) {
      await repository.remove(transaction.transactionId);
      return;
    }

    for (final record in transaction.participants.values) {
      final participant = _requireParticipant(record.participantKey);
      final actualPayload = await participant.readPayload();
      final actualChecksum = checksumService.checksumCanonical(actualPayload);

      if (record.status != JournalParticipantStatus.applied) {
        // Nunca atribuimos a la transacción un cambio de un participante que
        // no quedó marcado como applied. Cualquier estado externo se conserva.
        continue;
      }

      if (actualChecksum == record.beforeChecksum) {
        // Ya está en baseline (por ejemplo, un rollback previo interrumpido).
        continue;
      }

      if (actualChecksum != record.targetChecksum) {
        throw TransactionRecoveryException(
          transactionId: transaction.transactionId,
          participantKey: record.participantKey,
          message:
              'el participante aplicado cambió a un estado que no coincide '
              'ni con before ni con target; no se sobrescribirá.',
        );
      }

      final beforePayload = record.beforePayload;
      if (beforePayload == null) {
        throw TransactionRecoveryException(
          transactionId: transaction.transactionId,
          participantKey: record.participantKey,
          message:
              'el journal legacy no contiene beforePayload para revertir '
              'de forma segura una aplicación parcial.',
        );
      }

      participant.validatePayload(beforePayload);
      await participant.writePayload(beforePayload);
      final verifiedPayload = await participant.readPayload();
      final verifiedChecksum = checksumService.checksumCanonical(
        verifiedPayload,
      );
      if (verifiedChecksum != record.beforeChecksum) {
        throw TransactionRecoveryException(
          transactionId: transaction.transactionId,
          participantKey: record.participantKey,
          message: 'el rollback no alcanzó el estado anterior esperado.',
        );
      }
    }

    await repository.remove(transaction.transactionId);
  }

  Future<JournalTransaction?> _findTransaction(String transactionId) async {
    final transactions = await repository.loadAll();
    for (final transaction in transactions) {
      if (transaction.transactionId == transactionId) {
        return transaction;
      }
    }
    return null;
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

class _TransactionPerformanceTrace {
  _TransactionPerformanceTrace(this.type)
    : _total = Stopwatch()..start(),
      _lap = Stopwatch()..start();

  final String type;
  final Stopwatch _total;
  final Stopwatch _lap;
  final Map<String, Duration> _steps = <String, Duration>{};

  void markLookup() => _mark('lookup');

  void markBaseline() => _mark('baseline');

  void markJournalOpened() => _mark('journalOpen');

  void markParticipant(String key, Duration elapsed) {
    if (!kDebugMode) {
      return;
    }
    _steps[key] = elapsed;
    _lap
      ..reset()
      ..start();
  }

  void markJournalClosed() => _mark('journalClose');

  void _mark(String name) {
    if (!kDebugMode) {
      return;
    }
    _steps[name] = _lap.elapsed;
    _lap
      ..reset()
      ..start();
  }

  void finish() {
    if (!kDebugMode) {
      return;
    }
    _total.stop();
    final details = _steps.entries
        .map((entry) => '${entry.key}=${entry.value.inMilliseconds}ms')
        .join(' | ');
    debugPrint(
      '[NTI PERF][TX $type] total=${_total.elapsedMilliseconds}ms'
      '${details.isEmpty ? '' : ' | $details'}',
    );
  }
}
