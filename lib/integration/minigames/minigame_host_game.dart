import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/mini-games/minigame_selector.dart';
import 'package:flutter_application_1/features/mini-games/trepa_nubes.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/integration/minigames/minigame_cost_policies.dart';

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
  final Future<void> Function() onGameOverDetected;
  final VoidCallback onExitRequested;

  late final MinigameSelector _selector;
  TrepaNubes? _activeGame;
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
    _selector = MinigameSelector(onPlayTrepaNubes: _openTrepaNubes);
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

    if (activeGame.gameOver && !_gameOverCheckpointStarted) {
      _gameOverCheckpointStarted = true;
      unawaited(_checkpointGameOver());
    }

    if (activeGame.isMounted) {
      _activeGameWasMounted = true;
    } else if (_activeGameWasMounted) {
      _requestExit();
    }
  }

  void _openTrepaNubes() {
    if (_activeGame != null || _gameStartPending || _exitSent) {
      return;
    }
    unawaited(_tryOpenTrepaNubes());
  }

  Future<void> _tryOpenTrepaNubes() async {
    _gameStartPending = true;
    _gameWasSelected = true;
    try {
      final accepted = await onGameStartRequested(
        MinigameCostPolicies.trepaNubes,
      );
      if (!accepted) {
        _gameWasSelected = false;
        onGameStartRejected();
        if (!_selector.isMounted) {
          _requestExit();
        }
        return;
      }

      _gameStarted = true;
      if (_selector.isMounted) {
        _selector.removeFromParent();
      }
      final game = TrepaNubes(ntiOutfit: ntiOutfit);
      _activeGame = game;
      await add(game);
    } catch (error, stackTrace) {
      _gameWasSelected = false;
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'nt_tamagochi.minigame_host',
          context: ErrorDescription('al iniciar Trepa Nubes'),
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
    try {
      await onGameOverDetected();
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
