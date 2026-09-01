import 'package:flutter_application_1/features/customization/domain/theme_option.dart';

const defaultThemeOptions = <ThemeOption>[
  ThemeOption(
    id: 'original',
    displayName: 'Original',
    backgroundAssetPath: 'backgrounds/room_original.png',
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

ThemeOption? themeOptionById(String id) {
  for (final theme in defaultThemeOptions) {
    if (theme.id == id) {
      return theme;
    }
  }
  return null;
}
