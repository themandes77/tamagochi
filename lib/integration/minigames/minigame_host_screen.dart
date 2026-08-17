import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/pet/domain/game_cost_policy.dart';
import 'package:flutter_application_1/integration/minigames/minigame_host_game.dart';
import 'package:flutter_application_1/integration/minigames/minigame_session_result.dart';

class MinigameHostScreen extends StatefulWidget {
  const MinigameHostScreen({
    required this.ntiOutfit,
    required this.onGameStartRequested,
    required this.onGameOverDetected,
    required this.onGameSessionEnded,
    super.key,
  });

  final NtiOutfit ntiOutfit;

  final Future<bool> Function(GameCostPolicy costPolicy)
      onGameStartRequested;
  final Future<void> Function(MinigameSessionResult result)
      onGameOverDetected;
  final Future<void> Function() onGameSessionEnded;

  @override
  State<MinigameHostScreen> createState() => _MinigameHostScreenState();
}

class _MinigameHostScreenState extends State<MinigameHostScreen> {
  late final MinigameHostGame _game;
  Timer? _messageTimer;
  bool _exitScheduled = false;
  bool _showInsufficientEnergy = false;

  @override
  void initState() {
    super.initState();
    _game = MinigameHostGame(
      ntiOutfit: widget.ntiOutfit,
      onGameStartRequested: widget.onGameStartRequested,
      onGameStartRejected: _showEnergyMessage,
      onGameOverDetected: widget.onGameOverDetected,
      onExitRequested: _scheduleExit,
    );
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    super.dispose();
  }

  void _showEnergyMessage() {
    _messageTimer?.cancel();
    if (mounted) {
      setState(() {
        _showInsufficientEnergy = true;
      });
    }
    _messageTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showInsufficientEnergy = false;
      });
    });
  }

  void _scheduleExit() {
    if (_exitScheduled) {
      return;
    }
    if (mounted) {
      setState(() {
        _exitScheduled = true;
      });
    } else {
      _exitScheduled = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_endSessionAndExit());
    });
  }

  Future<void> _endSessionAndExit() async {
    try {
      if (_game.gameStarted) {
        await widget.onGameSessionEnded();
      }
    } finally {
      if (mounted) {
        await Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _exitScheduled,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              GameWidget(game: _game),
              if (_showInsufficientEnergy)
                Align(
                  alignment: const Alignment(0, -0.68),
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF7E57C2),
                          width: 2,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.22),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        child: Text(
                          'No tienes suficiente energía.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF473D50),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
