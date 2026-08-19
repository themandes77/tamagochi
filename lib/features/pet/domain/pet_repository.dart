import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

abstract interface class PetRepository {
  Future<PetState?> load();

  Future<void> save(PetState state);
}
