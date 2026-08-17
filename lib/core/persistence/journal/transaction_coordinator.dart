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
  Future<void> _materializationTail = Future<void>.value();
  Object? _materializationFailure;
  StackTrace? _materializationFailureStack;
  final Map<String, List<_PendingWriteAheadTarget>>
      _pendingWriteAheadTargets =
      <String, List<_PendingWriteAheadTarget>>{};

  /// Ejecuta una transacción entre módulos.
  ///
  /// [baselineAlreadyDurable] solo debe usarse cuando un caller de la ruta
  /// tradicional ya garantizó que la fotografía actual de todos los
  /// participantes está persistida. Alimentar ya no usa esta ruta: desde
  /// schema 3 utiliza [commitWriteAhead].
  ///
  /// El valor por defecto conserva el comportamiento defensivo genérico: cada
  /// participante vuelve a durabilizar su estado antes de crear el journal.
  ///
  /// [deferSuccessfulCleanup] permite retirar la entrada del journal fuera del
  /// camino crítico una vez que todos los participantes ya alcanzaron target.
  /// No cambia el punto de commit: Pet + Store deben estar durables antes de
  /// que [execute] termine. Si el cleanup falla, recovery puede reconocer que
  /// todos los participantes ya están en target y limpiarlo después.
  Future<void> execute({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
    bool baselineAlreadyDurable = false,
    bool deferSuccessfulCleanup = false,
  }) {
    return _enqueue<void>(
      () => _executeInternal(
        transactionId: transactionId,
        type: type,
        targetPayloads: targetPayloads,
        baselineAlreadyDurable: baselineAlreadyDurable,
        deferSuccessfulCleanup: deferSuccessfulCleanup,
      ),
    );
  }

  Future<void> _executeInternal({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> targetPayloads,
    required bool baselineAlreadyDurable,
    required bool deferSuccessfulCleanup,
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
        await _resumeWithImmediateRecovery(
          existing,
          perf: perf,
          deferSuccessfulCleanup: deferSuccessfulCleanup,
        );
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
          // Ruta defensiva para callers genéricos de execute().
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
      await _resumeWithImmediateRecovery(
        transaction,
        perf: perf,
        deferSuccessfulCleanup: deferSuccessfulCleanup,
      );
    } finally {
      perf.finish();
    }
  }

  /// Compromete una transacción write-ahead.
  ///
  /// El único I/O durable que bloquea al caller es la escritura del journal.
  /// Una vez que esa evidencia existe, los targets se aplican al runtime y su
  /// materialización Pet/Store se serializa en segundo plano. Si la app muere,
  /// recovery completa los targets usando el journal schema 3.
  Future<void> commitWriteAhead({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> logicalBeforePayloads,
    required Map<String, Map<String, Object?>> durableBeforePayloads,
    required Map<String, Map<String, Object?>> targetPayloads,
  }) {
    return _enqueue<void>(
      () => _commitWriteAheadInternal(
        transactionId: transactionId,
        type: type,
        logicalBeforePayloads: logicalBeforePayloads,
        durableBeforePayloads: durableBeforePayloads,
        targetPayloads: targetPayloads,
      ),
    );
  }

  Future<void> _commitWriteAheadInternal({
    required String transactionId,
    required String type,
    required Map<String, Map<String, Object?>> logicalBeforePayloads,
    required Map<String, Map<String, Object?>> durableBeforePayloads,
    required Map<String, Map<String, Object?>> targetPayloads,
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
    if (_materializationFailure != null) {
      Error.throwWithStackTrace(
        _materializationFailure!,
        _materializationFailureStack ?? StackTrace.current,
      );
    }

    try {
      final existingTransactions = await repository.loadAll();
      perf.markLookup();
      for (final transaction in existingTransactions) {
        if (transaction.transactionId == transactionId) {
          _validateRepeatedRequest(transaction, type, targetPayloads);
          throw StateError(
            'La transacción write-ahead $transactionId ya fue comprometida.',
          );
        }
      }

      if (logicalBeforePayloads.length != targetPayloads.length ||
          durableBeforePayloads.length != targetPayloads.length) {
        throw ArgumentError(
          'before lógico, before durable y target deben contener los mismos '
          'participantes.',
        );
      }

      final now = clock.nowUtc();
      final records = <String, JournalParticipantRecord>{};
      for (final entry in targetPayloads.entries) {
        final key = entry.key;
        final participant = _requireWriteAheadParticipant(key);
        final logicalBefore = logicalBeforePayloads[key];
        final durableBefore = durableBeforePayloads[key];
        if (logicalBefore == null || durableBefore == null) {
          throw ArgumentError(
            'Falta before lógico o durable para el participante $key.',
          );
        }

        participant.validatePayload(logicalBefore);
        participant.validatePayload(durableBefore);
        participant.validatePayload(entry.value);

        final previousPending = _latestPendingWriteAheadTarget(key);
        final durableBeforeChecksum = previousPending?.targetChecksum ??
            checksumService.checksumCanonical(durableBefore);

        records[key] = JournalParticipantRecord(
          participantKey: key,
          beforePayload: deepCopyStringObjectMap(logicalBefore),
          beforeChecksum: checksumService.checksumCanonical(logicalBefore),
          durableBeforeChecksum: durableBeforeChecksum,
          targetChecksum: checksumService.checksumCanonical(entry.value),
          targetPayload: deepCopyStringObjectMap(entry.value),
        );
      }
      perf.markPrepared();

      final transaction = JournalTransaction(
        transactionId: transactionId,
        type: type,
        createdAt: now,
        updatedAt: now,
        participants: records,
      );

      // Este write es el commit: desde aquí recovery puede terminar la acción.
      await repository.upsert(transaction);
      perf.markJournalCommitted();
      _appendPendingWriteAheadTargets(transaction);

      // El runtime cambia solo después del commit durable del journal. La
      // materialización se agenda en finally para que incluso un fallo raro de
      // aplicación runtime conserve una ruta durable de recuperación.
      try {
        for (final record in transaction.participants.values) {
          final participant = _requireWriteAheadParticipant(
            record.participantKey,
          );
          await participant.applyRuntimePayload(record.targetPayload);
        }
        perf.markRuntimeApplied();
      } finally {
        _scheduleWriteAheadMaterialization(transaction);
        perf.markMaterializationQueued();
      }
    } finally {
      perf.finish();
    }
  }

  /// Espera la cola de materializaciones write-ahead ya comprometidas.
  ///
  /// Se usa al salir de Home, pausar/cerrar la app y en pruebas. No es parte
  /// del camino crítico de Alimentar, por lo que varios taps pueden comprometer
  /// nuevas entradas mientras esta cola continúa serialmente.
  Future<void> flushPendingMaterializations() async {
    await _materializationTail;
    final failure = _materializationFailure;
    if (failure != null) {
      Error.throwWithStackTrace(
        failure,
        _materializationFailureStack ?? StackTrace.current,
      );
    }
  }

  bool get hasPendingMaterializations =>
      _pendingWriteAheadTargets.values.any((items) => items.isNotEmpty);

  void _scheduleWriteAheadMaterialization(JournalTransaction transaction) {
    _materializationTail = _materializationTail.then((_) async {
      try {
        await _materializeWriteAhead(transaction);
      } catch (error, stackTrace) {
        _materializationFailure ??= error;
        _materializationFailureStack ??= stackTrace;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'nt_tamagochi.transaction_materialization',
            context: ErrorDescription(
              'al materializar ${transaction.transactionId}',
            ),
          ),
        );
        rethrow;
      }
    });

    // Evita un Future error sin observador; la cola original conserva el error
    // para que flush/new commits sigan fallando cerrado.
    unawaited(_materializationTail.catchError((Object _) {}));
  }

  Future<void> _materializeWriteAhead(JournalTransaction transaction) async {
    final perf = _WriteAheadMaterializationTrace(transaction.type);
    try {
      for (final record in transaction.participants.values) {
        final participant = _requireWriteAheadParticipant(
          record.participantKey,
        );
        final watch = Stopwatch()..start();
        await participant.persistPayload(record.targetPayload);
        watch.stop();
        perf.markParticipant(record.participantKey, watch.elapsed);
      }

      _removePendingWriteAheadTargets(transaction);

      // El target ya está durable en todos los participantes. Si esta limpieza
      // falla, no revertimos: recovery reconocerá targets y retirará el journal.
      final closeWatch = Stopwatch()..start();
      try {
        await repository.remove(transaction.transactionId);
        closeWatch.stop();
        perf.markJournalClosed(closeWatch.elapsed);
      } catch (error, stackTrace) {
        closeWatch.stop();
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'nt_tamagochi.transaction_cleanup',
            context: ErrorDescription(
              'al retirar un journal write-ahead ya materializado '
              '(${transaction.transactionId})',
            ),
          ),
        );
        perf.markCleanupFailed(closeWatch.elapsed);
      }
    } finally {
      perf.finish();
    }
  }

  void _appendPendingWriteAheadTargets(JournalTransaction transaction) {
    for (final record in transaction.participants.values) {
      final queue = _pendingWriteAheadTargets.putIfAbsent(
        record.participantKey,
        () => <_PendingWriteAheadTarget>[],
      );
      queue.add(
        _PendingWriteAheadTarget(
          transactionId: transaction.transactionId,
          targetChecksum: record.targetChecksum,
        ),
      );
    }
  }

  void _removePendingWriteAheadTargets(JournalTransaction transaction) {
    for (final record in transaction.participants.values) {
      final queue = _pendingWriteAheadTargets[record.participantKey];
      if (queue == null || queue.isEmpty) {
        continue;
      }
      queue.removeWhere(
        (item) => item.transactionId == transaction.transactionId,
      );
      if (queue.isEmpty) {
        _pendingWriteAheadTargets.remove(record.participantKey);
      }
    }
  }

  _PendingWriteAheadTarget? _latestPendingWriteAheadTarget(String key) {
    final queue = _pendingWriteAheadTargets[key];
    if (queue == null || queue.isEmpty) {
      return null;
    }
    return queue.last;
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
    bool deferSuccessfulCleanup = false,
  }) async {
    try {
      await _resume(
        transaction,
        perf: perf,
        deferSuccessfulCleanup: deferSuccessfulCleanup,
      );
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
  /// rollback atribuible y la compatibilidad con journals schema 1/2/3.
  Future<void> _resume(
    JournalTransaction transaction, {
    _TransactionPerformanceTrace? perf,
    bool deferSuccessfulCleanup = false,
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

      final matchesLogicalBefore = actualChecksum == record.beforeChecksum;
      final matchesDurableBefore =
          actualChecksum == record.durableBeforeChecksum;
      if (!matchesLogicalBefore && !matchesDurableBefore) {
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

    // Llegar aquí significa que todos los participantes ya alcanzaron target:
    // este es el commit durable real de la transacción. Alimentar puede sacar la
    // limpieza administrativa del camino perceptible sin relajar atomicidad.
    if (deferSuccessfulCleanup) {
      _scheduleSuccessfulCleanup(
        transactionId: current.transactionId,
        type: current.type,
      );
      perf?.markCleanupDeferred();
      return;
    }

    await repository.remove(current.transactionId);
    perf?.markJournalClosed();
  }

  void _scheduleSuccessfulCleanup({
    required String transactionId,
    required String type,
  }) {
    unawaited(
      _cleanupSuccessfulTransaction(
        transactionId: transactionId,
        type: type,
      ),
    );
  }

  Future<void> _cleanupSuccessfulTransaction({
    required String transactionId,
    required String type,
  }) async {
    final watch = Stopwatch()..start();
    try {
      await repository.remove(transactionId);
      watch.stop();
      if (kDebugMode) {
        debugPrint(
          '[NTI PERF][TX $type][CLEANUP] '
          'journalClose=${watch.elapsedMilliseconds}ms',
        );
      }
    } catch (error, stackTrace) {
      watch.stop();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.transaction_cleanup',
          context: ErrorDescription(
            'al retirar un journal ya comprometido ($transactionId)',
          ),
        ),
      );
      if (kDebugMode) {
        debugPrint(
          '[NTI PERF][TX $type][CLEANUP] failedAfter='
          '${watch.elapsedMilliseconds}ms',
        );
      }
    }
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

  WriteAheadTransactionParticipant _requireWriteAheadParticipant(String key) {
    final participant = _requireParticipant(key);
    if (participant is! WriteAheadTransactionParticipant) {
      throw StateError(
        'El participante $key no soporta materialización write-ahead.',
      );
    }
    return participant;
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

  void markPrepared() => _mark('prepare');

  void markJournalOpened() => _mark('journalOpen');

  void markJournalCommitted() => _mark('journalCommit');

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

  void markCleanupDeferred() => _mark('cleanupDeferred');

  void markMaterializationQueued() => _mark('materializeQueued');

  void markRuntimeApplied() => _mark('runtimeApply');

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

class _PendingWriteAheadTarget {
  const _PendingWriteAheadTarget({
    required this.transactionId,
    required this.targetChecksum,
  });

  final String transactionId;
  final String targetChecksum;
}

class _WriteAheadMaterializationTrace {
  _WriteAheadMaterializationTrace(this.type) : _total = Stopwatch()..start();

  final String type;
  final Stopwatch _total;
  final Map<String, Duration> _steps = <String, Duration>{};

  void markParticipant(String key, Duration elapsed) {
    if (kDebugMode) {
      _steps[key] = elapsed;
    }
  }

  void markJournalClosed(Duration elapsed) {
    if (kDebugMode) {
      _steps['journalClose'] = elapsed;
    }
  }

  void markCleanupFailed(Duration elapsed) {
    if (kDebugMode) {
      _steps['journalCloseFailed'] = elapsed;
    }
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
      '[NTI PERF][TX $type][MATERIALIZE] '
      'total=${_total.elapsedMilliseconds}ms'
      '${details.isEmpty ? '' : ' | $details'}',
    );
  }
}

