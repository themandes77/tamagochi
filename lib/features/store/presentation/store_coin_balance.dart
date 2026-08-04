import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

/// Contador de monedas compuesto por un marco, una cantidad dinámica y moneda.
class StoreCoinBalance extends StatelessWidget {
  const StoreCoinBalance({
    required this.coins,
    this.compact = false,
    super.key,
  });

  static const _frameAssetPath = 'assets/images/ui/coin_balance_frame_v1.png';
  static const _coinAssetPath = 'assets/images/ui/coin_star_v1.png';

  final int coins;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('coin_balance_semantics'),
      label: '$coins monedas',
      child: SizedBox(
        width: compact ? 88 : 104,
        height: compact ? 42 : 48,
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
              padding: compact
                  ? const EdgeInsets.fromLTRB(10, 6, 8, 8)
                  : const EdgeInsets.fromLTRB(13, 7, 10, 9),
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
                            color: Color(0xFFFFF1C4),
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 17 : 20,
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
                  SizedBox(width: compact ? 3 : 5),
                  Image.asset(
                    _coinAssetPath,
                    key: const ValueKey('coin_star_asset'),
                    width: compact ? 24 : 29,
                    height: compact ? 24 : 29,
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
