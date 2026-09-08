import 'package:flutter_application_1/core/time/app_clock.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/application/pet_lifecycle_coordinator.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('durable load does not apply offline decay before journal recovery', () async {
    final savedAt = DateTime.utc(2026, 8, 10, 12);
    final clock = _MutableClock(DateTime.utc(2026, 8, 10, 13));
    final repository = _MemoryPetRepository(
      PetState(
        hunger: 10,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: savedAt,
      ),
    );
    final controller = PetController(
      initialState: PetState.initial(nowUtc: savedAt),
    );
    final lifecycle = PetLifecycleCoordinator(
      controller: controller,
      repository: repository,
      clock: clock,
    );

    await lifecycle.loadDurableState();

    expect(controller.state.hunger, 10);
    expect(controller.state.lastSavedAt, savedAt);
    expect(repository.saveCount, 0);
    expect(lifecycle.isInitialized, isFalse);

    // Simula que recovery sustituyó Pet por el target durable de una
    // transacción pendiente antes de activar runtime.
    controller.replaceState(
      PetState(
        hunger: 5,
        cleanliness: 10,
        energy: 10,
        fun: 10,
        lastSavedAt: DateTime.utc(2026, 8, 10, 12, 30),
      ),
    );

    await lifecycle.activateRuntimeAfterRecovery();

    // 30 minutos sobre una necesidad que tarda 10 h en ir 10 -> 0 = -0.5.
    expect(controller.state.hunger, closeTo(4.5, 0.000001));
    expect(controller.state.lastSavedAt, clock.nowUtc());
    expect(repository.saveCount, 1);
    expect(lifecycle.isInitialized, isTrue);
  });
}

class _MutableClock implements AppClock {
  _MutableClock(this.value);

  DateTime value;

  @override
  DateTime nowUtc() => value.toUtc();
}

class _MemoryPetRepository implements PetRepository {
  _MemoryPetRepository(this.state);

  PetState? state;
  int saveCount = 0;

  @override
  Future<PetState?> load() async => state;

  @override
  Future<void> save(PetState state) async {
    saveCount += 1;
    this.state = PetState.fromJson(state.toJson());
  }
}
