import 'package:flutter_application_1/integration/minigames/minigame_cost_policies.dart';
import 'package:flutter_application_1/integration/minigames/minigame_fun_reward_policy.dart';
import 'package:flutter_application_1/integration/minigames/minigame_session_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const maximumReward = 3.0;

  group('MinigameFunRewardPolicy', () {
    test('ambos juegos usan inicialmente score 25 para +3', () {
      expect(
        MinigameFunRewardPolicy.scoreForMaximum(
          MinigameCostPolicies.saltoEstelar.gameId,
        ),
        25,
      );
      expect(
        MinigameFunRewardPolicy.scoreForMaximum(
          MinigameCostPolicies.recoleccion.gameId,
        ),
        25,
      );
    });

    test('score 0 conserva recompensa mínima +1', () {
      final reward = MinigameFunRewardPolicy.rewardFor(
        const MinigameSessionResult(gameId: 'salto_estelar', score: 0),
        maximumReward: maximumReward,
      );

      expect(reward, 1.0);
    });

    test('la progresión es continua entre +1 y +3', () {
      expect(
        MinigameFunRewardPolicy.rewardFor(
          const MinigameSessionResult(gameId: 'salto_estelar', score: 5),
          maximumReward: maximumReward,
        ),
        closeTo(1.4, 0.000001),
      );
      expect(
        MinigameFunRewardPolicy.rewardFor(
          const MinigameSessionResult(gameId: 'recoleccion', score: 10),
          maximumReward: maximumReward,
        ),
        closeTo(1.8, 0.000001),
      );
      expect(
        MinigameFunRewardPolicy.rewardFor(
          const MinigameSessionResult(gameId: 'salto_estelar', score: 20),
          maximumReward: maximumReward,
        ),
        closeTo(2.6, 0.000001),
      );
    });

    test('score 25 o superior queda limitado a +3', () {
      for (final score in <int>[25, 50, 500]) {
        expect(
          MinigameFunRewardPolicy.rewardFor(
            MinigameSessionResult(gameId: 'recoleccion', score: score),
            maximumReward: maximumReward,
          ),
          3.0,
        );
      }
    });

    test('un gameId sin política falla cerrado', () {
      expect(
        () => MinigameFunRewardPolicy.rewardFor(
          const MinigameSessionResult(gameId: 'otro_juego', score: 10),
          maximumReward: maximumReward,
        ),
        throwsUnsupportedError,
      );
    });

    test('score negativo es inválido', () {
      expect(
        () => MinigameFunRewardPolicy.rewardFor(
          const MinigameSessionResult(gameId: 'salto_estelar', score: -1),
          maximumReward: maximumReward,
        ),
        throwsArgumentError,
      );
    });
  });
}
