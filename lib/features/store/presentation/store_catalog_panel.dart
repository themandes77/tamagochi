import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

class StoreCatalogPanel extends StatelessWidget {
  static const assetPath = 'assets/images/ui/catalog_panel_v1.png';

  const StoreCatalogPanel({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 24, 24, 22),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StoreVisualTokens.panelRadius),
        boxShadow: const [StoreVisualTokens.panelShadow],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              assetPath,
              key: const ValueKey('store_catalog_panel_asset'),
              fit: BoxFit.fill,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
