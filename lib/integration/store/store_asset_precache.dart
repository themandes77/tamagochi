import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';

class StoreAssetPrecache {
  const StoreAssetPrecache._();

  static const _uiAssets = <String>[
    'assets/images/ui/catalog_hint_star_v1.png',
    'assets/images/ui/catalog_panel_v1.png',
    'assets/images/ui/category_tab_inactive_v1.png',
    'assets/images/ui/category_tab_selected_v1.png',
    'assets/images/ui/coin_balance_frame_v1.png',
    'assets/images/ui/coin_star_v1.png',
    'assets/images/ui/equipped_button_frame_v1.png',
    'assets/images/ui/item_card_frame_v1.png',
    'assets/images/ui/price_button_frame_v1.png',
    'assets/images/ui/store_back_button_v1.png',
    'assets/images/ui/store_header_panel_v1.png',
    'assets/images/ui/store_showcase_platform_v1.png',
    'assets/images/ui/store_showcase_room_background_v2.png',
    'assets/images/ui/store_showcase_room_v1.png',
    'assets/images/ui/store_title_v1.png',
  ];

  /// Precarga oportunista: nunca bloquea la entrada al Home.
  ///
  /// Se prioriza el chrome de la Tienda y los outfits, que son los recursos
  /// visibles en la categoría inicial. Los fondos de temas se cargan bajo
  /// demanda cuando el usuario entra a esa categoría.
  static Future<void> precache(BuildContext context) async {
    final assets = <String>{
      ..._uiAssets,
      for (final outfit in NtiOutfit.values) outfit.flutterArtworkAssetPath,
    };

    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (_) {
        // La precarga es una optimización. Un fallo aquí no debe impedir que
        // la Tienda cargue el asset normalmente cuando se abra.
      }
    }
  }
}
