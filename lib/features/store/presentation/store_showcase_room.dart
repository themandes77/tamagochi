import 'package:flutter/material.dart';

class StoreShowcaseRoom extends StatelessWidget {
  static const assetPath = 'assets/images/ui/store_showcase_room_v1.png';

  const StoreShowcaseRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      key: const ValueKey('store_showcase_room_asset'),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      excludeFromSemantics: true,
    );
  }
}
