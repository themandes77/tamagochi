import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';
import 'package:flutter_application_1/integration/audio/game_sound_effects.dart';

/// Botón circular de regreso usado en el encabezado de la tienda.
class StoreBackButton extends StatefulWidget {
  const StoreBackButton({
    required this.tooltip,
    required this.onPressed,
    this.size = 54,
    super.key,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final double size;

  @override
  State<StoreBackButton> createState() => _StoreBackButtonState();
}

class _StoreBackButtonState extends State<StoreBackButton> {
  static const _assetPath = 'assets/images/ui/store_back_button_v1.png';

  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          duration: StoreVisualTokens.quick,
          scale: _isPressed ? 0.94 : 1,
          child: SizedBox.square(
            dimension: widget.size,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.none,
              child: Ink(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x703A2252),
                      blurRadius: 5,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onHighlightChanged: (value) {
                    if (_isPressed == value) {
                      return;
                    }
                    setState(() => _isPressed = value);
                  },
                  onTap: () {
                    GameSoundEffects.playButton();
                    widget.onPressed();
                  },
                  splashColor: const Color(0x55FFF1B5),
                  highlightColor: const Color(0x227744B8),
                  child: Image.asset(
                    _assetPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
