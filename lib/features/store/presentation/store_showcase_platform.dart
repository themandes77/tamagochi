import 'package:flutter/material.dart';

class StoreShowcasePlatform extends StatelessWidget {
  static const assetPath = 'assets/images/ui/store_showcase_platform_v1.png';
  static const aspectRatio = 1234 / 403;

  const StoreShowcasePlatform({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: const ValueKey('store_showcase_platform_asset'),
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}
