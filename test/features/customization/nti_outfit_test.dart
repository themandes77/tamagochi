import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outfits expose stable unique ids and asset paths', () {
    expect(NtiOutfit.original.id, 'original');
    expect(NtiOutfit.original.assetPath, 'outfits/nti_original_round.png');
    expect(
      NtiOutfit.original.flutterAssetPath,
      'assets/images/outfits/nti_original_round.png',
    );
    expect(NtiOutfit.anniversary.id, 'anniversary');
    expect(NtiOutfit.anniversary.displayName, 'Aniversario');
    expect(NtiOutfit.techno.assetPath, 'outfits/nti_techno_round.png');
    expect(NtiOutfit.adventurer.assetPath, 'outfits/nti_adventurer_round.png');
    expect(
      NtiOutfit.values.map((outfit) => outfit.id).toSet(),
      hasLength(NtiOutfit.values.length),
    );
  });
}
