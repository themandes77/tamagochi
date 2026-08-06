import 'package:flutter/scheduler.dart';

class PetSessionTicker {
  PetSessionTicker({
    required TickerProvider vsync,
    required this.onElapsed,
  }) {
    _ticker = vsync.createTicker(_handleTick);
  }

  final void Function(Duration elapsed) onElapsed;
  late final Ticker _ticker;
  Duration _previousElapsed = Duration.zero;

  bool get isActive => _ticker.isActive;

  void start() {
    if (_ticker.isActive) {
      return;
    }
    _previousElapsed = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) {
      _ticker.stop();
    }
    _previousElapsed = Duration.zero;
  }

  void dispose() {
    _ticker.dispose();
  }

  void _handleTick(Duration elapsed) {
    final delta = elapsed - _previousElapsed;
    _previousElapsed = elapsed;
    if (delta > Duration.zero) {
      onElapsed(delta);
    }
  }
}
