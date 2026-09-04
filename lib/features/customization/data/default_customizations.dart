import 'package:flutter_application_1/features/customization/domain/pet_skin.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';

const defaultPetSkins = <PetSkin>[
  PetSkin(
    id: 'purple',
    displayName: 'Morado',
    previewColorValue: 0xFF9B59B6,
    spriteSheetAsset: 'assets/Slimes/slime_idle2.png',
    spriteRow: 0,
  ),
  PetSkin(
    id: 'blue',
    displayName: 'Azul',
    previewColorValue: 0xFF55BDEB,
    spriteSheetAsset: 'assets/Slimes/slime_idle2.png',
    spriteRow: 3,
  ),
  PetSkin(
    id: 'green',
    displayName: 'Verde',
    previewColorValue: 0xFF8BCF45,
    spriteSheetAsset: 'assets/Slimes/slime_idle2.png',
    spriteRow: 4,
  ),
  PetSkin(
    id: 'orange',
    displayName: 'Naranja',
    previewColorValue: 0xFFF39C45,
    spriteSheetAsset: 'assets/Slimes/slime_idle2.png',
    spriteRow: 2,
  ),
];

const defaultThemeOptions = <ThemeOption>[
  ThemeOption(
    id: 'original',
    displayName: 'Original',
    backgroundAssetPath: null,
    backgroundColorValue: 0xFFEEEEEE,
    surfaceColorValue: 0xFFFFFFFF,
    accentColorValue: 0xFF7E57C2,
  ),
  ThemeOption(
    id: 'normal',
    displayName: 'Aniversario',
    backgroundAssetPath: 'backgrounds/room_normal_anniversary.png',
    backgroundColorValue: 0xFFF3F0F7,
    surfaceColorValue: 0xFFFFFFFF,
    accentColorValue: 0xFF7E57C2,
  ),
  ThemeOption(
    id: 'techno',
    displayName: 'Techno',
    backgroundAssetPath: 'backgrounds/room_techno.png',
    backgroundColorValue: 0xFF10131A,
    surfaceColorValue: 0xFF1B2230,
    accentColorValue: 0xFF00E5FF,
  ),
  ThemeOption(
    id: 'adventure',
    displayName: 'Aventura',
    backgroundAssetPath: 'backgrounds/room_adventure.png',
    backgroundColorValue: 0xFFF4E5CE,
    surfaceColorValue: 0xFFFFF9F0,
    accentColorValue: 0xFFD44D3F,
  ),
];

PetSkin? petSkinById(String id) {
  for (final skin in defaultPetSkins) {
    if (skin.id == id) {
      return skin;
    }
  }
  return null;
}

ThemeOption? themeOptionById(String id) {
  for (final theme in defaultThemeOptions) {
    if (theme.id == id) {
      return theme;
    }
  }
  return null;
}
