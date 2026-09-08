import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/app/boot/app_boot_status.dart';
import 'package:flutter_application_1/theme/app_ui_assets.dart';

class AppLoadingScreen extends StatelessWidget {
  const AppLoadingScreen({
    required this.status,
    required this.progress,
    required this.onRetry,
    required this.retryInProgress,
    super.key,
  });

  final AppBootStatus status;
  final double progress;
  final Future<void> Function() onRetry;
  final bool retryInProgress;

  @override
  Widget build(BuildContext context) {
    final normalizedProgress = progress.clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFF5D2F81),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final horizontalSafe = (screenWidth * 0.085).clamp(24.0, 52.0);
          final bottomSafe = (screenHeight * 0.075).clamp(34.0, 82.0);

          return Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0xFF5D2F81),
                  child: Image.asset(
                    AppUiAssets.loadingBackground,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              SafeArea(
                minimum: EdgeInsets.fromLTRB(
                  horizontalSafe,
                  12,
                  horizontalSafe,
                  bottomSafe,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: status == AppBootStatus.error
                      ? _BootError(
                          retryInProgress: retryInProgress,
                          onRetry: onRetry,
                        )
                      : _BootProgress(
                          progress: normalizedProgress,
                          availableWidth: screenWidth - (horizontalSafe * 2),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BootProgress extends StatelessWidget {
  const _BootProgress({
    required this.progress,
    required this.availableWidth,
  });

  final double progress;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final barWidth = math.min(availableWidth * 0.86, 330.0);
    final barHeight = (barWidth * 0.082).clamp(20.0, 26.0);
    final labelSize = (barWidth * 0.082).clamp(18.0, 23.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Cargando...',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Fredoka',
            fontSize: labelSize,
            fontWeight: FontWeight.w600,
            height: 1,
            shadows: const <Shadow>[
              Shadow(
                color: Color(0xAA5D20A8),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
        SizedBox(height: (barHeight * 0.44).clamp(9.0, 12.0)),
        SizedBox(
          width: barWidth,
          height: barHeight,
          child: _NtiProgressBar(progress: progress),
        ),
      ],
    );
  }
}

class _NtiProgressBar extends StatelessWidget {
  const _NtiProgressBar({required this.progress});

  final double progress;

  static const _track = Color(0xFF2A0A62);
  static const _fill = Color(0xFFB65CFF);
  static const _border = Color(0xFF9347E5);
  static const _gold = Color(0xFFFFC53D);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        final radius = BorderRadius.circular(height / 2);
        final borderWidth = (height * 0.085).clamp(2.0, 3.0);
        final innerInset = borderWidth + (height * 0.07);
        final starSize = height * 0.68;
        final starRight = height * 0.20;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x664F1494),
                blurRadius: 10,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _track,
                  borderRadius: radius,
                  border: Border.all(
                    color: _border,
                    width: borderWidth,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(innerInset),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(height),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(end: progress),
                    builder: (context, value, _) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          heightFactor: 1,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: _fill,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                right: starRight,
                top: (height - starSize) / 2,
                child: Icon(
                  Icons.star_rounded,
                  size: starSize,
                  color: _gold,
                  shadows: const <Shadow>[
                    Shadow(
                      color: Color(0xAA7D3D00),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({
    required this.retryInProgress,
    required this.onRetry,
  });

  final bool retryInProgress;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'No fue posible iniciar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Fredoka',
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: retryInProgress ? null : onRetry,
              child: retryInProgress
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
