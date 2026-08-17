import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/settings/app_preferences_controller.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

/// Overlay de pausa construido como UI real sobre un shell artístico limpio.
///
/// La composición base sigue el mockup aprobado y se escala como una sola
/// unidad. En pantallas excepcionalmente cortas conserva la misma composición
/// y permite desplazamiento vertical como último recurso.
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

  static const double _designWidth = 415;
  static const double _androidDesignHeight = 690;
  static const double _iosDesignHeight = 620;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.54),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final designHeight = showExit
                  ? _androidDesignHeight
                  : _iosDesignHeight;
              final availableWidth = math.max(0.0, constraints.maxWidth - 18);
              final availableHeight = math.max(0.0, constraints.maxHeight - 14);
              final scale = math
                  .min(1.0, availableWidth / _designWidth)
                  .toDouble();
              final scaledHeight = designHeight * scale;

              final design = _ScaledPauseDesign(
                scale: scale,
                designWidth: _designWidth,
                designHeight: designHeight,
                child: _PauseDesign(
                  preferencesController: preferencesController,
                  onContinue: onContinue,
                  onExitRequested: onExitRequested,
                  showExit: showExit,
                  designHeight: designHeight,
                ),
              );

              if (scaledHeight <= availableHeight) {
                return Center(child: design);
              }

              return SingleChildScrollView(
                key: const ValueKey('pause_overlay_scroll'),
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Center(child: design),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScaledPauseDesign extends StatelessWidget {
  const _ScaledPauseDesign({
    required this.scale,
    required this.designWidth,
    required this.designHeight,
    required this.child,
  });

  final double scale;
  final double designWidth;
  final double designHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // El diseño base debe escalarse una sola vez. La implementación anterior
    // primero restringía el child al tamaño ya escalado y después aplicaba
    // Transform.scale, provocando una segunda reducción visual.
    return SizedBox(
      width: designWidth * scale,
      height: designHeight * scale,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: designWidth,
          height: designHeight,
          child: child,
        ),
      ),
    );
  }
}

class _PauseDesign extends StatelessWidget {
  const _PauseDesign({
    required this.preferencesController,
    required this.onContinue,
    required this.onExitRequested,
    required this.showExit,
    required this.designHeight,
  });

  final AppPreferencesController preferencesController;
  final VoidCallback onContinue;
  final Future<void> Function() onExitRequested;
  final bool showExit;
  final double designHeight;

  static const _purple = StoreVisualTokens.purple;
  static const _deepPurple = StoreVisualTokens.purpleDark;
  static const _gold = StoreVisualTokens.gold;
  static const _danger = StoreVisualTokens.danger;
  static const _cardCream = StoreVisualTokens.cream;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: Image.asset(
            showExit
                ? 'assets/ui/pause/pause_panel_shell_android.png'
                : 'assets/ui/pause/pause_panel_shell_ios.png',
            key: const ValueKey('pause_panel_surface'),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
          ),
        ),

        // Mascota fija/original integrada en la cúpula del panel.
        const Positioned(
          left: 126,
          top: 22,
          width: 163,
          height: 163,
          child: _PauseNtiMascot(),
        ),

        const Positioned(
          left: 0,
          right: 0,
          top: 188,
          child: Center(
            child: Text(
              'PAUSA',
              key: ValueKey('pause_title'),
              style: TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 48,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _purple,
                shadows: <Shadow>[
                  Shadow(
                    color: Color(0x553A2252),
                    offset: Offset(0, 3),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),

        const Positioned(left: 56, top: 189, child: _GoldStar(size: 24)),
        const Positioned(right: 56, top: 189, child: _GoldStar(size: 24)),
        const Positioned(left: 91, top: 200, child: _DecorativeLine(width: 47)),
        const Positioned(right: 91, top: 200, child: _DecorativeLine(width: 47)),
        const Positioned(left: 108, top: 221, child: _SoftStar(size: 14)),
        const Positioned(right: 108, top: 221, child: _SoftStar(size: 14)),

        Positioned(
          left: 32,
          right: 32,
          top: 250,
          child: AnimatedBuilder(
            animation: preferencesController,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _PreferenceCard(
                    icon: Icons.music_note_rounded,
                    label: 'MÚSICA',
                    trailing: _PauseSlider(
                      key: const ValueKey('pause_music_slider'),
                      value: preferencesController.musicVolume,
                      onChanged: preferencesController.updateMusicVolume,
                      onChangeEnd: (_) {
                        unawaited(preferencesController.persist());
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreferenceCard(
                    icon: Icons.volume_up_rounded,
                    label: 'EFECTOS',
                    trailing: _PauseSlider(
                      key: const ValueKey('pause_effects_slider'),
                      value: preferencesController.effectsVolume,
                      onChanged: preferencesController.updateEffectsVolume,
                      onChangeEnd: (_) {
                        unawaited(preferencesController.persist());
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _PreferenceCard(
                    icon: Icons.vibration_rounded,
                    label: 'VIBRACIÓN',
                    trailing: _PauseToggle(
                      key: const ValueKey('pause_vibration_switch'),
                      value: preferencesController.vibrationEnabled,
                      onChanged: (value) {
                        unawaited(
                          preferencesController.setVibrationEnabled(value),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        Positioned(
          left: 55,
          right: 55,
          top: 501,
          height: 64,
          child: _PauseButton(
            key: const ValueKey('pause_continue_button'),
            label: 'CONTINUAR',
            fillColor: _purple,
            borderColor: _gold,
            textColor: Colors.white,
            elevationColor: const Color(0x553C1763),
            onPressed: onContinue,
          ),
        ),

        if (showExit)
          Positioned(
            left: 83,
            right: 83,
            top: 584,
            height: 50,
            child: _PauseButton(
              key: const ValueKey('pause_exit_button'),
              label: 'SALIR DEL JUEGO',
              fillColor: _cardCream,
              borderColor: _danger,
              textColor: const Color(0xFFB7372D),
              elevationColor: const Color(0x22A42A1D),
              compact: true,
              onPressed: () {
                unawaited(onExitRequested());
              },
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          top: showExit ? 650 : 586,
          child: const _VersionFooter(),
        ),
      ],
    );
  }
}

class _PauseNtiMascot extends StatelessWidget {
  const _PauseNtiMascot();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.asset(
          'assets/images/outfits/nti_body_master.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const CustomPaint(painter: _PauseMascotFacePainter()),
      ],
    );
  }
}

/// Rostro neutral basado en las proporciones del NtiFace de Home.
class _PauseMascotFacePainter extends CustomPainter {
  const _PauseMascotFacePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Deliberadamente un poco más abajo que el rostro de las primeras
    // corridas para reproducir la referencia aprobada.
    final eyeY = size.height * 0.455;
    final eyeWidth = size.width * 0.075;
    final eyeHeight = size.height * 0.115;

    _drawEye(
      canvas,
      center: Offset(size.width * 0.39, eyeY),
      width: eyeWidth,
      height: eyeHeight,
    );
    _drawEye(
      canvas,
      center: Offset(size.width * 0.61, eyeY),
      width: eyeWidth,
      height: eyeHeight,
    );

    final mouthCenter = Offset(size.width * 0.50, size.height * 0.555);
    final smile = Path()
      ..moveTo(mouthCenter.dx - size.width * 0.052, mouthCenter.dy)
      ..quadraticBezierTo(
        mouthCenter.dx,
        mouthCenter.dy + size.height * 0.041,
        mouthCenter.dx + size.width * 0.052,
        mouthCenter.dy,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF17111D)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.2,
    );
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
  }) {
    final eyeRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );
    canvas.drawOval(
      eyeRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: <Color>[Color(0xFF5A5361), Color(0xFF09070D)],
          stops: <double>[0, 0.7],
        ).createShader(eyeRect),
    );
    canvas.drawCircle(
      Offset(center.dx - width * 0.18, center.dy - height * 0.23),
      width * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  @override
  bool shouldRepaint(covariant _PauseMascotFacePainter oldDelegate) => false;
}

class _GoldStar extends StatelessWidget {
  const _GoldStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: StoreVisualTokens.gold,
      shadows: const <Shadow>[
        Shadow(color: Color(0x554A245E), offset: Offset(0, 2), blurRadius: 2),
      ],
    );
  }
}

class _DecorativeLine extends StatelessWidget {
  const _DecorativeLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: const Color(0xFFD6A277).withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _SoftStar extends StatelessWidget {
  const _SoftStar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: size,
      color: StoreVisualTokens.purpleLight,
    );
  }
}

/// Fila de preferencias con geometría fija dentro de la composición base.
/// Así los labels nunca pueden robarle espacio al slider/switch.
class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard({
    required this.icon,
    required this.label,
    required this.trailing,
  });

  final IconData icon;
  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('pause_preference_${label.toLowerCase()}'),
      width: double.infinity,
      height: 70,
      decoration: BoxDecoration(
        color: StoreVisualTokens.cream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: StoreVisualTokens.creamStrong, width: 1.5),
        boxShadow: const <BoxShadow>[StoreVisualTokens.cardShadow],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 10,
            top: 8,
            width: 54,
            height: 54,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    StoreVisualTokens.lavenderStrong,
                    StoreVisualTokens.purple,
                  ],
                ),
                border: Border.all(color: StoreVisualTokens.purple, width: 2),
                boxShadow: const <BoxShadow>[StoreVisualTokens.tabShadow],
              ),
              child: Icon(
                icon,
                color: StoreVisualTokens.gold,
                size: 31,
                shadows: const <Shadow>[
                  Shadow(
                    color: Color(0x884F2A1E),
                    offset: Offset(0, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 76,
            top: 0,
            bottom: 0,
            width: 118,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  maxLines: 1,
                  style: const TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StoreVisualTokens.purpleDark,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 202,
            right: 15,
            top: 12,
            bottom: 12,
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class _PauseSlider extends StatelessWidget {
  const _PauseSlider({
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  double _valueForDx(double dx, double width) {
    const inset = 13.0;
    final usable = math.max(1.0, width - inset * 2);
    return ((dx - inset) / usable).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final current = value.clamp(0.0, 1.0).toDouble();
        return Semantics(
          label: 'Volumen',
          value: '${(current * 100).round()}%',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) {
              onChanged(_valueForDx(details.localPosition.dx, width));
            },
            onTapUp: (details) {
              onChangeEnd(_valueForDx(details.localPosition.dx, width));
            },
            onHorizontalDragUpdate: (details) {
              onChanged(_valueForDx(details.localPosition.dx, width));
            },
            onHorizontalDragEnd: (_) => onChangeEnd(value),
            child: SizedBox.expand(
              child: CustomPaint(
                painter: _PauseSliderPainter(value: current),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PauseSliderPainter extends CustomPainter {
  const _PauseSliderPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 13.0;
    final centerY = size.height / 2;
    final left = inset;
    final right = math.max(left + 1, size.width - inset);
    final trackRect = Rect.fromLTRB(left, centerY - 5, right, centerY + 5);
    const radius = Radius.circular(8);

    canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, radius),
      Paint()..color = StoreVisualTokens.purpleLight,
    );

    final knobX = left + (right - left) * value;
    final activeRect = Rect.fromLTRB(left, centerY - 5, knobX, centerY + 5);
    if (activeRect.width > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, radius),
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[
              StoreVisualTokens.lavenderStrong,
              StoreVisualTokens.purple,
            ],
          ).createShader(trackRect),
      );
    }

    canvas.drawCircle(
      Offset(knobX, centerY + 2),
      13,
      Paint()..color = const Color(0x36502B6F),
    );
    canvas.drawCircle(
      Offset(knobX, centerY),
      12,
      Paint()..color = StoreVisualTokens.goldDark,
    );
    canvas.drawCircle(
      Offset(knobX, centerY),
      9.5,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          colors: <Color>[Color(0xFFFFE489), StoreVisualTokens.gold],
        ).createShader(
          Rect.fromCircle(center: Offset(knobX, centerY), radius: 10),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _PauseSliderPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _PauseToggle extends StatelessWidget {
  const _PauseToggle({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Semantics(
        toggled: value,
        label: 'Vibración',
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(!value),
          child: SizedBox(
            width: 78,
            height: 42,
            child: CustomPaint(
              painter: _PauseTogglePainter(value: value),
            ),
          ),
        ),
      ),
    );
  }
}

class _PauseTogglePainter extends CustomPainter {
  const _PauseTogglePainter({required this.value});

  final bool value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(1, 2, size.width - 2, size.height - 4);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(size.height / 2));

    canvas.drawShadow(
      Path()..addRRect(rrect),
      const Color(0x3D3A2252),
      4,
      false,
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = value
            ? StoreVisualTokens.purple
            : StoreVisualTokens.purpleLight,
    );

    final radius = size.height * 0.39;
    final x = value ? size.width - radius - 7 : radius + 7;
    final center = Offset(x, size.height / 2);
    canvas.drawCircle(center, radius + 1.8, Paint()..color = StoreVisualTokens.goldDark);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          colors: value
              ? const <Color>[Color(0xFFFFE489), StoreVisualTokens.gold]
              : const <Color>[Color(0xFFFFFBF1), Color(0xFFE9DDF1)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldRepaint(covariant _PauseTogglePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.label,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
    required this.elevationColor,
    required this.onPressed,
    this.compact = false,
    super.key,
  });

  final String label;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;
  final Color elevationColor;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: elevationColor,
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: fillColor,
        shape: StadiumBorder(
          side: BorderSide(color: borderColor, width: compact ? 2.2 : 3),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: compact ? 20 : 29,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  letterSpacing: compact ? 0.1 : 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const _DecorativeLine(width: 44),
        const SizedBox(width: 10),
        const Text(
          'Versión Early Access',
          key: ValueKey('pause_version_label'),
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: StoreVisualTokens.purpleDark,
          ),
        ),
        const SizedBox(width: 10),
        const _DecorativeLine(width: 44),
      ],
    );
  }
}
