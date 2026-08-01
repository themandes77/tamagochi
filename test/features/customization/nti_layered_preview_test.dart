import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('every preview starts with the exact same master body', (
    tester,
  ) async {
    for (final outfit in NtiOutfit.values) {
      await tester.pumpWidget(
        MaterialApp(home: NtiStaticPreview(outfit: outfit)),
      );

      final assetNames = tester
          .widgetList<Image>(find.byType(Image))
          .map((image) => (image.image as AssetImage).assetName)
          .toList();

      expect(assetNames.first, NtiOutfit.flutterBodyAssetPath);
      expect(
        assetNames.skip(1),
        outfit.flutterOverlayAssetPath == null
            ? isEmpty
            : equals([outfit.flutterOverlayAssetPath]),
      );
    }
  });
}
