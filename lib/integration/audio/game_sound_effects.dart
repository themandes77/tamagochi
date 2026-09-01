import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/widgets.dart';

/// Sonidos cortos que se preparan durante la pantalla de carga.
///
/// Los pools mantienen reproductores listos para evitar el retraso que ocurre
/// cuando [FlameAudio.play] tiene que crear uno al momento de la acción.
class GameSoundEffects {
  GameSoundEffects._();

  static Future<void>? _preloadOperation;
  static Future<void> Function()? _playPurchaseFromPool;
  static Future<void> Function()? _playCoinFromPool;
  static Future<void> Function()? _playButtonFromPool;
  static Future<void> Function()? _playEatFromPool;
  static Future<void> Function()? _playJumpFromPool;
  static AudioPlayer? _washingPlayer;
  static Future<void>? _washingStart;
  static int _washingGeneration = 0;

  static Future<void> preload() {
    return _preloadOperation ??= _preloadAll();
  }

  static Future<void> _preloadAll() async {
    await Future.wait(<Future<void>>[
      _preparePurchasePool(),
      _prepareCoinPool(),
      _prepareButtonPool(),
      _prepareEatPool(),
      _prepareJumpPool(),
      _prepareWashingAudio(),
    ]);
  }

  static Future<void> _preparePurchasePool() async {
    try {
      final pool = await FlameAudio.createPool(
        'sfx/buy.wav',
        minPlayers: 1,
        maxPlayers: 3,
      );
      _playPurchaseFromPool = () async {
        await pool.start();
      };
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static Future<void> _prepareCoinPool() async {
    try {
      final pool = await FlameAudio.createPool(
        'sfx/coin_pick.wav',
        minPlayers: 2,
        maxPlayers: 5,
      );
      _playCoinFromPool = () async {
        await pool.start();
      };
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static Future<void> _prepareButtonPool() async {
    try {
      final pool = await FlameAudio.createPool(
        'sfx/button.mp3',
        minPlayers: 2,
        maxPlayers: 5,
      );
      _playButtonFromPool = () async {
        await pool.start();
      };
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static Future<void> _prepareEatPool() async {
    try {
      final pool = await FlameAudio.createPool(
        'sfx/eat.mp3',
        minPlayers: 1,
        maxPlayers: 3,
      );
      _playEatFromPool = () async {
        await pool.start();
      };
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static Future<void> _prepareJumpPool() async {
    try {
      final pool = await FlameAudio.createPool(
        'sfx/jump.mp3',
        minPlayers: 1,
        maxPlayers: 3,
      );
      _playJumpFromPool = () async {
        await pool.start();
      };
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static Future<void> _prepareWashingAudio() async {
    try {
      await FlameAudio.audioCache.load('sfx/washing.mp3');
    } catch (_) {
      // El audio es opcional y no debe impedir que la app inicie.
    }
  }

  static void playPurchase() {
    unawaited(_playSafely(_playPurchaseFromPool, 'sfx/buy.wav'));
  }

  static void playCoinPickup() {
    unawaited(_playSafely(_playCoinFromPool, 'sfx/coin_pick.wav'));
  }

  static void playButton() {
    unawaited(_playSafely(_playButtonFromPool, 'sfx/button.mp3'));
  }

  static void playEat() {
    unawaited(_playSafely(_playEatFromPool, 'sfx/eat.mp3'));
  }

  static void playJump() {
    unawaited(_playSafely(_playJumpFromPool, 'sfx/jump.mp3'));
  }

  static void playWashing() {
    if (_washingPlayer != null || _washingStart != null) {
      return;
    }

    final generation = ++_washingGeneration;
    final start = _startWashingLoop(generation);
    _washingStart = start;
    unawaited(start.whenComplete(() => _washingStart = null));
  }

  static Future<void> _startWashingLoop(int generation) async {
    try {
      final player = await FlameAudio.loop('sfx/washing.mp3');
      if (generation != _washingGeneration) {
        await player.dispose();
        return;
      }
      _washingPlayer = player;
    } catch (_) {
      // Un error de audio nunca debe cambiar el resultado de una acción.
    }
  }

  static Future<void> stopWashing() async {
    _washingGeneration++;
    final player = _washingPlayer;
    _washingPlayer = null;
    if (player != null) {
      await player.dispose();
    }
  }

  static Future<void> _playSafely(
    Future<void> Function()? pooledPlayback,
    String asset,
  ) async {
    try {
      WidgetsBinding.instance;
      if (pooledPlayback != null) {
        await pooledPlayback();
      } else {
        await FlameAudio.play(asset);
      }
    } catch (_) {
      // Un error de audio nunca debe cambiar el resultado de una acción.
    }
  }
}
