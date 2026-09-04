import 'package:flutter_application_1/features/store/domain/shop_item.dart';

const defaultShopCatalog = <ShopItem>[
  ShopItem(
    id: 'outfit_original',
    name: 'Original',
    description: 'El aspecto clásico de NTI.',
    price: 0,
    kind: ShopItemKind.outfit,
    customizationId: 'original',
  ),
  ShopItem(
    id: 'outfit_anniversary',
    name: 'Aniversario',
    description: 'Corona y traje de celebración.',
    price: 100,
    kind: ShopItemKind.outfit,
    customizationId: 'anniversary',
  ),
  ShopItem(
    id: 'outfit_techno',
    name: 'Techno',
    description: 'Visor y accesorios con luces neón.',
    price: 120,
    kind: ShopItemKind.outfit,
    customizationId: 'techno',
  ),
  ShopItem(
    id: 'outfit_adventurer',
    name: 'Aventurero',
    description: 'Pañuelo, capa y cinturón de explorador.',
    price: 140,
    kind: ShopItemKind.outfit,
    customizationId: 'adventurer',
  ),
  ShopItem(
    id: 'theme_original',
    name: 'Fondo Original',
    description: 'El fondo clásico de la primera versión.',
    price: 0,
    kind: ShopItemKind.theme,
    customizationId: 'original',
  ),
  ShopItem(
    id: 'theme_normal',
    name: 'Fondo Aniversario',
    description: 'Una habitación cálida para celebrar.',
    price: 100,
    kind: ShopItemKind.theme,
    customizationId: 'normal',
  ),
  ShopItem(
    id: 'theme_techno',
    name: 'Fondo Techno',
    description: 'Una habitación con luces de neón.',
    price: 120,
    kind: ShopItemKind.theme,
    customizationId: 'techno',
  ),
  ShopItem(
    id: 'theme_adventure',
    name: 'Fondo Aventura',
    description: 'Una habitación para explorar nuevos mundos.',
    price: 140,
    kind: ShopItemKind.theme,
    customizationId: 'adventure',
  ),
];

ShopItem? shopItemById(String id) {
  for (final item in defaultShopCatalog) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
}
