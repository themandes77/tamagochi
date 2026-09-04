import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_back_button.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('store back button invokes its callback', (tester) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: StoreBackButton(
            tooltip: 'Cerrar tienda',
            onPressed: () => taps++,
          ),
        ),
      ),
    );

    expect(find.byType(StoreBackButton), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.byType(StoreBackButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
