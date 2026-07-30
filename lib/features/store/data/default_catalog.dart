import 'package:flutter_application_1/features/store/domain/shop_item.dart';

const defaultShopCatalog = <ShopItem>[
  ShopItem(
    id: 'skin_purple',
    name: 'Slime morado',
    description: 'Color inicial de la mascota.',
    price: 0,
    kind: ShopItemKind.skin,
    customizationId: 'purple',
  ),
  ShopItem(
    id: 'skin_blue',
    name: 'Slime azul',
    description: 'Un color fresco para tu mascota.',
    price: 50,
    kind: ShopItemKind.skin,
    customizationId: 'blue',
  ),
  ShopItem(
    id: 'skin_green',
    name: 'Slime verde',
    description: 'Una apariencia inspirada en la naturaleza.',
    price: 75,
    kind: ShopItemKind.skin,
    customizationId: 'green',
  ),
  ShopItem(
    id: 'skin_orange',
    name: 'Slime naranja',
    description: 'Una apariencia cálida y alegre.',
    price: 75,
    kind: ShopItemKind.skin,
    customizationId: 'orange',
  ),
  ShopItem(
    id: 'theme_original',
    name: 'Tema original',
    description: 'El fondo clasico de la primera version.',
    price: 0,
    kind: ShopItemKind.theme,
    customizationId: 'original',
  ),
  ShopItem(
    id: 'theme_normal',
    name: 'Tema Aniversario',
    description: 'La apariencia predeterminada de la habitación.',
    price: 100,
    kind: ShopItemKind.theme,
    customizationId: 'normal',
  ),
  ShopItem(
    id: 'theme_techno',
    name: 'Tema Techno',
    description: 'Colores oscuros con acentos de neón.',
    price: 120,
    kind: ShopItemKind.theme,
    customizationId: 'techno',
  ),
  ShopItem(
    id: 'theme_adventure',
    name: 'Tema Aventura',
    description: 'Una habitacion para explorar nuevos mundos.',
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
