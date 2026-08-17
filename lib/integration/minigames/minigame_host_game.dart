import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/mini-games/minigame_selector.dart';
import 'package:flutter_application_1/features/mini-games/recoleccion.dart';
import 'package:flutter_application_1/features/mini-games/trepa_nubes.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/integration/minigames/minigame_cost_policies.dart';
import 'package:flutter_application_1/integration/minigames/minigame_session_result.dart';

class MinigameHostGame extends FlameGame {
  MinigameHostGame({
    required this.ntiOutfit,
    required this.onGameStartRequested,
    required this.onGameStartRejected,
    required this.onGameOverDetected,
    required this.onExitRequested,
  });

  final NtiOutfit ntiOutfit;
  final Future<bool> Function(GameCostPolicy costPolicy)
      onGameStartRequested;
  final VoidCallback onGameStartRejected;
  final Future<void> Function(MinigameSessionResult result)
      onGameOverDetected;
  final VoidCallback onExitRequested;

  late final MinigameSelector _selector;
  PositionComponent? _activeGame;
  bool Function()? _activeGameOver;
  int Function()? _activeScore;
  GameCostPolicy? _activeCostPolicy;

  bool _selectorWasMounted = false;
  bool _activeGameWasMounted = false;
  bool _gameWasSelected = false;
  bool _gameStartPending = false;
  bool _gameStarted = false;
  bool _gameOverCheckpointStarted = false;
  bool _exitSent = false;

  bool get gameStarted => _gameStarted;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _selector = MinigameSelector(
      onPlaySaltoEstelar: _openSaltoEstelar,
      onPlayRecoleccion: _openRecoleccion,
    );
    await add(_selector);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_exitSent) {
      return;
    }

    if (_selector.isMounted) {
      _selectorWasMounted = true;
    } else if (_selectorWasMounted && !_gameWasSelected) {
      _requestExit();
      return;
    }

    final activeGame = _activeGame;
    if (activeGame == null) {
      return;
    }

    final isGameOver = _activeGameOver;
    if (isGameOver != null &&
        isGameOver() &&
        !_gameOverCheckpointStarted) {
      _gameOverCheckpointStarted = true;
      unawaited(_checkpointGameOver());
    }

    if (activeGame.isMounted) {
      _activeGameWasMounted = true;
    } else if (_activeGameWasMounted) {
      _requestExit();
    }
  }

  void _openSaltoEstelar() {
    if (_activeGame != null || _gameStartPending || _exitSent) {
      return;
    }
    unawaited(_tryOpenSaltoEstelar());
  }

  void _openRecoleccion() {
    if (_activeGame != null || _gameStartPending || _exitSent) {
      return;
    }
    unawaited(_tryOpenRecoleccion());
  }

  Future<void> _tryOpenSaltoEstelar() async {
    await _tryOpenGame(
      costPolicy: MinigameCostPolicies.saltoEstelar,
      contextLabel: 'Salto Estelar',
      createGame: () {
        final game = TrepaNubes(ntiOutfit: ntiOutfit);
        _activeGameOver = () => game.gameOver;
        _activeScore = () => game.score;
        return game;
      },
    );
  }

  Future<void> _tryOpenRecoleccion() async {
    await _tryOpenGame(
      costPolicy: MinigameCostPolicies.recoleccion,
      contextLabel: 'Recolección',
      createGame: () {
        final game = Recoleccion(ntiOutfit: ntiOutfit);
        _activeGameOver = () => game.gameOver;
        _activeScore = () => game.score;
        return game;
      },
    );
  }

  Future<void> _tryOpenGame({
    required GameCostPolicy costPolicy,
    required String contextLabel,
    required PositionComponent Function() createGame,
  }) async {
    _gameStartPending = true;
    _gameWasSelected = true;
    try {
      final accepted = await onGameStartRequested(costPolicy);
      if (!accepted) {
        _gameWasSelected = false;
        onGameStartRejected();
        if (!_selector.isMounted) {
          _requestExit();
        }
        return;
      }

      _activeCostPolicy = costPolicy;
      _gameStarted = true;
      if (_selector.isMounted) {
        _selector.removeFromParent();
      }
      final game = createGame();
      _activeGame = game;
      await add(game);
    } catch (error, stackTrace) {
      _gameWasSelected = false;
      _activeCostPolicy = null;
      _activeGameOver = null;
      _activeScore = null;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.minigame_host',
          context: ErrorDescription('al iniciar $contextLabel'),
        ),
      );
      if (!_selector.isMounted) {
        _requestExit();
      }
    } finally {
      _gameStartPending = false;
    }
  }

  Future<void> _checkpointGameOver() async {
    final costPolicy = _activeCostPolicy;
    final readScore = _activeScore;
    if (costPolicy == null || readScore == null) {
      return;
    }

    try {
      await onGameOverDetected(
        MinigameSessionResult(
          gameId: costPolicy.gameId,
          score: readScore(),
        ),
      );
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.minigame_host',
          context: ErrorDescription('al guardar monedas de Game Over'),
        ),
      );
    }
  }

  void _requestExit() {
    if (_exitSent) {
      return;
    }
    _exitSent = true;
    onExitRequested();
  }
}
