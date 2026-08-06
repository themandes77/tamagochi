import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

/// Contador de monedas compuesto por un marco, una cantidad dinámica y moneda.
class StoreCoinBalance extends StatelessWidget {
  const StoreCoinBalance({
    required this.coins,
    this.compact = false,
    this.width,
    this.height,
    super.key,
  });

  static const _frameAssetPath = 'assets/images/ui/coin_balance_frame_v1.png';
  static const _coinAssetPath = 'assets/images/ui/coin_star_v1.png';

  final int coins;
  final bool compact;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? (compact ? 88.0 : 104.0);
    final resolvedHeight = height ?? (compact ? 42.0 : 48.0);
    final horizontalScale = resolvedWidth / 104;
    final verticalScale = resolvedHeight / 48;
    final contentScale = horizontalScale < verticalScale
        ? horizontalScale
        : verticalScale;

    return Semantics(
      key: const ValueKey('coin_balance_semantics'),
      label: '$coins monedas',
      child: SizedBox(
        width: resolvedWidth,
        height: resolvedHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _frameAssetPath,
              key: const ValueKey('coin_balance_frame_asset'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                13 * horizontalScale,
                7 * verticalScale,
                10 * horizontalScale,
                9 * verticalScale,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: StoreVisualTokens.normal,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: FittedBox(
                        key: ValueKey(coins),
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$coins',
                          style: TextStyle(
                            color: const Color(0xFFFFF1C4),
                            fontWeight: FontWeight.w700,
                            fontSize: 20 * contentScale,
                            height: 1,
                            shadows: [
                              Shadow(
                                color: Color(0xAA3A2252),
                                blurRadius: 1,
                                offset: Offset(0, 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 5 * horizontalScale),
                  Image.asset(
                    _coinAssetPath,
                    key: const ValueKey('coin_star_asset'),
                    width: 29 * contentScale,
                    height: 29 * contentScale,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
