import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/core/persistence/checksum_service.dart';
import 'package:flutter_application_1/core/persistence/journal/journal_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/journal/local_transaction_journal_repository.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_coordinator.dart';
import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/core/persistence/json_file_storage.dart';
import 'package:flutter_application_1/core/persistence/persistence_file_names.dart';
import 'package:flutter_application_1/core/persistence/storage_directory_provider.dart';
import 'package:flutter_application_1/core/persistence/storage_notice.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/food/application/feeding_coordinator.dart';
import 'package:flutter_application_1/features/home/application/home_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/pet/data/local_pet_repository.dart';
import 'package:flutter_application_1/features/pet/data/pet_storage_policy.dart';
import 'package:flutter_application_1/features/pet/data/pet_transaction_participant.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/integration/app/app_exit_coordinator.dart';
import 'package:flutter_application_1/integration/audio/audio_service.dart';
import 'package:flutter_application_1/integration/audio/noop_audio_service.dart';
import 'package:flutter_application_1/integration/settings/app_preferences_storage_policy.dart';
import 'package:flutter_application_1/integration/settings/local_app_preferences_repository.dart';
import 'package:flutter_application_1/integration/store/local_store_repository.dart';
import 'package:flutter_application_1/integration/store/store_storage_policy.dart';
import 'package:flutter_application_1/integration/store/store_transaction_participant.dart';

typedef AppBootstrapProgress = void Function(double progress);

class AppBootstrap {
  AppBootstrap._({
    required this.clock,
    required this.noticeCenter,
    required this.petStorage,
    required this.storeStorage,
    required this.settingsStorage,
    required this.journalStorage,
    required this.journalRepository,
    required this.petController,
    required this.petLifecycleCoordinator,
    required this.feedingCoordinator,
    required this.homeController,
    required this.storeController,
    required this.preferencesController,
    required this.audioService,
    required this.petTransactionParticipant,
    required this.storeTransactionParticipant,
    required this.transactionCoordinator,
    required this.exitCoordinator,
  });

  factory AppBootstrap.create({PetRules rules = const PetRules()}) {
    rules.validate();
    const clock = SystemUtcClock();
    const checksumService = Sha256ChecksumService();
    const directoryProvider = ApplicationSupportDirectoryProvider();
    const audioService = NoOpAudioService();
    final noticeCenter = StorageNoticeCenter();

    final petStorage = JsonFileStorage(
      fileName: PersistenceFileNames.pet,
      policy: PetStoragePolicy(rules: rules),
      directoryProvider: directoryProvider,
      checksumService: checksumService,
      clock: clock,
    );

    final storeStorage = JsonFileStorage(
      fileName: PersistenceFileNames.store,
      policy: StoreStoragePolicy(),
      directoryProvider: directoryProvider,
      checksumService: checksumService,
      clock: clock,
    );

    final settingsStorage = JsonFileStorage(
      fileName: PersistenceFileNames.appSettings,
      policy: AppPreferencesStoragePolicy(),
      directoryProvider: directoryProvider,
      checksumService: checksumService,
      clock: clock,
    );

    final journalStorage = JsonFileStorage(
      fileName: PersistenceFileNames.transactionJournal,
      policy: JournalStoragePolicy(),
      directoryProvider: directoryProvider,
      checksumService: checksumService,
      clock: clock,
    );

    final petController = PetController(
      initialState: PetState.initial(nowUtc: clock.nowUtc(), rules: rules),
      rules: rules,
    );

    final petRepository = LocalPetRepository(
      storage: petStorage,
      clock: clock,
      noticeCenter: noticeCenter,
      rules: rules,
    );

    final storeRepository = LocalStoreRepository(
      storage: storeStorage,
      noticeCenter: noticeCenter,
    );

    final preferencesRepository = LocalAppPreferencesRepository(
      storage: settingsStorage,
      noticeCenter: noticeCenter,
    );

    final lifecycleCoordinator = PetLifecycleCoordinator(
      controller: petController,
      repository: petRepository,
      clock: clock,
      rules: rules,
    );

    final storeController = StoreController(repository: storeRepository);
    final preferencesController = AppPreferencesController(
      repository: preferencesRepository,
      audioService: audioService,
    );
    final journalRepository = LocalTransactionJournalRepository(
      storage: journalStorage,
    );
    final petTransactionParticipant = PetTransactionParticipant(
      controller: petController,
      repository: petRepository,
      rules: rules,
      onDurablePersisted: lifecycleCoordinator.markTransactionSnapshotDurable,
    );
    final storeTransactionParticipant = StoreTransactionParticipant(
      controller: storeController,
      repository: storeRepository,
    );
    final transactionCoordinator = CrossModuleTransactionCoordinator(
      repository: journalRepository,
      participants: <TransactionParticipant>[
        petTransactionParticipant,
        storeTransactionParticipant,
      ],
      checksumService: checksumService,
      clock: clock,
    );
    final feedingCoordinator = FeedingCoordinator(
      petController: petController,
      petLifecycleCoordinator: lifecycleCoordinator,
      storeController: storeController,
      transactionCoordinator: transactionCoordinator,
      clock: clock,
    );
    final homeController = HomeController(
      petController: petController,
      lifecycleCoordinator: lifecycleCoordinator,
      feedingCoordinator: feedingCoordinator,
    );
    final exitCoordinator = AppExitCoordinator(
      feedingCoordinator: feedingCoordinator,
      petLifecycleCoordinator: lifecycleCoordinator,
      storeController: storeController,
      preferencesController: preferencesController,
      transactionCoordinator: transactionCoordinator,
    );

    return AppBootstrap._(
      clock: clock,
      noticeCenter: noticeCenter,
      petStorage: petStorage,
      storeStorage: storeStorage,
      settingsStorage: settingsStorage,
      journalStorage: journalStorage,
      journalRepository: journalRepository,
      petController: petController,
      petLifecycleCoordinator: lifecycleCoordinator,
      feedingCoordinator: feedingCoordinator,
      homeController: homeController,
      storeController: storeController,
      preferencesController: preferencesController,
      audioService: audioService,
      petTransactionParticipant: petTransactionParticipant,
      storeTransactionParticipant: storeTransactionParticipant,
      transactionCoordinator: transactionCoordinator,
      exitCoordinator: exitCoordinator,
    );
  }

  final AppClock clock;
  final StorageNoticeCenter noticeCenter;
  final JsonFileStorage petStorage;
  final JsonFileStorage storeStorage;
  final JsonFileStorage settingsStorage;
  final JsonFileStorage journalStorage;
  final LocalTransactionJournalRepository journalRepository;
  final PetController petController;
  final PetLifecycleCoordinator petLifecycleCoordinator;
  final FeedingCoordinator feedingCoordinator;
  final HomeController homeController;
  final StoreController storeController;
  final AppPreferencesController preferencesController;
  final AudioService audioService;
  final PetTransactionParticipant petTransactionParticipant;
  final StoreTransactionParticipant storeTransactionParticipant;
  final CrossModuleTransactionCoordinator transactionCoordinator;
  final AppExitCoordinator exitCoordinator;

  bool _initializedSuccessfully = false;

  Future<void> initialize({AppBootstrapProgress? onProgress}) async {
    // 1) Cargamos Pet exactamente como está en disco. Todavía no aplicamos
    // deterioro offline ni movemos lastSavedAt: el journal necesita comparar
    // contra la línea base durable original.
    await petLifecycleCoordinator.loadDurableState();
    onProgress?.call(0.30);

    // 2) Store debe estar cargado para que su participante transaccional lea
    // el mismo snapshot durable que existía al interrumpirse la operación.
    await storeController.initialize();
    onProgress?.call(0.60);

    await preferencesController.initialize();
    onProgress?.call(0.70);

    // 3) Reconciliamos transacciones antes de modificar Pet por tiempo offline.
    await transactionCoordinator.recoverPending();
    onProgress?.call(0.85);

    // 4) Solo con el journal limpio activamos runtime y deterioro offline.
    await petLifecycleCoordinator.activateRuntimeAfterRecovery();
    _initializedSuccessfully = true;
    onProgress?.call(0.90);
  }

  Future<void> dispose() async {
    // Si bootstrap falló durante recovery, dispose no debe crear nuevos
    // checkpoints que cambien el baseline antes de un Reintentar. Solo espera
    // operaciones que ya estuvieran en vuelo.
    await feedingCoordinator.flushPendingMaterializations();
    await petLifecycleCoordinator.flushPendingSaves();
    if (_initializedSuccessfully) {
      await storeController.persistRuntimeCoins();
    }
    await storeController.flushPendingSaves();
    await preferencesController.flushPendingSaves();
    homeController.dispose();
    petController.dispose();
    storeController.dispose();
    preferencesController.dispose();
  }
}
