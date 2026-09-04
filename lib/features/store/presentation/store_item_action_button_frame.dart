import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

class StoreItemActionButtonFrame extends StatelessWidget {
  static const priceAssetPath = 'assets/images/ui/price_button_frame_v1.png';
  static const statusAssetPath =
      'assets/images/ui/equipped_button_frame_v1.png';

  const StoreItemActionButtonFrame({
    required this.isPrice,
    required this.child,
    super.key,
  });

  final bool isPrice;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          isPrice
              ? StoreVisualTokens.priceButtonShadow
              : StoreVisualTokens.statusButtonShadow,
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            isPrice ? priceAssetPath : statusAssetPath,
            key: ValueKey(
              isPrice
                  ? 'store_price_button_frame_asset'
                  : 'store_status_button_frame_asset',
            ),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          child,
        ],
      ),
    );
  }
}
