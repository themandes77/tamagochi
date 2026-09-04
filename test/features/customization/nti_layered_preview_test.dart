import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('integrated outfits render as one image', (tester) async {
    for (final outfit in NtiOutfit.values) {
      await tester.pumpWidget(
        MaterialApp(home: NtiStaticPreview(outfit: outfit)),
      );

      final assetNames = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toList();

      expect(assetNames, [outfit.flutterArtworkAssetPath]);
    }
  });
}
