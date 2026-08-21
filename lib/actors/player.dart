import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/pet/presentation/nti_care_visual_state.dart';
import 'package:flutter_application_1/gui.dart';

enum PlayerState { idle, talking }

class Nti extends PositionComponent with TapCallbacks {
  static const double cleanReactionDuration = 0.78;

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
  late final _NtiGroundShadow _shadow;
  late final NtiSpeechBubble _speechBubble;
  late final _NtiCareEffects _careEffects;
  NtiCareVisualState _targetCareVisual = const NtiCareVisualState.idle();
  double _hungerVisual = 0;
  double _cleanlinessVisual = 0;
  double _energyVisual = 0;
  double _funVisual = 0;
  double _distressVisual = 0;
  double _sleepVisual = 0;
  double _cleaningVisual = 0;
  double _eatingActionVisual = 0;
  double _cleanReactionRemaining = 0;
  double _motionPhase = 0;
  double _idleTime = 0;
  double _reactionRemaining = 0;
  double _reactionDuration = 0;
  double _reactionVisual = 0;
  double _eatRemaining = 0;
  double _eatDuration = 0;
  double _eatVisual = 0;
  double _viewportScale = 1;
  int _greetingIndex = 0;
  Vector2? _restingPosition;

  bool get isReacting => _reactionRemaining > 0;
  bool get isEatingReaction => _eatRemaining > 0;

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
    react(celebratory: true);
    say('¡Traje ${newOutfit.displayName} equipado!');
  }

  void react({bool celebratory = false}) {
    _reactionDuration = celebratory ? 0.9 : 0.56;
    _reactionRemaining = _reactionDuration;

    if (isLoaded) {
      add(
        _NtiSparkleBurst(
          size: size,
          particleCount: celebratory ? 18 : 10,
          duration: celebratory ? 1.5 : 1.05,
        ),
      );
    }
  }

  /// Reacción breve y reiniciable de comer. No bloquea nuevos consumos: cada
  /// commit exitoso reinicia el gesto visual y el movimiento de masticar.
  void eat() {
    _eatDuration = 0.72;
    _eatRemaining = _eatDuration;
    _face.eatFor(_eatDuration);
  }

  void say(String message, {double duration = 3}) {
    _speechBubble.show(message, duration: duration);
    _face.talkFor(duration);
  }

  /// Cancela cualquier diálogo/reacción de habla que ya no pertenezca a la
  /// acción actual. Esto evita que un feedback viejo aparezca encima de una
  /// nueva acción (por ejemplo, Dormir después de Limpiar).
  void cancelSpeech() {
    _speechBubble.hide();
    _face.stopTalking();
  }

  /// Recibe únicamente la interpretación visual del estado durable/runtime.
  /// No altera Pet, no persiste nada y no crea una cola de estados anteriores.
  void setCareVisualState(NtiCareVisualState state) {
    final wasCleaning = _targetCareVisual.isCleaning;
    _targetCareVisual = state;
    if (!wasCleaning && state.isCleaning) {
      _cleanReactionRemaining = cleanReactionDuration;
    }
  }

  @override
  FutureOr<void> onLoad() async {
    _placeAtCenter(findGame()!.size);

    _shadow = _NtiGroundShadow(
      position: Vector2(62, size.y * 0.87),
      size: Vector2(size.x - 124, 46),
    );
    _body = SpriteComponent(
      sprite: await Sprite.load(outfit.artworkAssetPath),
      size: size,
    );
    _face = NtiFace(size: size, outfit: outfit);
    _careEffects = _NtiCareEffects(size: size);
    _speechBubble = NtiSpeechBubble(
      position: Vector2((size.x - 260) / 2, -96),
    );

    addAll([_shadow, _body, _face, _careEffects, _speechBubble]);
    say('¡Hola! Soy NTI.', duration: 2.8);
    return super.onLoad();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _placeAtCenter(size);
  }

  void _placeAtCenter(Vector2 gameSize) {
    _viewportScale = math
        .min(gameSize.x / 500, gameSize.y / 820)
        .clamp(0.72, 1.08);
    _restingPosition = gameSize / 2 + Vector2(0, 18);
    position = _restingPosition!;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _idleTime += dt;
    _reactionRemaining = math.max(0, _reactionRemaining - dt);
    _eatRemaining = math.max(0, _eatRemaining - dt);
    _cleanReactionRemaining = math.max(0, _cleanReactionRemaining - dt);

    _hungerVisual = _approach(
      _hungerVisual,
      _targetCareVisual.hungerIntensity,
      dt,
    );
    _cleanlinessVisual = _approach(
      _cleanlinessVisual,
      _targetCareVisual.cleanlinessIntensity,
      dt,
    );
    _energyVisual = _approach(
      _energyVisual,
      _targetCareVisual.energyIntensity,
      dt,
    );
    _funVisual = _approach(_funVisual, _targetCareVisual.funIntensity, dt);
    _distressVisual = _approach(
      _distressVisual,
      _targetCareVisual.distressIntensity,
      dt,
      speed: 4.4,
    );
    _sleepVisual = _approach(
      _sleepVisual,
      _targetCareVisual.isSleeping ? 1 : 0,
      dt,
      speed: 5.2,
    );
    _cleaningVisual = _approach(
      _cleaningVisual,
      _targetCareVisual.isCleaning ? 1 : 0,
      dt,
      speed: 6.0,
    );
    _eatingActionVisual = _approach(
      _eatingActionVisual,
      isEatingReaction || _targetCareVisual.isEating ? 1 : 0,
      dt,
      speed: 8.5,
    );

    final actionSuppression = math.max(
      _cleaningVisual,
      _eatingActionVisual,
    );
    final careWeight = 1 - actionSuppression;
    final hunger = _hungerVisual * careWeight;
    final energy = _energyVisual * careWeight;
    final fun = _funVisual * careWeight;
    final distress = _distressVisual * careWeight;

    final motionSlowdown = (energy * 0.43 + distress * 0.22)
        .clamp(0.0, 0.58)
        .toDouble();
    final normalMotionSpeed = 1.65 * (1 - motionSlowdown);
    final motionSpeed = _lerp(normalMotionSpeed, 0.62, _sleepVisual);
    _motionPhase += dt * motionSpeed;

    final normalFloatAmplitude =
        5.5 *
        (1 -
            (energy * 0.45 + fun * 0.22 + distress * 0.28)
                .clamp(0.0, 0.72)
                .toDouble());
    final floatAmplitude = _lerp(normalFloatAmplitude, 1.35, _sleepVisual);
    final floatOffset = math.sin(_motionPhase) * floatAmplitude;

    final reactionProgress = _reactionDuration == 0
        ? 1.0
        : 1 - (_reactionRemaining / _reactionDuration);
    _reactionVisual = isReacting ? math.sin(reactionProgress * math.pi) : 0.0;
    final eatProgress = _eatDuration == 0
        ? 1.0
        : 1 - (_eatRemaining / _eatDuration);
    _eatVisual = isEatingReaction ? math.sin(eatProgress * math.pi) : 0.0;
    final chew = isEatingReaction
        ? math.sin(eatProgress * math.pi * 6).abs()
        : 0.0;
    final hungerPulse =
        ((math.sin(_idleTime * 3.25) + 1) / 2) * hunger * (1 - _sleepVisual);
    final cleanProgress = (1 - (_cleanReactionRemaining / cleanReactionDuration))
        .clamp(0.0, 1.0)
        .toDouble();
    final cleanActive = _cleanReactionRemaining > 0;
    // Limpieza "squishy": deformación visible pero redonda. El movimiento se
    // desacopla del activity flag para que la reacción pueda terminar suave
    // aunque Pet ya haya vuelto a idle al soltar el gesto.
    final cleanEnvelope = cleanActive
        ? math.sin(cleanProgress * math.pi)
        : 0.0;
    final cleanScaleX = cleanActive ? _cleanScaleX(cleanProgress) : 1.0;
    final cleanScaleY = cleanActive ? _cleanScaleY(cleanProgress) : 1.0;
    final cleanAngle = cleanActive ? _cleanAngle(cleanProgress) : 0.0;
    final cleanSway = cleanActive ? _cleanSway(cleanProgress) : 0.0;
    final cleanPresentation = math.max(_cleaningVisual, cleanEnvelope);

    final restingPosition = _restingPosition;
    if (restingPosition != null) {
      final slump =
          (energy * 4.5 + hunger * 2.0 + distress * 7.0) * (1 - _sleepVisual);
      position = Vector2(
        restingPosition.x + cleanSway,
        restingPosition.y +
            floatOffset +
            slump +
            _sleepVisual * 5.5 -
            _reactionVisual * 20 +
            _eatVisual * 5 -
            cleanEnvelope * 2.0,
      );
    }

    final breathAmplitude = _lerp(0.008, 0.0045, _sleepVisual);
    final breath = math.sin(_motionPhase * math.pi) * breathAmplitude;
    final postureSquash =
        hunger * 0.010 + distress * 0.014 + hungerPulse * 0.012;
    final baseScale =
        _viewportScale * (1 + breath + _reactionVisual * 0.06);
    scale = Vector2(
      baseScale *
          (1 + chew * 0.035 + postureSquash * 0.55) *
          cleanScaleX,
      baseScale *
          (1 - chew * 0.026 - postureSquash) *
          cleanScaleY,
    );

    final idleAngleAmplitude =
        0.007 *
        (1 - (energy * 0.42 + fun * 0.18).clamp(0.0, 0.62).toDouble());
    angle =
        math.sin(_motionPhase * 0.52) *
            _lerp(idleAngleAmplitude, 0.002, _sleepVisual) +
        math.sin(reactionProgress * math.pi * 2) *
            _reactionVisual *
            0.025 +
        math.sin(eatProgress * math.pi * 4) * _eatVisual * 0.012 +
        cleanAngle;

    if (isLoaded) {
      final liftDenominator = math.max(floatAmplitude * 2, 1.0);
      _shadow.lift =
          ((floatOffset + floatAmplitude) / liftDenominator) +
          _reactionVisual * (1 - _sleepVisual);
      _face.setCarePresentation(
        hungerIntensity: _hungerVisual,
        cleanlinessIntensity: _cleanlinessVisual,
        energyIntensity: _energyVisual,
        funIntensity: _funVisual,
        distressIntensity: _distressVisual,
        sleepingIntensity: _sleepVisual,
        cleaningIntensity: cleanPresentation,
        actionSuppression: actionSuppression,
      );
      _careEffects.setCarePresentation(
        cleanlinessIntensity: _cleanlinessVisual,
        cleaningIntensity: cleanPresentation,
      );
    }
  }

  double _approach(
    double current,
    double target,
    double dt, {
    double speed = 3.6,
  }) {
    final factor = (1 - math.exp(-speed * dt)).clamp(0.0, 1.0).toDouble();
    return current + (target - current) * factor;
  }

  double _lerp(double from, double to, double amount) {
    return from + (to - from) * amount.clamp(0.0, 1.0).toDouble();
  }

  double _smoothStep(double value) {
    final t = value.clamp(0.0, 1.0).toDouble();
    return t * t * (3 - 2 * t);
  }

  double _cleanSegment(
    double progress,
    double start,
    double end,
    double from,
    double to,
  ) {
    if (end <= start) {
      return to;
    }
    final local = _smoothStep((progress - start) / (end - start));
    return _lerp(from, to, local);
  }

  double _cleanScaleX(double progress) {
    if (progress < 0.16) {
      return _cleanSegment(progress, 0.00, 0.16, 1.00, 1.04);
    }
    if (progress < 0.38) {
      return _cleanSegment(progress, 0.16, 0.38, 1.04, 0.97);
    }
    if (progress < 0.62) {
      return _cleanSegment(progress, 0.38, 0.62, 0.97, 1.025);
    }
    return _cleanSegment(progress, 0.62, 1.00, 1.025, 1.00);
  }

  double _cleanScaleY(double progress) {
    if (progress < 0.16) {
      return _cleanSegment(progress, 0.00, 0.16, 1.00, 0.96);
    }
    if (progress < 0.38) {
      return _cleanSegment(progress, 0.16, 0.38, 0.96, 1.03);
    }
    if (progress < 0.62) {
      return _cleanSegment(progress, 0.38, 0.62, 1.03, 0.975);
    }
    return _cleanSegment(progress, 0.62, 1.00, 0.975, 1.00);
  }

  double _cleanAngle(double progress) {
    const maxAngle = 1.5 * math.pi / 180;
    if (progress < 0.16) {
      return 0;
    }
    if (progress < 0.38) {
      return _cleanSegment(progress, 0.16, 0.38, 0, maxAngle);
    }
    if (progress < 0.62) {
      return _cleanSegment(progress, 0.38, 0.62, maxAngle, -maxAngle);
    }
    return _cleanSegment(progress, 0.62, 1.00, -maxAngle, 0);
  }

  double _cleanSway(double progress) {
    // Muy poco desplazamiento físico: la sensación viene principalmente del
    // squash/stretch, no de sacudir la posición de NTI.
    if (progress < 0.16) {
      return _cleanSegment(progress, 0.00, 0.16, 0, -1.4);
    }
    if (progress < 0.38) {
      return _cleanSegment(progress, 0.16, 0.38, -1.4, 1.8);
    }
    if (progress < 0.62) {
      return _cleanSegment(progress, 0.38, 0.62, 1.8, -1.2);
    }
    return _cleanSegment(progress, 0.62, 1.00, -1.2, 0);
  }

  @override
  void render(Canvas canvas) {
    if (_reactionVisual > 0) {
      final glowRect = Rect.fromCircle(
        center: Offset(size.x / 2, size.y / 2),
        radius: size.x * (0.43 + _reactionVisual * 0.05),
      );
      canvas.drawCircle(
        glowRect.center,
        glowRect.width / 2,
        Paint()
          ..shader = RadialGradient(
            colors: [
              const Color(0xFFFFD45A).withValues(alpha: _reactionVisual * 0.25),
              Colors.transparent,
            ],
          ).createShader(glowRect),
      );
    }
    super.render(canvas);
  }

  @override
  bool onTapDown(TapDownEvent event) {
    react();
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

class _NtiGroundShadow extends PositionComponent {
  _NtiGroundShadow({required super.position, required super.size}) {
    priority = -10;
  }

  double lift = 0;

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final normalizedLift = lift.clamp(0.0, 2.0);
    final shadowRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: size.x * (1 - normalizedLift * 0.1),
      height: size.y * (1 - normalizedLift * 0.16),
    );
    canvas.drawOval(
      shadowRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFF352043,
            ).withValues(alpha: 0.4 - normalizedLift * 0.09),
            Colors.transparent,
          ],
        ).createShader(shadowRect),
    );
  }
}

class _NtiSparkleBurst extends PositionComponent {
  _NtiSparkleBurst({
    required super.size,
    required this.particleCount,
    required this.duration,
  }) : _particles = List.generate(
         particleCount,
         (index) => _NtiSparkleParticle(
           angle:
               (math.pi * 2 * index / particleCount) +
               (index.isEven ? 0.08 : -0.05),
           distance: 68 + (index % 4) * 18,
           size: 7 + (index % 3) * 2.5,
           spin: index.isEven ? 1 : -1,
         ),
       ) {
    priority = 20;
  }

  final int particleCount;
  final double duration;
  final List<_NtiSparkleParticle> _particles;
  double _elapsed = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (_elapsed / duration).clamp(0.0, 1.0);
    final easedProgress = 1 - math.pow(1 - progress, 2).toDouble();
    final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final center = Offset(size.x / 2, size.y / 2);

    for (final particle in _particles) {
      final distance = particle.distance * easedProgress;
      final particleCenter = Offset(
        center.dx + math.cos(particle.angle) * distance,
        center.dy + math.sin(particle.angle) * distance,
      );
      _drawStar(
        canvas,
        center: particleCenter,
        radius: particle.size * (0.72 + opacity * 0.28),
        rotation: progress * math.pi * particle.spin,
        opacity: opacity,
      );
    }
  }

  void _drawStar(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double rotation,
    required double opacity,
  }) {
    final path = Path();
    for (var index = 0; index < 8; index++) {
      final pointRadius = index.isEven ? radius : radius * 0.32;
      final pointAngle = rotation - math.pi / 2 + index * math.pi / 4;
      final point = Offset(
        center.dx + math.cos(pointAngle) * pointRadius,
        center.dy + math.sin(pointAngle) * pointRadius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFFFBE24).withValues(alpha: opacity),
    );
    canvas.drawCircle(
      center,
      radius * 0.22,
      Paint()..color = Colors.white.withValues(alpha: opacity * 0.9),
    );
  }
}

class _NtiSparkleParticle {
  const _NtiSparkleParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.spin,
  });

  final double angle;
  final double distance;
  final double size;
  final int spin;
}

class NtiFace extends PositionComponent {
  static const double minimumAwakeEyeOpenFraction = 0.82;

  static double awakeEyeOpenFractionFor(double energyIntensity) {
    final normalized = energyIntensity.clamp(0.0, 1.0).toDouble();
    return 1 - normalized * (1 - minimumAwakeEyeOpenFraction);
  }

  NtiFace({
    required super.size,
    required this.outfit,
    this.eyeScale = 1.0,
    this.eyeCenterYOffset = 0.0,
    this.mouthCenterYOffset = 0.0,
  });

  NtiOutfit outfit;

  /// Ajustes ópticos opcionales para renders muy pequeños (minijuegos).
  /// Los defaults preservan exactamente la cara canónica de Home.
  final double eyeScale;
  final double eyeCenterYOffset;
  final double mouthCenterYOffset;
  double _elapsed = 0;
  double _talkRemaining = 0;
  double _eatRemaining = 0;
  double _hungerIntensity = 0;
  double _cleanlinessIntensity = 0;
  double _energyIntensity = 0;
  double _funIntensity = 0;
  double _distressIntensity = 0;
  double _sleepingIntensity = 0;
  double _cleaningIntensity = 0;
  double _actionSuppression = 0;

  bool get isTalking => _talkRemaining > 0;
  bool get isEating => _eatRemaining > 0;

  void talkFor(double duration) {
    _talkRemaining = duration;
  }

  void stopTalking() {
    _talkRemaining = 0;
  }

  void eatFor(double duration) {
    _eatRemaining = duration;
  }

  void setCarePresentation({
    required double hungerIntensity,
    required double cleanlinessIntensity,
    required double energyIntensity,
    required double funIntensity,
    required double distressIntensity,
    required double sleepingIntensity,
    required double cleaningIntensity,
    required double actionSuppression,
  }) {
    _hungerIntensity = hungerIntensity;
    _cleanlinessIntensity = cleanlinessIntensity;
    _energyIntensity = energyIntensity;
    _funIntensity = funIntensity;
    _distressIntensity = distressIntensity;
    _sleepingIntensity = sleepingIntensity;
    _cleaningIntensity = cleaningIntensity;
    _actionSuppression = actionSuppression;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    _talkRemaining = math.max(0, _talkRemaining - dt);
    _eatRemaining = math.max(0, _eatRemaining - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final needsWeight = 1 - _actionSuppression;
    final hunger = _hungerIntensity * needsWeight * (1 - _sleepingIntensity);
    final cleanliness =
        _cleanlinessIntensity * needsWeight * (1 - _sleepingIntensity);
    final energy = _energyIntensity * needsWeight * (1 - _sleepingIntensity);
    final fun = _funIntensity * needsWeight * (1 - _sleepingIntensity);
    final distress =
        _distressIntensity * needsWeight * (1 - _sleepingIntensity);

    final blinkCycle = _elapsed % 4.2;
    final isBlinking = blinkCycle > 3.92 && blinkCycle < 4.12;
    final gazeX =
        math.sin(_elapsed * 0.85) * size.x * 0.009 * (1 - energy * 0.65);
    // Los ojos despiertos sólo comunican cansancio mediante apertura.
    // Hambre, limpieza, diversión y multicrítico usan sus propios canales.
    // A energía 0 la apertura conserva al menos 82% del ojo canónico.
    final gazeDrop = size.y * (fun * 0.006 + distress * 0.020);
    final eyeY =
        size.y * (outfit.eyeCenterY + eyeCenterYOffset) + gazeDrop;
    final eyeWidth = size.x * 0.075 * eyeScale;
    final awakeEyeHeight =
        size.y * 0.115 * eyeScale * awakeEyeOpenFractionFor(energy);
    final eyeHeight = isBlinking
        ? size.y * 0.012
        : _lerp(awakeEyeHeight, size.y * 0.012, _sleepingIntensity);

    _drawEye(
      canvas,
      center: Offset(size.x * 0.39, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
      sleeping: _sleepingIntensity,
      tired: energy,
      distress: distress,
      mirror: false,
    );
    _drawEye(
      canvas,
      center: Offset(size.x * 0.61, eyeY),
      width: eyeWidth,
      height: eyeHeight,
      gazeX: gazeX,
      blinking: isBlinking,
      sleeping: _sleepingIntensity,
      tired: energy,
      distress: distress,
      mirror: true,
    );

    _drawMouth(
      canvas,
      hunger: hunger,
      cleanliness: cleanliness,
      fun: fun,
      distress: distress,
      cleaning: _cleaningIntensity,
      sleeping: _sleepingIntensity,
    );
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double width,
    required double height,
    required double gazeX,
    required bool blinking,
    required double sleeping,
    required double tired,
    required double distress,
    required bool mirror,
  }) {
    if (sleeping > 0.62) {
      final path = Path()
        ..moveTo(center.dx - width * 0.50, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + height * 0.72 + size.y * 0.008,
          center.dx + width * 0.50,
          center.dy,
        );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF211A2B)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 4.2,
      );
      return;
    }

    final eyeRect = Rect.fromCenter(
      center: center,
      width: width,
      height: math.max(height, size.y * 0.012),
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

    final highlightAlpha = (0.72 * (1 - tired * 0.18 - distress * 0.18))
        .clamp(0.46, 0.72)
        .toDouble();
    canvas.drawCircle(
      Offset(center.dx - width * 0.18 + gazeX, center.dy - height * 0.23),
      width * 0.13,
      Paint()..color = Colors.white.withValues(alpha: highlightAlpha),
    );

    // Sin falso párpado despierto: NTI no tiene párpados dibujados.
    // Parpadear y dormir siguen siendo los únicos cierres completos.

    if (distress > 0.18) {
      final browY = eyeRect.top - size.y * 0.024;
      final inward = mirror ? -1.0 : 1.0;
      final tilt = size.y * 0.010 * distress;
      final path = Path()
        ..moveTo(center.dx - width * 0.36, browY + inward * tilt)
        ..lineTo(center.dx + width * 0.36, browY - inward * tilt);
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF34263D).withValues(alpha: distress * 0.58)
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawMouth(
    Canvas canvas, {
    required double hunger,
    required double cleanliness,
    required double fun,
    required double distress,
    required double cleaning,
    required double sleeping,
  }) {
    final center = Offset(
      size.x * 0.5,
      size.y * (outfit.mouthCenterY + mouthCenterYOffset),
    );

    if (sleeping > 0.62) {
      final sleepPath = Path()
        ..moveTo(center.dx - size.x * 0.035, center.dy)
        ..quadraticBezierTo(
          center.dx,
          center.dy + size.y * 0.012,
          center.dx + size.x * 0.035,
          center.dy,
        );
      canvas.drawPath(
        sleepPath,
        Paint()
          ..color = const Color(0xFF17111D)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 5,
      );
      return;
    }

    if (isEating) {
      final open = (_elapsed * 13).floor().isEven;
      final mouthRect = Rect.fromCenter(
        center: center,
        width: size.x * (open ? 0.105 : 0.072),
        height: size.y * (open ? 0.072 : 0.026),
      );
      canvas.drawOval(mouthRect, Paint()..color = const Color(0xFF151019));
      if (open) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + mouthRect.height * 0.18),
            width: mouthRect.width * 0.52,
            height: mouthRect.height * 0.28,
          ),
          Paint()..color = const Color(0xFFE97A9B),
        );
      }
      return;
    }

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

    if (cleaning > 0.08) {
      final comfort = cleaning.clamp(0.0, 1.0).toDouble();
      final smile = Path()
        ..moveTo(center.dx - size.x * 0.060, center.dy - size.y * 0.002)
        ..quadraticBezierTo(
          center.dx,
          center.dy + size.y * (0.048 + comfort * 0.010),
          center.dx + size.x * 0.060,
          center.dy - size.y * 0.002,
        );
      canvas.drawPath(
        smile,
        Paint()
          ..color = const Color(0xFF17111D)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = 6,
      );
      return;
    }

    if (distress > 0.12) {
      _drawFrown(canvas, center: center, intensity: distress, width: 0.060);
      return;
    }

    // Hambre y diversión compiten principalmente por boca. Se combinan todos
    // los demás canales, pero aquí gana suavemente la necesidad más intensa.
    if (hunger >= fun && hunger > 0.08) {
      _drawUneasyMouth(canvas, center: center, intensity: hunger);
      return;
    }
    if (fun > 0.08) {
      _drawFrown(canvas, center: center, intensity: fun, width: 0.055);
      return;
    }
    if (cleanliness > 0.22) {
      _drawUneasyMouth(
        canvas,
        center: center,
        intensity: cleanliness * 0.55,
      );
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

  void _drawFrown(
    Canvas canvas, {
    required Offset center,
    required double intensity,
    required double width,
  }) {
    final normalized = intensity.clamp(0.0, 1.0).toDouble();
    final path = Path()
      ..moveTo(center.dx - size.x * width, center.dy + size.y * 0.018)
      ..quadraticBezierTo(
        center.dx,
        center.dy - size.y * (0.015 + 0.030 * normalized),
        center.dx + size.x * width,
        center.dy + size.y * 0.018,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF17111D)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.5,
    );
  }

  void _drawUneasyMouth(
    Canvas canvas, {
    required Offset center,
    required double intensity,
  }) {
    final normalized = intensity.clamp(0.0, 1.0).toDouble();
    final width = size.x * (0.047 + normalized * 0.010);
    final wave = size.y * (0.008 + normalized * 0.010);
    final path = Path()
      ..moveTo(center.dx - width, center.dy)
      ..cubicTo(
        center.dx - width * 0.45,
        center.dy - wave,
        center.dx - width * 0.10,
        center.dy + wave,
        center.dx,
        center.dy,
      )
      ..cubicTo(
        center.dx + width * 0.10,
        center.dy - wave,
        center.dx + width * 0.45,
        center.dy + wave,
        center.dx + width,
        center.dy,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF17111D)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 5.2,
    );
  }

  double _lerp(double from, double to, double amount) {
    return from + (to - from) * amount.clamp(0.0, 1.0).toDouble();
  }
}

class _NtiCareEffects extends PositionComponent {
  _NtiCareEffects({required super.size}) {
    priority = 12;
  }

  double _elapsed = 0;
  double _cleanlinessIntensity = 0;
  double _cleaningIntensity = 0;

  static const _dirtPoints = <Offset>[
    Offset(0.31, 0.36),
    Offset(0.68, 0.39),
    Offset(0.39, 0.58),
    Offset(0.63, 0.62),
    Offset(0.48, 0.72),
  ];

  void setCarePresentation({
    required double cleanlinessIntensity,
    required double cleaningIntensity,
  }) {
    _cleanlinessIntensity = cleanlinessIntensity;
    _cleaningIntensity = cleaningIntensity;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final dirt = _cleanlinessIntensity.clamp(0.0, 1.0).toDouble();
    if (dirt > 0.035) {
      final visibleCount = (1 + dirt * (_dirtPoints.length - 1)).ceil();
      for (var index = 0; index < visibleCount; index++) {
        final point = _dirtPoints[index];
        final pulse = 0.88 + math.sin(_elapsed * 1.4 + index) * 0.08;
        final radius = size.x * (0.014 + (index % 3) * 0.004) * pulse;
        final alpha = (0.10 + dirt * 0.25).clamp(0.0, 0.34).toDouble();
        canvas.drawCircle(
          Offset(size.x * point.dx, size.y * point.dy),
          radius,
          Paint()
            ..color = const Color(0xFF725744).withValues(alpha: alpha)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.6),
        );
      }

      // Dos motas exteriores muy discretas: suficiente para leer "sucio" sin
      // convertir el Home en una nube de partículas.
      for (var index = 0; index < 2; index++) {
        final phase = _elapsed * (0.75 + index * 0.12) + index * math.pi;
        final center = Offset(
          size.x * (index == 0 ? 0.24 : 0.76) + math.sin(phase) * 5,
          size.y * (0.38 + index * 0.15) + math.cos(phase * 0.8) * 7,
        );
        canvas.drawCircle(
          center,
          size.x * 0.009,
          Paint()..color = const Color(0xFF624936).withValues(alpha: dirt * 0.32),
        );
      }
    }

    final cleaning = _cleaningIntensity.clamp(0.0, 1.0).toDouble();
    if (cleaning > 0.05) {
      for (var index = 0; index < 3; index++) {
        final phase = _elapsed * 2.8 + index * 2.1;
        final center = Offset(
          size.x * (0.35 + index * 0.15) + math.sin(phase) * size.x * 0.018,
          size.y * (0.34 + (index % 2) * 0.22) -
              ((_elapsed * 18 + index * 20) % 24),
        );
        final radius = size.x * (0.008 + index * 0.002);
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Colors.white.withValues(alpha: cleaning * 0.52)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.1,
        );
      }
    }
  }
}

class NtiSpeechBubble extends PositionComponent {
  NtiSpeechBubble({required super.position}) : super(size: Vector2(260, 84)) {
    priority = 40;
  }

  String _message = '';
  double _remaining = 0;
  double _visibility = 0;
  double _appearanceElapsed = 0;

  void show(String message, {required double duration}) {
    final wasHidden = _remaining <= 0 && _visibility < 0.05;
    _message = message;
    _remaining = duration;
    if (wasHidden) {
      _appearanceElapsed = 0;
    }
  }

  void hide() {
    _remaining = 0;
    _message = '';
    _appearanceElapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _remaining = math.max(0, _remaining - dt);
    if (_remaining > 0) {
      _appearanceElapsed += dt;
    }
    final target = _remaining > 0 ? 1.0 : 0.0;
    final speed = target > _visibility ? 10.0 : 8.0;
    final factor = (1 - math.exp(-speed * dt)).clamp(0.0, 1.0).toDouble();
    _visibility += (target - _visibility) * factor;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_visibility <= 0.01 || _message.isEmpty) {
      return;
    }

    final alpha = _visibility.clamp(0.0, 1.0).toDouble();
    final intro = (_appearanceElapsed / 0.22).clamp(0.0, 1.0).toDouble();
    final eased = 1 - math.pow(1 - intro, 3).toDouble();
    final scaleValue = 0.90 + eased * 0.10;
    final bubbleRect = Rect.fromLTWH(0, 0, size.x, size.y - 14);
    final bubble = RRect.fromRectAndRadius(
      bubbleRect,
      const Radius.circular(22),
    );

    canvas.save();
    canvas.translate(size.x / 2, (size.y - 14) / 2);
    canvas.scale(scaleValue, scaleValue);
    canvas.translate(-size.x / 2, -(size.y - 14) / 2);

    final shadowBubble = bubble.shift(const Offset(0, 5));
    canvas.drawRRect(
      shadowBubble,
      Paint()
        ..color = const Color(0xFF4A2A67).withValues(alpha: 0.18 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = const Color(0xFFFFF1D6).withValues(alpha: 0.98 * alpha)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      bubble,
      Paint()
        ..color = const Color(0xFF6D3AA5).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    final tail = Path()
      ..moveTo(size.x * 0.45, size.y - 16)
      ..lineTo(size.x * 0.51, size.y)
      ..lineTo(size.x * 0.57, size.y - 16)
      ..close();
    canvas.drawPath(
      tail,
      Paint()..color = const Color(0xFFFFF1D6).withValues(alpha: 0.98 * alpha),
    );
    canvas.drawPath(
      tail,
      Paint()
        ..color = const Color(0xFF6D3AA5).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    _drawGoldSparkle(
      canvas,
      center: Offset(size.x - 22, 17),
      radius: 7,
      alpha: alpha,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: _message,
        style: TextStyle(
          color: const Color(0xFF3D3048).withValues(alpha: alpha),
          fontSize: 17,
          fontWeight: FontWeight.w700,
          fontFamily: 'Fredoka',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: size.x - 38);

    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - 14 - textPainter.height) / 2,
      ),
    );
    canvas.restore();
  }

  void _drawGoldSparkle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
  }) {
    final path = Path();
    for (var index = 0; index < 8; index++) {
      final pointRadius = index.isEven ? radius : radius * 0.28;
      final angle = -math.pi / 2 + index * math.pi / 4;
      final point = Offset(
        center.dx + math.cos(angle) * pointRadius,
        center.dy + math.sin(angle) * pointRadius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()..color = const Color(0xFFE2AA37).withValues(alpha: alpha),
    );
  }
}
