import 'dart:math' as math;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              const labelHeight = 18.0;
              const gap = 3.0;
              final maxIconHeight = math.max(
                0.0,
                constraints.maxHeight - labelHeight - gap,
              );
              final iconSide = math.min(
                constraints.maxWidth * 0.94,
                maxIconHeight,
              );

              return InkResponse(
                onTap: enabled ? onPressed : null,
                radius: math.max(36, constraints.maxWidth * 0.52),
                containedInkWell: false,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 140),
                  scale: selected ? 1.045 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: iconSide,
                        child: Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: <Widget>[
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(1.5),
                                child: Image.asset(
                                  backgroundAsset,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                            ),
                            if (selected)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
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
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        height: labelHeight,
                        width: double.infinity,
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                height: 1,
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
