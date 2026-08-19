import 'package:flutter_application_1/features/customization/data/default_customizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('themes expose stable unique ids and background assets', () {
    expect(themeOptionById('original')?.displayName, 'Original');
    expect(
      themeOptionById('original')?.backgroundAssetPath,
      'backgrounds/room_original.png',
    );
    expect(themeOptionById('normal')?.displayName, 'Aniversario');
    expect(
      themeOptionById('normal')?.backgroundAssetPath,
      'backgrounds/room_normal_anniversary.png',
    );
    expect(
      themeOptionById('techno')?.backgroundAssetPath,
      'backgrounds/room_techno.png',
    );
    expect(
      themeOptionById('adventure')?.backgroundAssetPath,
      'backgrounds/room_adventure.png',
    );
    expect(
      defaultThemeOptions.map((theme) => theme.id).toSet(),
      hasLength(defaultThemeOptions.length),
    );
  });
}
