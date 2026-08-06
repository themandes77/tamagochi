import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/domain/nti_outfit.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_platform.dart';
import 'package:flutter_application_1/features/store/presentation/store_showcase_stage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const stageSizes = <String, Size>{
    'compact mobile': Size(320, 180),
    'large mobile': Size(430, 215),
    'landscape': Size(844, 330),
  };

  for (final entry in stageSizes.entries) {
    testWidgets('anchors NTI to the platform on ${entry.key}', (tester) async {
      final stageSize = entry.value;

      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: stageSize.width,
              height: stageSize.height,
              child: StoreShowcaseStage(
                outfit: NtiOutfit.original,
                message: 'Vista previa',
                foregroundHeight: stageSize.height,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final stageRect = tester.getRect(
        find.byKey(const ValueKey('store_showcase_stage')),
      );
      final backgroundRect = tester.getRect(
        find.byKey(const ValueKey('store_showcase_room_asset')),
      );
      final platformRect = tester.getRect(
        find.byKey(const ValueKey('store_showcase_platform_anchor')),
      );
      final ntiRect = tester.getRect(
        find.byKey(const ValueKey('store_showcase_nti_anchor')),
      );

      expect(backgroundRect, stageRect);
      expect(platformRect.center.dx, closeTo(stageRect.center.dx, 0.1));
      expect(ntiRect.center.dx, closeTo(platformRect.center.dx, 0.1));
      expect(ntiRect.top, greaterThanOrEqualTo(stageRect.top - 0.1));
      expect(ntiRect.bottom, greaterThan(platformRect.top));
      expect(ntiRect.bottom, lessThan(platformRect.bottom));
      expect(platformRect.width, lessThan(stageRect.width));

      final platformAsset = tester.widget<Image>(
        find.byKey(const ValueKey('store_showcase_platform_asset')),
      );
      expect(
        (platformAsset.image as AssetImage).assetName,
        StoreShowcasePlatform.assetPath,
      );
    });
  }
}
