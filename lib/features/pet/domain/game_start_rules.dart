import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';

abstract final class GameStartRules {
  static bool hasEnoughEnergy({
    required double currentEnergy,
    required GameCostPolicy costPolicy,
  }) {
    if (!currentEnergy.isFinite || currentEnergy < 0.0) {
      throw ArgumentError.value(
        currentEnergy,
        'currentEnergy',
        'Debe ser un número finito mayor o igual que cero.',
      );
    }
    costPolicy.validate();
    return currentEnergy >= costPolicy.energyCost;
  }
}
