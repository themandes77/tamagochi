import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders balance and the three store categories', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.pump();

    expect(find.text('500'), findsWidgets);
    expect(find.text('TRAJES'), findsOneWidget);
    expect(find.text('FONDOS'), findsOneWidget);
    expect(find.text('COMIDA'), findsOneWidget);
  });

  testWidgets('food category buys repeatable food units', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));
    await tester.pump();

    await tester.tap(find.text('COMIDA'));
    await tester.pump();

    expect(find.text('Comida 1'), findsWidgets);
    expect(find.text('Comida 2'), findsWidgets);
    expect(find.text('Comida 3'), findsWidgets);
  });
}
