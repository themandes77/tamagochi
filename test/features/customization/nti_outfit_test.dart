import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every outfit uses one integrated artwork asset', () {
    expect(NtiOutfit.original.id, 'original');
    expect(NtiOutfit.bodyAssetPath, 'outfits/nti_body_master.png');
    expect(
      NtiOutfit.flutterBodyAssetPath,
      'assets/images/outfits/nti_body_master.png',
    );
    expect(
      NtiOutfit.original.integratedAssetPath,
      'outfits/nti_body_master.png',
    );
    expect(NtiOutfit.anniversary.id, 'anniversary');
    expect(NtiOutfit.anniversary.displayName, 'Aniversario');
    expect(
      NtiOutfit.anniversary.integratedAssetPath,
      'outfits/nti_anniversary_integrated_v1.png',
    );
    expect(
      NtiOutfit.anniversary.flutterArtworkAssetPath,
      'assets/images/outfits/nti_anniversary_integrated_v1.png',
    );
    expect(
      NtiOutfit.techno.integratedAssetPath,
      'outfits/nti_techno_integrated_v3.png',
    );
    expect(
      NtiOutfit.adventurer.integratedAssetPath,
      'outfits/nti_adventurer_integrated_v5.png',
    );
    expect(
      NtiOutfit.values.map((outfit) => outfit.id).toSet(),
      hasLength(NtiOutfit.values.length),
    );
  });

  test('every outfit uses a distinct integrated artwork', () {
    expect(
      NtiOutfit.values.map((outfit) => outfit.integratedAssetPath).toSet(),
      hasLength(NtiOutfit.values.length),
    );
  });
}
