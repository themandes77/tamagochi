import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const responsiveViewports = <Size>[
    Size(320, 568),
    Size(360, 640),
    Size(390, 844),
    Size(667, 375),
    Size(844, 390),
    Size(600, 960),
    Size(1024, 768),
    Size(1440, 900),
  ];

  test('store theme uses Fredoka typography', () {
    final theme = storeThemeFrom(
      const ThemeOption(
        id: 'test',
        displayName: 'Test',
        backgroundAssetPath: null,
        backgroundColorValue: 0xFFFFFFFF,
        surfaceColorValue: 0xFFFFFFFF,
        accentColorValue: 0xFFFFFFFF,
      ),
    );

    expect(theme.textTheme.bodyMedium?.fontFamily, 'Fredoka');
  });

  testWidgets('renders store balance and catalog', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    expect(find.bySemanticsLabel('TIENDA'), findsOneWidget);
    final titleImage = tester.widget<Image>(
      find.byKey(const ValueKey('store_title_asset')),
    );
    expect(
      (titleImage.image as AssetImage).assetName,
      'assets/images/ui/store_title_v1.png',
    );
    expect(find.text('200'), findsOneWidget);
    expect(find.text('TRAJES'), findsOneWidget);
    expect(find.text('Aniversario'), findsOneWidget);
    expect(find.text('Techno'), findsOneWidget);

    await tester.tap(find.text('FONDOS'));
    await tester.pump();

    expect(find.text('Fondo Original'), findsOneWidget);
    expect(find.text('Fondo Aniversario'), findsOneWidget);
  });

  testWidgets('does not render an owned-items section', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    expect(find.byKey(const ValueKey('open_inventory')), findsNothing);
    expect(find.byKey(const ValueKey('open_store')), findsNothing);
    expect(find.text('MIS ARTÍCULOS'), findsNothing);
  });

  testWidgets('all catalog NTI previews use the same base canvas', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.drag(
      find.byKey(const ValueKey('store_page')),
      const Offset(0, -320),
    );
    await tester.pump();

    final previews = tester
        .widgetList<NtiStaticPreview>(find.byType(NtiStaticPreview))
        .toList();
    expect(previews, hasLength(4));
    expect(previews.map((preview) => preview.size).toSet(), hasLength(1));
  });

  testWidgets('buys and equips a real outfit from the catalog', (tester) async {
    _useMobileViewport(tester);
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    final anniversaryAction = find.byKey(
      const ValueKey('store_action_outfit_anniversary'),
    );
    await tester.ensureVisible(anniversaryAction);
    await tester.tap(anniversaryAction);
    await tester.pump();

    expect(controller.coins, 100);
    expect(controller.ownedItemIds, contains('outfit_anniversary'));
    expect(find.text('Equipar'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.ensureVisible(anniversaryAction);
    await tester.tap(anniversaryAction);
    await tester.pump();

    expect(controller.equippedOutfitId, 'anniversary');
    expect(find.text('Equipado'), findsOneWidget);
  });

  for (final viewport in responsiveViewports) {
    testWidgets(
      'renders without overflow at ${viewport.width.toInt()}x${viewport.height.toInt()}',
      (tester) async {
        _useViewport(tester, viewport);
        final controller = StoreController(
          repository: InMemoryStoreRepository(),
        );
        await controller.initialize();

        await tester.pumpWidget(StorePreviewApp(controller: controller));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.bySemanticsLabel('TIENDA'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byKey(const ValueKey('store_page')),
          const Offset(0, -160),
        );
        await tester.pump();

        expect(find.text('TRAJES'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.drag(
          find.byKey(const ValueKey('store_page')),
          const Offset(0, -320),
        );
        await tester.pump();

        expect(find.text('Aventurero'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

void _useMobileViewport(WidgetTester tester) {
  _useViewport(tester, const Size(390, 844));
}

void _useViewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
