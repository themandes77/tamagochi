import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outfits expose stable unique ids and asset paths', () {
    expect(NtiOutfit.original.id, 'original');
    expect(NtiOutfit.original.assetPath, 'outfits/nti_original.png');
    expect(NtiOutfit.anniversary.id, 'anniversary');
    expect(NtiOutfit.anniversary.displayName, 'Aniversario');
    expect(NtiOutfit.techno.assetPath, 'outfits/nti_techno.png');
    expect(NtiOutfit.adventurer.assetPath, 'outfits/nti_adventurer.png');
    expect(
      NtiOutfit.values.map((outfit) => outfit.id).toSet(),
      hasLength(NtiOutfit.values.length),
    );
  });
}
