import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders store balance and catalog', (tester) async {
    final controller = StoreController(repository: InMemoryStoreRepository());
    await controller.initialize();

    await tester.pumpWidget(StorePreviewApp(controller: controller));

    expect(find.text('Personalización'), findsOneWidget);
    expect(find.text('200 monedas'), findsOneWidget);
    expect(find.text('Slime azul'), findsOneWidget);
    expect(find.text('Tema original'), findsOneWidget);
  });
}
