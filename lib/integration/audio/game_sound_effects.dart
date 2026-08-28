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

  static Future<void> preload() {
    return _preloadOperation ??= _preloadAll();
  }

  static Future<void> _preloadAll() async {
    await Future.wait(<Future<void>>[
      _preparePurchasePool(),
      _prepareCoinPool(),
    ]);
  }

  static Future<void> _preparePurchasePool() async {
    try {
      final pool = await FlameAudio.createPool(
        'buy.mp3',
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
        'coin_pick.wav',
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

  static void playPurchase() {
    unawaited(_playSafely(_playPurchaseFromPool, 'buy.mp3'));
  }

  static void playCoinPickup() {
    unawaited(_playSafely(_playCoinFromPool, 'coin_pick.wav'));
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
