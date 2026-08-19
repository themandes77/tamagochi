import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/customization/presentation/animated_nti_preview.dart';
import 'package:flutter_application_1/features/customization/domain/theme_option.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_category_tabs.dart';
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

  const catalogEdgeViewports = <String, Size>{
    'Samsung mobile': Size(360, 800),
    'iPhone 12': Size(390, 844),
    'Pixel 7': Size(412, 915),
    'iPhone XR': Size(414, 896),
    'iPhone 14 Pro Max': Size(430, 932),
  };

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
    expect(find.text('500'), findsOneWidget);
    expect(find.text('TRAJES'), findsOneWidget);
    expect(find.text('Aniversario'), findsOneWidget);
    expect(find.text('Techno'), findsOneWidget);

    await tester.tap(find.text('FONDOS'));
    await tester.pump();

    expect(find.text('Fondo Original'), findsOneWidget);
    expect(find.text('Fondo Aniversario'), findsOneWidget);
  });

  testWidgets('header follows the reference proportions', (tester) async {
    _useViewport(tester, const Size(500, 920));
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    final backRect = tester.getRect(
      find.byKey(const ValueKey('store_header_back_slot')),
    );
    final titleRect = tester.getRect(
      find.byKey(const ValueKey('store_header_title_slot')),
    );
    final balanceRect = tester.getRect(
      find.byKey(const ValueKey('store_header_balance_slot')),
    );
    final panelImage = tester.widget<Image>(
      find.byKey(const ValueKey('store_header_panel_asset')),
    );
    final appBar = tester.widget<AppBar>(find.byType(AppBar));

    expect(backRect.left, closeTo(500 * 45 / 942, 0.1));
    expect(backRect.width, closeTo(500 * 116 / 942, 0.1));
    expect(titleRect.center.dx, closeTo(250, 0.1));
    expect(titleRect.width, closeTo(500 * 333 / 942, 0.1));
    expect(balanceRect.right, closeTo(500 - 500 * 39 / 942, 0.1));
    expect(balanceRect.width, closeTo(500 * 204 / 942, 0.1));
    expect(panelImage.fit, BoxFit.fill);
    expect(find.byKey(const ValueKey('store_header_panel_crop')), findsNothing);
    expect(appBar.backgroundColor, Colors.transparent);
    final appBarRect = tester.getRect(find.byType(AppBar));
    final roomRect = tester.getRect(
      find.byKey(const ValueKey('store_showcase_room_asset')),
    );
    expect(roomRect.top, lessThan(appBarRect.bottom));
    expect(
      find.byKey(const ValueKey('store_showcase_room_asset')),
      findsOneWidget,
    );
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

  testWidgets('selected theme fills the entire showcase without distortion', (
    tester,
  ) async {
    _useViewport(tester, const Size(430, 932));
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.tap(find.byKey(const ValueKey('category_fondos')));
    await tester.pump(const Duration(milliseconds: 450));
    await tester.tap(find.byKey(const ValueKey('store_item_theme_normal')));
    await tester.pump(const Duration(milliseconds: 450));

    final showcaseRect = tester.getRect(
      find.byKey(const ValueKey('store_theme_showcase')),
    );
    final selectedBackground = find
        .byKey(const ValueKey('store_theme_background_asset'))
        .last;
    final backgroundRect = tester.getRect(selectedBackground);
    final background = tester.widget<Image>(selectedBackground);

    expect(backgroundRect, showcaseRect.deflate(3));
    expect(background.fit, BoxFit.cover);
  });

  for (final viewportEntry in catalogEdgeViewports.entries) {
    testWidgets('catalog panel reaches every edge on ${viewportEntry.key}', (
      tester,
    ) async {
      final viewport = viewportEntry.value;
      _useViewport(tester, viewport);
      final controller = StoreController(repository: InMemoryStoreRepository());
      await controller.initialize();

      await tester.pumpWidget(StorePreviewApp(controller: controller));

      final outfitsTabRect = tester.getRect(
        find.byKey(const ValueKey('category_tab_trajes_background')),
      );
      final themesTabRect = tester.getRect(
        find.byKey(const ValueKey('category_tab_fondos_background')),
      );
      final initialPanelRect = tester.getRect(
        find.byKey(const ValueKey('store_catalog_panel_asset')),
      );
      final showcaseBackgroundRect = tester.getRect(
        find.byKey(const ValueKey('store_showcase_room_asset')),
      );
      expect(showcaseBackgroundRect.left, closeTo(0, 0.1));
      expect(showcaseBackgroundRect.right, closeTo(viewport.width, 0.1));
      expect(showcaseBackgroundRect.bottom, closeTo(initialPanelRect.top, 0.1));
      expect(outfitsTabRect.top, lessThan(showcaseBackgroundRect.bottom));
      expect(themesTabRect.top, lessThan(showcaseBackgroundRect.bottom));
      expect(
        outfitsTabRect.bottom - initialPanelRect.top,
        closeTo(StoreCategoryTabs.panelOverlap, 0.1),
      );
      expect(
        themesTabRect.bottom - initialPanelRect.top,
        closeTo(StoreCategoryTabs.panelOverlap, 0.1),
      );

      await tester.drag(
        find.byKey(const ValueKey('store_page')),
        const Offset(0, -1200),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final panelRect = tester.getRect(
        find.byKey(const ValueKey('store_catalog_panel_asset')),
      );
      expect(panelRect.left, closeTo(0, 0.1));
      expect(panelRect.right, closeTo(viewport.width, 0.1));
      expect(panelRect.bottom, closeTo(viewport.height, 0.1));
    });
  }

  testWidgets(
    'catalog action buttons stay centered at a shared compact width',
    (tester) async {
      _useViewport(tester, const Size(430, 932));
      final controller = StoreController(repository: InMemoryStoreRepository());
      await controller.initialize();

      await tester.pumpWidget(StorePreviewApp(controller: controller));

      const itemIds = <String>[
        'outfit_original',
        'outfit_anniversary',
        'outfit_techno',
        'outfit_adventurer',
      ];
      final actionRects = <Rect>[];

      for (final itemId in itemIds) {
        final cardRect = tester.getRect(
          find.byKey(ValueKey('store_item_$itemId')),
        );
        final actionRect = tester.getRect(
          find.byKey(ValueKey('store_action_$itemId')),
        );
        actionRects.add(actionRect);

        expect(actionRect.center.dx, closeTo(cardRect.center.dx, 0.1));
        expect(actionRect.width, lessThan(cardRect.width * 0.85));
        expect(actionRect.height, closeTo(32 * 0.985, 0.1));
      }

      expect(actionRects.map((rect) => rect.width).toSet(), hasLength(1));
    },
  );

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

    expect(controller.coins, 400);
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
