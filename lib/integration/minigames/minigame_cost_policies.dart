import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';

abstract final class MinigameCostPolicies {
  static const GameCostPolicy saltoEstelar = GameCostPolicy(
    gameId: 'salto_estelar',
    energyCost: 2.0,
    cleanlinessCost: 2.0,
  );

  static const GameCostPolicy recoleccion = GameCostPolicy(
    gameId: 'recoleccion',
    energyCost: 2.0,
    cleanlinessCost: 2.0,
  );
}
