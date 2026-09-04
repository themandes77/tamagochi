import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/domain/shop_item.dart';
import 'package:flutter_application_1/features/store/presentation/store_visual_tokens.dart';

class StoreCatalogHint extends StatelessWidget {
  static const starAssetPath = 'assets/images/ui/catalog_hint_star_v1.png';

  const StoreCatalogHint({
    required this.selectedKind,
    required this.isStorePage,
    super.key,
  });

  final ShopItemKind selectedKind;
  final bool isStorePage;

  @override
  Widget build(BuildContext context) {
    final message = isStorePage
        ? selectedKind == ShopItemKind.outfit
              ? 'Los trajes cambian la apariencia de tu NTI.'
              : 'Los fondos transforman la habitación de NTI.'
        : 'Toca un artículo para verlo y equiparlo.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            starAssetPath,
            key: const ValueKey('store_catalog_hint_star_asset'),
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StoreVisualTokens.purpleDark,
                fontWeight: FontWeight.w600,
                fontSize: 15.5,
                height: 1.05,
                shadows: [StoreVisualTokens.textShadow],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
