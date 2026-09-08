import 'package:flutter_application_1/integration/minigames/minigame_cost_policies.dart';
import 'package:flutter_application_1/integration/minigames/minigame_session_result.dart';

/// Traduce el progreso reportado por un minijuego a diversión de NTI.
///
/// Los minijuegos son autoridad sobre cómo se obtiene el [score]. Esta
/// política pertenece a la integración: decide únicamente cuánto repercute
/// ese progreso sobre Pet.
abstract final class MinigameFunRewardPolicy {
  static const double minimumReward = 1.0;

  // Ambos juegos comparten la misma curva inicial. Se mantienen separados
  // por gameId para poder calibrarlos de forma independiente tras playtesting
  // sin modificar la lógica interna de Marco.
  static const Map<String, int> _scoreForMaximumByGame = <String, int>{
    'salto_estelar': 25,
    'recoleccion': 25,
  };

  static double rewardFor(
    MinigameSessionResult result, {
    required double maximumReward,
  }) {
    if (!maximumReward.isFinite || maximumReward < minimumReward) {
      throw ArgumentError.value(
        maximumReward,
        'maximumReward',
        'Debe ser finito y mayor o igual que $minimumReward.',
      );
    }
    if (result.score < 0) {
      throw ArgumentError.value(
        result.score,
        'result.score',
        'El score no puede ser negativo.',
      );
    }

    final scoreForMaximum = _scoreForMaximumByGame[result.gameId];
    if (scoreForMaximum == null) {
      throw UnsupportedError(
        'No existe una política de diversión para ${result.gameId}.',
      );
    }

    final progress = (result.score / scoreForMaximum).clamp(0.0, 1.0);
    return minimumReward +
        ((maximumReward - minimumReward) * progress);
  }

  static bool supports(String gameId) =>
      _scoreForMaximumByGame.containsKey(gameId);

  static int scoreForMaximum(String gameId) {
    final value = _scoreForMaximumByGame[gameId];
    if (value == null) {
      throw UnsupportedError(
        'No existe una política de diversión para $gameId.',
      );
    }
    return value;
  }

  static void validateCurrentGameContracts() {
    // Esta comprobación mantiene explícito el vínculo con los IDs publicados
    // por nuestras políticas de coste, sin duplicar autoridad sobre los juegos.
    if (!supports(MinigameCostPolicies.saltoEstelar.gameId) ||
        !supports(MinigameCostPolicies.recoleccion.gameId)) {
      throw StateError('Falta una política de diversión para un minijuego.');
    }
  }
}
