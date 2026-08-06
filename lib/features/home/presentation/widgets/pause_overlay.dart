import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/theme/app_ui_assets.dart';

class PauseOverlay extends StatelessWidget {
  const PauseOverlay({
    required this.preferencesController,
    required this.onContinue,
    required this.onExitRequested,
    required this.showExit,
    super.key,
  });

  final AppPreferencesController preferencesController;
  final VoidCallback onContinue;
  final Future<void> Function() onExitRequested;
  final bool showExit;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.58),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: Image.asset(
                        AppUiAssets.pausePanel,
                        fit: BoxFit.fill,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
                      child: AnimatedBuilder(
                        animation: preferencesController,
                        builder: (context, _) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  const Expanded(
                                    child: Text(
                                      'Pausa',
                                      style: TextStyle(
                                        color: Color(0xFF473D50),
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Continuar',
                                    onPressed: onContinue,
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _VolumeControl(
                                label: 'Música',
                                icon: Icons.music_note_rounded,
                                value: preferencesController.musicVolume,
                                onChanged:
                                    preferencesController.updateMusicVolume,
                                onChangeEnd: (_) {
                                  unawaited(preferencesController.persist());
                                },
                              ),
                              const SizedBox(height: 8),
                              _VolumeControl(
                                label: 'Efectos',
                                icon: Icons.volume_up_rounded,
                                value: preferencesController.effectsVolume,
                                onChanged:
                                    preferencesController.updateEffectsVolume,
                                onChangeEnd: (_) {
                                  unawaited(preferencesController.persist());
                                },
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: const Text(
                                  'Vibración',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                secondary: const Icon(Icons.vibration_rounded),
                                value:
                                    preferencesController.vibrationEnabled,
                                onChanged: (value) {
                                  unawaited(
                                    preferencesController
                                        .setVibrationEnabled(value),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: onContinue,
                                  child: const Text('Continuar'),
                                ),
                              ),
                              if (showExit) ...<Widget>[
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      unawaited(onExitRequested());
                                    },
                                    child: const Text('Salir del juego'),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final IconData icon;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: 10),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0.0, 1.0).toDouble(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
