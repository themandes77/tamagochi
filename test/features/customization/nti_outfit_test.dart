import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('outfits share one body and expose only clothing overlays', () {
    expect(NtiOutfit.original.id, 'original');
    expect(NtiOutfit.bodyAssetPath, 'outfits/nti_body_master.png');
    expect(
      NtiOutfit.flutterBodyAssetPath,
      'assets/images/outfits/nti_body_master.png',
    );
    expect(NtiOutfit.original.overlayAssetPath, isNull);
    expect(NtiOutfit.original.flutterOverlayAssetPath, isNull);
    expect(NtiOutfit.anniversary.id, 'anniversary');
    expect(NtiOutfit.anniversary.displayName, 'Aniversario');
    expect(
      NtiOutfit.anniversary.overlayAssetPath,
      'outfits/nti_anniversary_overlay.png',
    );
    expect(NtiOutfit.techno.overlayAssetPath, 'outfits/nti_techno_overlay.png');
    expect(
      NtiOutfit.adventurer.overlayAssetPath,
      'outfits/nti_adventurer_overlay_v2.png',
    );
    expect(
      NtiOutfit.values.map((outfit) => outfit.id).toSet(),
      hasLength(NtiOutfit.values.length),
    );
  });
}
