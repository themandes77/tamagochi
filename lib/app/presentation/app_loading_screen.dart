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
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            AppUiAssets.loadingBackground,
            fit: BoxFit.cover,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(42, 24, 42, 42),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: status == AppBootStatus.error
                    ? _BootError(
                        retryInProgress: retryInProgress,
                        onRetry: onRetry,
                      )
                    : _BootProgress(progress: normalizedProgress),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BootProgress extends StatelessWidget {
  const _BootProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Text(
          'Cargando...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 30,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                AppUiAssets.loadingBarFrame,
                fit: BoxFit.fill,
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(end: progress),
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 20,
                        backgroundColor: const Color(0xFFDED7E9),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF7E57C2),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
