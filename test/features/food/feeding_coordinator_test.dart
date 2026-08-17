import 'package:flutter_application_1/core/persistence/checksum_service.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
import 'package:flutter_application_1/features/home/application/home_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/pet/data/pet_transaction_participant.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';
import 'package:flutter_application_1/integration/store/store_transaction_participant.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('consumes food atomically and keeps remaining inventory', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 10, 12));
    final petRepository = _InMemoryPetRepository(
      PetState(
        hunger: 4,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: clock.nowUtc(),
      ),
    );
    final petController = PetController(
      initialState: (await petRepository.load())!,
    );
    final lifecycle = PetLifecycleCoordinator(
      controller: petController,
      repository: petRepository,
      clock: clock,
    );
    await lifecycle.initialize();

    final storeRepository = InMemoryStoreRepository(
      initialSnapshot: StoreSnapshot.initial().copyWith(
        foodInventory: const <String, int>{
          'food_1': 0,
          'food_2': 2,
          'food_3': 0,
        },
      ),
    );
    final storeController = StoreController(repository: storeRepository);
    await storeController.initialize();

    final coordinator = CrossModuleTransactionCoordinator(
      repository: _InMemoryJournalRepository(),
      participants: <TransactionParticipant>[
        PetTransactionParticipant(
          controller: petController,
          repository: petRepository,
          onDurablePersisted: lifecycle.markTransactionSnapshotDurable,
        ),
        StoreTransactionParticipant(
          controller: storeController,
          repository: storeRepository,
        ),
      ],
      checksumService: const Sha256ChecksumService(),
      clock: clock,
    );

    final feeding = FeedingCoordinator(
      petController: petController,
      petLifecycleCoordinator: lifecycle,
      storeController: storeController,
      transactionCoordinator: coordinator,
      clock: clock,
    );

    final result = await feeding.consume('food_2');

    expect(result.status, FoodFeedStatus.success);
    expect(petController.state.hunger, 9);
    expect(storeController.foodQuantity('food_2'), 1);
    expect(result.remainingQuantity, 1);
  });

  test('rejects food at 9.5 hunger without consuming inventory', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 10, 12));
    final petRepository = _InMemoryPetRepository(
      PetState(
        hunger: 9.5,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: clock.nowUtc(),
      ),
    );
    final petController = PetController(
      initialState: (await petRepository.load())!,
    );
    final lifecycle = PetLifecycleCoordinator(
      controller: petController,
      repository: petRepository,
      clock: clock,
    );
    await lifecycle.initialize();

    final storeRepository = InMemoryStoreRepository(
      initialSnapshot: StoreSnapshot.initial().copyWith(
        foodInventory: const <String, int>{
          'food_1': 1,
          'food_2': 0,
          'food_3': 0,
        },
      ),
    );
    final storeController = StoreController(repository: storeRepository);
    await storeController.initialize();

    final feeding = FeedingCoordinator(
      petController: petController,
      petLifecycleCoordinator: lifecycle,
      storeController: storeController,
      transactionCoordinator: CrossModuleTransactionCoordinator(
        repository: _InMemoryJournalRepository(),
        participants: <TransactionParticipant>[
          PetTransactionParticipant(
            controller: petController,
            repository: petRepository,
            onDurablePersisted: lifecycle.markTransactionSnapshotDurable,
          ),
          StoreTransactionParticipant(
            controller: storeController,
            repository: storeRepository,
          ),
        ],
        checksumService: const Sha256ChecksumService(),
        clock: clock,
      ),
      clock: clock,
    );

    final result = await feeding.consume('food_1');

    expect(result.status, FoodFeedStatus.tooFull);
    expect(storeController.foodQuantity('food_1'), 1);
    expect(petController.state.hunger, 9.5);
  });

  test('defers Pet ticker advances while the food transaction is open', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 10, 12));
    final petRepository = _InMemoryPetRepository(
      PetState(
        hunger: 4,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: clock.nowUtc(),
      ),
    );
    final petController = PetController(
      initialState: (await petRepository.load())!,
    );
    final lifecycle = PetLifecycleCoordinator(
      controller: petController,
      repository: petRepository,
      clock: clock,
    );
    await lifecycle.initialize();

    // Simula frames reales entrando justo durante cada escritura asíncrona.
    // Antes del fix esto cambiaba el checksum de Pet entre baseline y resume.
    petRepository.onSave = () async {
      lifecycle.advance(const Duration(milliseconds: 16));
    };

    final storeRepository = InMemoryStoreRepository(
      initialSnapshot: StoreSnapshot.initial().copyWith(
        foodInventory: const <String, int>{
          'food_1': 0,
          'food_2': 1,
          'food_3': 0,
        },
      ),
    );
    final storeController = StoreController(repository: storeRepository);
    await storeController.initialize();

    final feeding = FeedingCoordinator(
      petController: petController,
      petLifecycleCoordinator: lifecycle,
      storeController: storeController,
      transactionCoordinator: CrossModuleTransactionCoordinator(
        repository: _InMemoryJournalRepository(),
        participants: <TransactionParticipant>[
          PetTransactionParticipant(
            controller: petController,
            repository: petRepository,
            onDurablePersisted: lifecycle.markTransactionSnapshotDurable,
          ),
          StoreTransactionParticipant(
            controller: storeController,
            repository: storeRepository,
          ),
        ],
        checksumService: const Sha256ChecksumService(),
        clock: clock,
      ),
      clock: clock,
    );

    final result = await feeding.consume('food_2');
    await feeding.flushPendingMaterializations();

    expect(result.status, FoodFeedStatus.success);
    expect(storeController.foodQuantity('food_2'), 0);
    expect(petController.state.hunger, lessThan(9));
    expect(petController.state.hunger, greaterThan(8.99));
  });

  test('serializes rapid taps and invalidates queued taps after full', () async {
    final clock = _FakeClock(DateTime.utc(2026, 8, 10, 12));
    final petRepository = _InMemoryPetRepository(
      PetState(
        hunger: 7,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: clock.nowUtc(),
      ),
    );
    final petController = PetController(
      initialState: (await petRepository.load())!,
    );
    final lifecycle = PetLifecycleCoordinator(
      controller: petController,
      repository: petRepository,
      clock: clock,
    );
    await lifecycle.initialize();

    final storeRepository = InMemoryStoreRepository(
      initialSnapshot: StoreSnapshot.initial().copyWith(
        foodInventory: const <String, int>{
          'food_1': 5,
          'food_2': 0,
          'food_3': 0,
        },
      ),
    );
    final storeController = StoreController(repository: storeRepository);
    await storeController.initialize();

    final feeding = FeedingCoordinator(
      petController: petController,
      petLifecycleCoordinator: lifecycle,
      storeController: storeController,
      transactionCoordinator: CrossModuleTransactionCoordinator(
        repository: _InMemoryJournalRepository(),
        participants: <TransactionParticipant>[
          PetTransactionParticipant(
            controller: petController,
            repository: petRepository,
            onDurablePersisted: lifecycle.markTransactionSnapshotDurable,
          ),
          StoreTransactionParticipant(
            controller: storeController,
            repository: storeRepository,
          ),
        ],
        checksumService: const Sha256ChecksumService(),
        clock: clock,
      ),
      clock: clock,
    );
    final home = HomeController(
      petController: petController,
      lifecycleCoordinator: lifecycle,
      feedingCoordinator: feeding,
    );
    home.toggleFoodSelection('food_1');

    final results = await Future.wait(<Future<FoodFeedResult>>[
      home.handleSelectedFoodTap(),
      home.handleSelectedFoodTap(),
      home.handleSelectedFoodTap(),
      home.handleSelectedFoodTap(),
      home.handleSelectedFoodTap(),
    ]);
    await feeding.flushPendingMaterializations();

    expect(results[0].status, FoodFeedStatus.success);
    expect(results[1].status, FoodFeedStatus.success);
    expect(results[2].status, FoodFeedStatus.success);
    expect(results[3].status, FoodFeedStatus.tooFull);
    expect(results[4].status, FoodFeedStatus.staleSelection);
    expect(petController.state.hunger, 10);
    expect(storeController.foodQuantity('food_1'), 2);
    expect(home.selectedFoodId, isNull);

    home.dispose();
  });

}

class _FakeClock implements AppClock {
  _FakeClock(this.value);

  DateTime value;

  @override
  DateTime nowUtc() => value.toUtc();
}

class _InMemoryPetRepository implements PetRepository {
  _InMemoryPetRepository(this.state);

  PetState? state;
  Future<void> Function()? onSave;

  @override
  Future<PetState?> load() async => state;

  @override
  Future<void> save(PetState state) async {
    this.state = PetState.fromJson(state.toJson());
    await onSave?.call();
  }
}

class _InMemoryJournalRepository implements TransactionJournalRepository {
  final Map<String, JournalTransaction> _items = <String, JournalTransaction>{};

  @override
  Future<List<JournalTransaction>> loadAll() async => _items.values.toList();

  @override
  Future<void> upsert(JournalTransaction transaction) async {
    _items[transaction.transactionId] = transaction;
  }

  @override
  Future<void> remove(String transactionId) async {
    _items.remove(transactionId);
  }
}
