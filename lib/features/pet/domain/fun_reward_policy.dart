import 'package:flutter_application_1/features/pet/domain/game_fun_rules.dart';

class FunRewardPolicy {
  const FunRewardPolicy();

  double calculate({
    required bool completed,
    required int score,
    required GameFunRules rules,
  }) {
    if (!completed) {
      return 0.0;
    }

    final bonus = switch (score) {
      _ when score >= rules.highScoreThreshold => rules.highBonus,
      _ when score >= rules.mediumScoreThreshold => rules.mediumBonus,
      _ => 0.0,
    };

    return (rules.completionReward + bonus)
        .clamp(0.0, rules.maximumReward)
        .toDouble();
  }
}
