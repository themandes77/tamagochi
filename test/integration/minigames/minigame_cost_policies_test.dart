import 'package:flutter_application_1/integration/minigames/minigame_cost_policies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Salto Estelar y Recolección conservan el mismo coste acordado', () {
    expect(MinigameCostPolicies.saltoEstelar.energyCost, 2.0);
    expect(MinigameCostPolicies.saltoEstelar.cleanlinessCost, 2.0);
    expect(MinigameCostPolicies.recoleccion.energyCost, 2.0);
    expect(MinigameCostPolicies.recoleccion.cleanlinessCost, 2.0);
  });

  test('cada minijuego conserva un gameId independiente', () {
    expect(MinigameCostPolicies.saltoEstelar.gameId, 'salto_estelar');
    expect(MinigameCostPolicies.recoleccion.gameId, 'recoleccion');
  });
}
