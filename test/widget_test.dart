import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

void main() {
  test('nti inicia con sus cuatro necesidades completas', () {
    final state = PetState.initial(
      nowUtc: DateTime.utc(2026, 8, 4),
      rules: const PetRules(),
    );

    expect(state.hunger, 10);
    expect(state.cleanliness, 10);
    expect(state.energy, 10);
    expect(state.fun, 10);
  });
}
