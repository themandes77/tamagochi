import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_catalog_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the generated catalog panel behind its child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StoreCatalogPanel(child: Text('Contenido interactivo')),
        ),
      ),
    );

    final image = tester.widget<Image>(
      find.byKey(const ValueKey('store_catalog_panel_asset')),
    );
    final provider = image.image as AssetImage;

    expect(provider.assetName, StoreCatalogPanel.assetPath);
    expect(find.text('Contenido interactivo'), findsOneWidget);
  });
}
