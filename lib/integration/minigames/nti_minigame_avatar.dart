import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';

/// Representación visual compartida de NTI para minijuegos.
///
/// Conserva la identidad visual de Azael (outfit + NtiFace) y únicamente el
/// idle que no interfiere con las físicas del juego: parpadeo, mirada, sonrisa,
/// respiración sutil e inclinación mínima. Posición, hitbox y movimiento siguen
/// perteneciendo por completo al minijuego anfitrión.
class NtiMinigameAvatar {
  NtiMinigameAvatar({required this.outfit})
    : _face = NtiFace(size: Vector2.all(_referenceExtent), outfit: outfit);

  static const double _referenceExtent = 360;

  final NtiOutfit outfit;
  final NtiFace _face;
  Sprite? _body;
  double _elapsed = 0;

  Future<void> load() async {
    _body = await Sprite.load(outfit.artworkAssetPath);
  }

  void update(double dt) {
    if (dt <= 0) {
      return;
    }
    _elapsed += dt;
    _face.update(dt);
  }

  void render(
    Canvas canvas, {
    required Vector2 position,
    required Vector2 size,
  }) {
    final body = _body;
    if (body == null || size.x <= 0 || size.y <= 0) {
      return;
    }

    final breath = math.sin(_elapsed * math.pi) * 0.008;
    final tilt = math.sin(_elapsed * 0.8) * 0.007;
    final visualScale = 1 + breath;
    final scaleX = (size.x / _referenceExtent) * visualScale;
    final scaleY = (size.y / _referenceExtent) * visualScale;
    final center = Offset(position.x + size.x / 2, position.y + size.y / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.scale(scaleX, scaleY);
    canvas.translate(-_referenceExtent / 2, -_referenceExtent / 2);

    body.render(
      canvas,
      position: Vector2.zero(),
      size: Vector2.all(_referenceExtent),
    );
    _face.render(canvas);
    canvas.restore();
  }
}
