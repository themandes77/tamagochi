import 'package:flutter/material.dart';

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({
    required this.label,
    required this.backgroundAsset,
    required this.onPressed,
    required this.enabled,
    this.selected = false,
    super.key,
  });

  final String label;
  final String backgroundAsset;
  final VoidCallback onPressed;
  final bool enabled;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          child: InkResponse(
            onTap: enabled ? onPressed : null,
            radius: 42,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              scale: selected ? 1.06 : 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        Image.asset(
                          backgroundAsset,
                          fit: BoxFit.contain,
                        ),
                        if (selected)
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(
                                    color: Color(0x667E57C2),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        shadows: <Shadow>[
                          Shadow(
                            color: Color(0xFF512B63),
                            offset: Offset(0, 2),
                            blurRadius: 1,
                          ),
                        ],
                      ),
                    ),
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
