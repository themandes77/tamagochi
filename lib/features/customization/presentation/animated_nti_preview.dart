import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';

class AnimatedNtiPreview extends StatefulWidget {
  const AnimatedNtiPreview({
    required this.outfit,
    this.message,
    this.size = 168,
    super.key,
  });

  final NtiOutfit outfit;
  final String? message;
  final double size;

  @override
  State<AnimatedNtiPreview> createState() => _AnimatedNtiPreviewState();
}

class NtiStaticPreview extends StatelessWidget {
  const NtiStaticPreview({required this.outfit, this.size = 72, super.key});

  final NtiOutfit outfit;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Vista del traje ${outfit.displayName}',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              outfit.flutterAssetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
            ),
            CustomPaint(
              painter: _NtiPreviewFacePainter(
                outfit: outfit,
                idlePhase: 0.25,
                talkPhase: 1,
                isTalking: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedNtiPreviewState extends State<AnimatedNtiPreview>
    with TickerProviderStateMixin {
  late final AnimationController _idleController;
  late final AnimationController _reactionController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _reactionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedNtiPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outfit != widget.outfit ||
        oldWidget.message != widget.message) {
      _reactionController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _reactionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animations = Listenable.merge([_idleController, _reactionController]);
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      image: true,
      label: 'NTI con traje ${widget.outfit.displayName}',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: animations,
          builder: (context, child) {
            final idlePhase = animationsDisabled ? 0.25 : _idleController.value;
            final reactionPhase = animationsDisabled
                ? 1.0
                : _reactionController.value;
            final breath = math.sin(idlePhase * math.pi * 2);
            final bounce = math.sin(reactionPhase * math.pi);

            return Transform.translate(
              offset: Offset(0, -bounce * 5),
              child: Transform.rotate(
                angle: animationsDisabled ? 0 : breath * 0.006,
                child: Transform.scale(scale: 1 + breath * 0.006, child: child),
              ),
            );
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: 0.92, end: 1.0).animate(animation),
                  child: child,
                ),
              );
            },
            child: RepaintBoundary(
              key: ValueKey(widget.outfit.id),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    widget.outfit.flutterAssetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                  AnimatedBuilder(
                    animation: animations,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _NtiPreviewFacePainter(
                          outfit: widget.outfit,
                          idlePhase: _idleController.value,
                          talkPhase: _reactionController.value,
                          isTalking: _reactionController.isAnimating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NtiPreviewFacePainter extends CustomPainter {
  const _NtiPreviewFacePainter({
    required this.outfit,
    required this.idlePhase,
    required this.talkPhase,
    required this.isTalking,
  });

  final NtiOutfit outfit;
  final double idlePhase;
  final double talkPhase;
  final bool isTalking;

  @override
  void paint(Canvas canvas, Size size) {
    final isBlinking = idlePhase > 0.93 && idlePhase < 0.98;
    final gazeX = math.sin(idlePhase * math.pi * 2) * size.width * 0.009;
    final eyeY = size.height * outfit.eyeCenterY;
    final eyeWidth = size.width * 0.075;
    final eyeHeight = isBlinking ? size.height * 0.012 : size.height * 0.115;

    _drawEye(
      canvas,
      center: Offset(size.width * 0.39, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
    );
    _drawEye(
      canvas,
      center: Offset(size.width * 0.61, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
    );
    _drawMouth(canvas, size);
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double gazeX,
    required bool blinking,
  }) {
    final eyeRect = Rect.fromCenter(
      center: center,
      width: width,
      height: height,
    );

    if (blinking) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(eyeRect, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF211A2B)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
      return;
    }

    canvas.drawOval(
      eyeRect,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 0.9,
          colors: [Color(0xFF5A5361), Color(0xFF09070D)],
          stops: [0, 0.7],
        ).createShader(eyeRect),
    );
    canvas.drawCircle(
      Offset(center.dx - width * 0.18 + gazeX, center.dy - height * 0.23),
      width * 0.13,
      Paint()..color = Colors.white.withValues(alpha: 0.72),
    );
  }

  void _drawMouth(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * outfit.mouthCenterY);
    final talking = isTalking && talkPhase < 0.76;

    if (talking) {
      final openWide = (talkPhase * 18).floor().isEven;
      final mouthRect = Rect.fromCenter(
        center: center,
        width: size.width * (openWide ? 0.12 : 0.09),
        height: size.height * (openWide ? 0.065 : 0.04),
      );
      canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF151019));
      if (openWide) {
        canvas.drawArc(
          Rect.fromLTWH(
            mouthRect.left + mouthRect.width * 0.18,
            mouthRect.top + mouthRect.height * 0.48,
            mouthRect.width * 0.64,
            mouthRect.height * 0.36,
          ),
          0,
          math.pi,
          false,
          Paint()..color = const Color(0xFFE97A9B),
        );
      }
      return;
    }

    final smile = Path()
      ..moveTo(center.dx - size.width * 0.055, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + size.height * 0.045,
        center.dx + size.width * 0.055,
        center.dy,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF17111D)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.5, size.width * 0.016),
    );
  }

  @override
  bool shouldRepaint(covariant _NtiPreviewFacePainter oldDelegate) {
    return oldDelegate.outfit != outfit ||
        oldDelegate.idlePhase != idlePhase ||
        oldDelegate.talkPhase != talkPhase ||
        oldDelegate.isTalking != isTalking;
  }
}
