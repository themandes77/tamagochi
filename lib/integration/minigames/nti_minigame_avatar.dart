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
    : _face = NtiFace(
        size: Vector2.all(_referenceExtent),
        outfit: outfit,
        // A escalas de 50–70 px los rasgos del Home pierden peso óptico por
        // rasterización. Estos ajustes son exclusivos del avatar de minijuego:
        // Home conserva exactamente su renderer canónico.
        eyeScale: 1.08,
        eyeCenterYOffset: 0.010,
        mouthCenterYOffset: 0.022,
      );

  static const double _referenceExtent = 360;

  // Las hitboxes de Marco son rectangulares (Salto 60×75, Recolección 54×68).
  // El primer fix encajaba un cuadrado usando sólo el ancho (60×60 / 54×54),
  // corrigiendo el 'huevo' pero haciendo a NTI demasiado pequeño. Recuperamos
  // presencia visual con +14% de ancho, sin superar la altura de la hitbox.
  // Resultado de referencia: ~68×68 / ~61×61. La hitbox NO cambia.
  static const double _visualWidthScale = 1.14;

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
    double visualOffsetY = 0,
  }) {
    final body = _body;
    if (body == null || size.x <= 0 || size.y <= 0) {
      return;
    }

    final breath = math.sin(_elapsed * math.pi) * 0.008;
    final tilt = math.sin(_elapsed * 0.8) * 0.007;
    final visualScale = 1 + breath;

    // La caja lógica de Marco es rectangular (por ejemplo 60x75), pero el
    // artwork de NTI y NtiFace es cuadrado. Escalar X/Y por separado lo
    // deformaba visualmente en un óvalo. Renderizamos siempre 1:1 y permitimos
    // que el dibujo sobresalga sólo unos pocos píxeles a izquierda/derecha
    // para conservar la presencia óptica de Home. La física/hitbox no cambia.
    final visualExtent = math.min(size.x * _visualWidthScale, size.y);
    final uniformScale =
        (visualExtent / _referenceExtent) * visualScale;

    // Alineamos el cuadrado visual con la base de la caja lógica para que la
    // corrección de aspect ratio no haga flotar a NTI sobre las plataformas.
    final center = Offset(
      position.x + size.x / 2,
      position.y + visualOffsetY + size.y - visualExtent / 2,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    canvas.scale(uniformScale, uniformScale);
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
