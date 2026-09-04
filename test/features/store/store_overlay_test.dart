import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_overlay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('store overlay can be closed', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();
    var wasClosed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: StoreOverlay(
          controller: controller,
          onClose: () => wasClosed = true,
        ),
      ),
    );

    final closeButton = find.byKey(const ValueKey('store_close_button'));
    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    expect(wasClosed, isTrue);
  });
}
