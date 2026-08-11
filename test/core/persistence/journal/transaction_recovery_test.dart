import 'dart:io';

import 'package:flutter_application_1/core/persistence/checksum_service.dart';
import 'package:flutter_application_1/core/persistence/journal/journal_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/journal/local_transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/storage_directory_provider.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const checksum = Sha256ChecksumService();

  test('journal schema 1 migrates to schema 2 without inventing beforePayload', () {
    final policy = JournalStoragePolicy();
    final migrated = policy.migrate(
      fromVersion: 1,
      payload: <String, Object?>{
        'transactions': <Object?>[
          <String, Object?>{
            'transactionId': 'legacy',
            'type': 'consume_food',
            'createdAt': DateTime.utc(2026, 8, 10).toIso8601String(),
            'updatedAt': DateTime.utc(2026, 8, 10).toIso8601String(),
            'status': 'conflict',
            'participants': <Object?>[
              <String, Object?>{
                'participantKey': 'pet',
                'beforeChecksum': 'before',
                'targetChecksum': 'target',
                'targetPayload': <String, Object?>{'value': 2},
                'status': 'conflict',
                'appliedAt': null,
              },
            ],
          },
        ],
      },
    );

    expect(policy.currentSchemaVersion, 2);
    final transaction = JournalTransaction.fromJson(
      (migrated['transactions']! as List).single as Map<String, Object?>,
    );
    expect(transaction.participants['pet']!.beforePayload, isNull);
  });

  test('removes every legacy conflict with zero applied participants', () async {
    final repository = _MemoryJournalRepository();
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 1});
    final store = _MemoryParticipant('store', <String, Object?>{'value': 10});
    final now = DateTime.utc(2026, 8, 10, 18, 30);

    for (var index = 0; index < 3; index++) {
      repository.items['feed_$index'] = JournalTransaction(
        transactionId: 'feed_$index',
        type: 'consume_food',
        createdAt: now,
        updatedAt: now,
        status: JournalTransactionStatus.conflict,
        participants: <String, JournalParticipantRecord>{
          'pet': JournalParticipantRecord(
            participantKey: 'pet',
            beforeChecksum: checksum.checksumCanonical(<String, Object?>{'value': 1}),
            targetChecksum: checksum.checksumCanonical(<String, Object?>{'value': 2}),
            targetPayload: <String, Object?>{'value': 2},
            status: JournalParticipantStatus.conflict,
          ),
          'store': JournalParticipantRecord(
            participantKey: 'store',
            beforeChecksum: checksum.checksumCanonical(<String, Object?>{'value': 10}),
            targetChecksum: checksum.checksumCanonical(<String, Object?>{'value': 9}),
            targetPayload: <String, Object?>{'value': 9},
          ),
        },
      );
    }

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet, store],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.recoverPending();

    expect(repository.items, isEmpty);
    expect(pet.payload, <String, Object?>{'value': 1});
    expect(store.payload, <String, Object?>{'value': 10});
  });

  test('rolls back applied participant and preserves external non-applied state', () async {
    final repository = _MemoryJournalRepository();
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 2});
    final store = _MemoryParticipant('store', <String, Object?>{'value': 99});
    final now = DateTime.utc(2026, 8, 10, 18, 30);
    final petBefore = <String, Object?>{'value': 1};
    final petTarget = <String, Object?>{'value': 2};
    final storeBefore = <String, Object?>{'value': 10};
    final storeTarget = <String, Object?>{'value': 9};

    repository.items['partial'] = JournalTransaction(
      transactionId: 'partial',
      type: 'consume_food',
      createdAt: now,
      updatedAt: now,
      status: JournalTransactionStatus.conflict,
      participants: <String, JournalParticipantRecord>{
        'pet': JournalParticipantRecord(
          participantKey: 'pet',
          beforePayload: petBefore,
          beforeChecksum: checksum.checksumCanonical(petBefore),
          targetChecksum: checksum.checksumCanonical(petTarget),
          targetPayload: petTarget,
          status: JournalParticipantStatus.applied,
          appliedAt: now,
        ),
        'store': JournalParticipantRecord(
          participantKey: 'store',
          beforePayload: storeBefore,
          beforeChecksum: checksum.checksumCanonical(storeBefore),
          targetChecksum: checksum.checksumCanonical(storeTarget),
          targetPayload: storeTarget,
          status: JournalParticipantStatus.conflict,
        ),
      },
    );

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet, store],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.recoverPending();

    expect(repository.items, isEmpty);
    expect(pet.payload, petBefore);
    expect(store.payload, <String, Object?>{'value': 99});
  });

  test('fails closed when an applied participant is ambiguous', () async {
    final repository = _MemoryJournalRepository();
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 3});
    final now = DateTime.utc(2026, 8, 10, 18, 30);
    final before = <String, Object?>{'value': 1};
    final target = <String, Object?>{'value': 2};

    repository.items['ambiguous'] = JournalTransaction(
      transactionId: 'ambiguous',
      type: 'consume_food',
      createdAt: now,
      updatedAt: now,
      status: JournalTransactionStatus.conflict,
      participants: <String, JournalParticipantRecord>{
        'pet': JournalParticipantRecord(
          participantKey: 'pet',
          beforePayload: before,
          beforeChecksum: checksum.checksumCanonical(before),
          targetChecksum: checksum.checksumCanonical(target),
          targetPayload: target,
          status: JournalParticipantStatus.applied,
          appliedAt: now,
        ),
      },
    );

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await expectLater(
      coordinator.recoverPending(),
      throwsA(isA<TransactionRecoveryException>()),
    );
    expect(repository.items.containsKey('ambiguous'), isTrue);
    expect(pet.payload, <String, Object?>{'value': 3});
  });

  test('legacy partial application without beforePayload cannot be guessed', () async {
    final repository = _MemoryJournalRepository();
    final now = DateTime.utc(2026, 8, 10, 18, 30);
    final before = <String, Object?>{'value': 1};
    final target = <String, Object?>{'value': 2};
    final pet = _MemoryParticipant('pet', target);

    repository.items['legacy_partial'] = JournalTransaction(
      transactionId: 'legacy_partial',
      type: 'consume_food',
      createdAt: now,
      updatedAt: now,
      status: JournalTransactionStatus.conflict,
      participants: <String, JournalParticipantRecord>{
        'pet': JournalParticipantRecord(
          participantKey: 'pet',
          beforeChecksum: checksum.checksumCanonical(before),
          targetChecksum: checksum.checksumCanonical(target),
          targetPayload: target,
          status: JournalParticipantStatus.applied,
          appliedAt: now,
        ),
      },
    );

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await expectLater(
      coordinator.recoverPending(),
      throwsA(isA<TransactionRecoveryException>()),
    );
    expect(repository.items.containsKey('legacy_partial'), isTrue);
  });

  test('a pending transaction that discovers conflict is resolved in same recovery', () async {
    final repository = _MemoryJournalRepository();
    final now = DateTime.utc(2026, 8, 10, 18, 30);
    final before = <String, Object?>{'value': 1};
    final target = <String, Object?>{'value': 2};
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 99});

    repository.items['pending_conflict'] = JournalTransaction(
      transactionId: 'pending_conflict',
      type: 'consume_food',
      createdAt: now,
      updatedAt: now,
      participants: <String, JournalParticipantRecord>{
        'pet': JournalParticipantRecord(
          participantKey: 'pet',
          beforePayload: before,
          beforeChecksum: checksum.checksumCanonical(before),
          targetChecksum: checksum.checksumCanonical(target),
          targetPayload: target,
        ),
      },
    );

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.recoverPending();

    expect(repository.items, isEmpty);
    expect(pet.payload, <String, Object?>{'value': 99});
  });


  test('fast path uses durable baseline without redundant participant writes', () async {
    final repository = _MemoryJournalRepository();
    final now = DateTime.utc(2026, 8, 11, 10);
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 1});
    final store = _MemoryParticipant('store', <String, Object?>{'value': 10});

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet, store],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.execute(
      transactionId: 'fast_feed',
      type: 'consume_food',
      targetPayloads: <String, Map<String, Object?>>{
        'pet': <String, Object?>{'value': 2},
        'store': <String, Object?>{'value': 9},
      },
      baselineAlreadyDurable: true,
    );

    expect(pet.payload, <String, Object?>{'value': 2});
    expect(store.payload, <String, Object?>{'value': 9});
    expect(pet.writeCount, 1);
    expect(store.writeCount, 1);
    expect(repository.upsertCount, 1);
    expect(repository.removeCount, 1);
    expect(repository.items, isEmpty);
  });

  test('default path still durabilizes baseline defensively', () async {
    final repository = _MemoryJournalRepository();
    final now = DateTime.utc(2026, 8, 11, 10);
    final pet = _MemoryParticipant('pet', <String, Object?>{'value': 1});

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.execute(
      transactionId: 'defensive',
      type: 'generic',
      targetPayloads: <String, Map<String, Object?>>{
        'pet': <String, Object?>{'value': 2},
      },
    );

    // Una escritura del baseline + una del target: la ruta genérica conserva
    // la protección anterior para futuros callers que no preparen su baseline.
    expect(pet.writeCount, 2);
    expect(repository.items, isEmpty);
  });

  test('pending partial transaction infers target and resumes without status checkpoints', () async {
    final repository = _MemoryJournalRepository();
    final now = DateTime.utc(2026, 8, 11, 10);
    final petBefore = <String, Object?>{'value': 1};
    final petTarget = <String, Object?>{'value': 2};
    final storeBefore = <String, Object?>{'value': 10};
    final storeTarget = <String, Object?>{'value': 9};
    final pet = _MemoryParticipant('pet', petTarget);
    final store = _MemoryParticipant('store', storeBefore);

    repository.items['partial_pending'] = JournalTransaction(
      transactionId: 'partial_pending',
      type: 'consume_food',
      createdAt: now,
      updatedAt: now,
      participants: <String, JournalParticipantRecord>{
        'pet': JournalParticipantRecord(
          participantKey: 'pet',
          beforePayload: petBefore,
          beforeChecksum: checksum.checksumCanonical(petBefore),
          targetChecksum: checksum.checksumCanonical(petTarget),
          targetPayload: petTarget,
        ),
        'store': JournalParticipantRecord(
          participantKey: 'store',
          beforePayload: storeBefore,
          beforeChecksum: checksum.checksumCanonical(storeBefore),
          targetChecksum: checksum.checksumCanonical(storeTarget),
          targetPayload: storeTarget,
        ),
      },
    );

    final coordinator = CrossModuleTransactionCoordinator(
      repository: repository,
      participants: <TransactionParticipant>[pet, store],
      checksumService: checksum,
      clock: _FixedClock(now),
    );

    await coordinator.recoverPending();

    expect(pet.payload, petTarget);
    expect(store.payload, storeTarget);
    expect(pet.writeCount, 0);
    expect(store.writeCount, 1);
    expect(repository.upsertCount, 0);
    expect(repository.removeCount, 1);
    expect(repository.items, isEmpty);
  });

  test('journal corruption stays fail-closed across retries', () async {
    final directory = await Directory.systemTemp.createTemp('nti_journal_test_');
    addTearDown(() => directory.delete(recursive: true));
    final clock = _FixedClock(DateTime.utc(2026, 8, 10, 18, 30));
    final storage = JsonFileStorage(
      fileName: 'transaction_journal.json',
      policy: JournalStoragePolicy(),
      directoryProvider: FixedStorageDirectoryProvider(directory),
      checksumService: checksum,
      clock: clock,
    );

    await File('${directory.path}${Platform.pathSeparator}transaction_journal.json')
        .writeAsString('{ definitely-not-valid-json', flush: true);

    final firstRepository = LocalTransactionJournalRepository(storage: storage);
    await expectLater(
      firstRepository.loadAll(),
      throwsA(isA<TransactionJournalUnavailableException>()),
    );

    final retryStorage = JsonFileStorage(
      fileName: 'transaction_journal.json',
      policy: JournalStoragePolicy(),
      directoryProvider: FixedStorageDirectoryProvider(directory),
      checksumService: checksum,
      clock: clock,
    );
    final retryRepository = LocalTransactionJournalRepository(
      storage: retryStorage,
    );

    await expectLater(
      retryRepository.loadAll(),
      throwsA(isA<TransactionJournalUnavailableException>()),
    );
  });
}

class _MemoryParticipant implements TransactionParticipant {
  _MemoryParticipant(this.participantKey, Map<String, Object?> initial)
    : payload = Map<String, Object?>.from(initial);

  @override
  final String participantKey;
  Map<String, Object?> payload;
  int writeCount = 0;

  @override
  Future<Map<String, Object?>> readPayload() async =>
      Map<String, Object?>.from(payload);

  @override
  Future<void> writePayload(Map<String, Object?> payload) async {
    writeCount++;
    this.payload = Map<String, Object?>.from(payload);
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    if (payload['value'] is! int) {
      throw const FormatException('value debe ser int.');
    }
  }
}

class _MemoryJournalRepository implements TransactionJournalRepository {
  final Map<String, JournalTransaction> items = <String, JournalTransaction>{};
  int upsertCount = 0;
  int removeCount = 0;

  @override
  Future<List<JournalTransaction>> loadAll() async => items.values.toList();

  @override
  Future<void> upsert(JournalTransaction transaction) async {
    upsertCount++;
    items[transaction.transactionId] = transaction;
  }

  @override
  Future<void> remove(String transactionId) async {
    removeCount++;
    items.remove(transactionId);
  }
}

class _FixedClock implements AppClock {
  _FixedClock(this.value);

  DateTime value;

  @override
  DateTime nowUtc() => value.toUtc();
}
