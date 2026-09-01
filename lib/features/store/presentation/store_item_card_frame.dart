import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

class StoreItemCardFrame extends StatelessWidget {
  static const assetPath = 'assets/images/ui/item_card_frame_v1.png';

  const StoreItemCardFrame({
    required this.child,
    required this.selected,
    super.key,
  });

  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: StoreVisualTokens.normal,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StoreVisualTokens.cardRadius),
        boxShadow: const [StoreVisualTokens.cardShadow],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            key: const ValueKey('store_item_card_frame_asset'),
            fit: BoxFit.fill,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          IgnorePointer(
            child: AnimatedContainer(
              duration: StoreVisualTokens.normal,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  StoreVisualTokens.cardRadius,
                ),
                border: Border.all(
                  color: selected
                      ? StoreVisualTokens.purple
                      : Colors.transparent,
                  width: 3,
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
