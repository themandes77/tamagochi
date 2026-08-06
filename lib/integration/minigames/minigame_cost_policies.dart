import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';

abstract final class MinigameCostPolicies {
  static const GameCostPolicy trepaNubes = GameCostPolicy(
    gameId: 'trepa_nubes',
    energyCost: 2.0,
    cleanlinessCost: 2.0,
  );
}
