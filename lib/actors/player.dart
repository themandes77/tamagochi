import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/gui.dart';

enum PlayerState { idle, talking }

class Nti extends PositionComponent with TapCallbacks {
  Nti({
    this.hunger = 10,
    this.cleanliness = 10,
    this.energy = 10,
    this.outfit = NtiOutfit.original,
  }) : super(size: Vector2.all(360), anchor: Anchor.center);

  double hunger;
  double cleanliness;
  double energy;
  double decayRate = 0.2;
  ToolBar? toolBar;
  NtiOutfit outfit;

  late final SpriteComponent _body;
  late final NtiFace _face;
  late final NtiSpeechBubble _speechBubble;
  double _idleTime = 0;
  int _greetingIndex = 0;

  static const _greetings = <String>[
    '¡Hola! ¿Jugamos?',
    'Me alegra verte.',
    '¿Qué traje usamos hoy?',
  ];

  void feed() {
    hunger = (hunger + 3).clamp(0, 10);
  }

  void wash() {
    cleanliness = (cleanliness + 3).clamp(0, 10);
  }

  void tick() {
    hunger = (hunger - decayRate).clamp(0, 10);
    cleanliness = (cleanliness - decayRate).clamp(0, 10);
    energy = (energy - decayRate).clamp(0, 10);
  }

  Future<void> wear(NtiOutfit newOutfit) async {
    outfit = newOutfit;
    _body.sprite = await Sprite.load(newOutfit.artworkAssetPath);
    _face.outfit = newOutfit;
    say('¡Traje ${newOutfit.displayName} equipado!');
  }

  void say(String message, {double duration = 3}) {
    _speechBubble.show(message, duration: duration);
    _face.talkFor(duration);
  }

  @override
  FutureOr<void> onLoad() async {
    position = findGame()!.size / 2 + Vector2(0, 18);

    _body = SpriteComponent(
      sprite: await Sprite.load(outfit.artworkAssetPath),
      size: size,
    );
    _face = NtiFace(size: size, outfit: outfit);
    _speechBubble = NtiSpeechBubble(position: Vector2((size.x - 244) / 2, -84));

    addAll([_body, _face, _speechBubble]);
    say('¡Hola! Soy NTI.', duration: 2.8);
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTime += dt;

    final breath = math.sin(_idleTime * math.pi);
    scale = Vector2.all(1 + breath * 0.006);
    angle = math.sin(_idleTime * 0.8) * 0.006;
  }

  @override
  bool onTapDown(TapDownEvent event) {
    final selectedTool = toolBar?.selected ?? Tool.none;

    switch (selectedTool) {
      case Tool.soap:
        wash();
        say('¡Gracias! Me siento limpio.');
      case Tool.food:
        feed();
        say('¡Qué rico! Ya tengo energía.');
      case Tool.none:
        say(_greetings[_greetingIndex]);
        _greetingIndex = (_greetingIndex + 1) % _greetings.length;
    }

    return true;
  }
}

class NtiFace extends PositionComponent {
  NtiFace({required super.size, required this.outfit});

  NtiOutfit outfit;
  double _elapsed = 0;
  double _talkRemaining = 0;

  bool get isTalking => _talkRemaining > 0;

  void talkFor(double duration) {
    _talkRemaining = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _talkRemaining = math.max(0, _talkRemaining - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final blinkCycle = _elapsed % 4.2;
    final isBlinking = blinkCycle > 3.92 && blinkCycle < 4.12;
    final gazeX = math.sin(_elapsed * 0.85) * size.x * 0.009;
    final eyeY = size.y * outfit.eyeCenterY;
    final eyeWidth = size.x * 0.075;
    final eyeHeight = isBlinking ? size.y * 0.012 : size.y * 0.115;

    _drawEye(
      canvas,
      center: Offset(size.x * 0.39, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
    );
    _drawEye(
      canvas,
      center: Offset(size.x * 0.61, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
    );

    _drawMouth(canvas);
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
          ..strokeWidth = 3
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

  void _drawMouth(Canvas canvas) {
    final center = Offset(size.x * 0.5, size.y * outfit.mouthCenterY);

    if (isTalking) {
      final openWide = (_elapsed * 8).floor().isEven;
      final mouthRect = Rect.fromCenter(
        center: center,
        width: size.x * (openWide ? 0.12 : 0.09),
        height: size.y * (openWide ? 0.065 : 0.04),
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
          Paint()
            ..color = const Color(0xFFE97A9B)
            ..style = PaintingStyle.fill,
        );
      }
      return;
    }

    final smile = Path()
      ..moveTo(center.dx - size.x * 0.055, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy + size.y * 0.045,
        center.dx + size.x * 0.055,
        center.dy,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = const Color(0xFF17111D)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 6,
    );
  }
}

class NtiSpeechBubble extends PositionComponent {
  NtiSpeechBubble({required super.position}) : super(size: Vector2(244, 72));

  String _message = '';
  double _remaining = 0;

  void show(String message, {required double duration}) {
    _message = message;
    _remaining = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _remaining = math.max(0, _remaining - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_remaining <= 0 || _message.isEmpty) {
      return;
    }

    final bubbleRect = Rect.fromLTWH(0, 0, size.x, size.y - 12);
    final bubble = RRect.fromRectAndRadius(
      bubbleRect,
      const Radius.circular(18),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.96)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = const Color(0xFF6E3CB5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final tail = Path()
      ..moveTo(size.x * 0.44, size.y - 13)
      ..lineTo(size.x * 0.5, size.y)
      ..lineTo(size.x * 0.56, size.y - 13)
      ..close();
    canvas.drawPath(tail, Paint()..color = Colors.white);
    canvas.drawPath(
      tail,
      Paint()
        ..color = const Color(0xFF6E3CB5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: _message,
        style: const TextStyle(
          color: Color(0xFF2C2135),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: size.x - 28);

    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - 12 - textPainter.height) / 2,
      ),
    );
  }
}
