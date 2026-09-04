import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/presentation/store_coin_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coin balance uses generated frame and coin assets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: StoreCoinBalance(coins: 200))),
    );

    expect(find.text('200'), findsOneWidget);
    final semanticsWidget = tester.widget<Semantics>(
      find.byKey(const ValueKey('coin_balance_semantics')),
    );
    expect(semanticsWidget.properties.label, '200 monedas');

    final frame = tester.widget<Image>(
      find.byKey(const ValueKey('coin_balance_frame_asset')),
    );
    final coin = tester.widget<Image>(
      find.byKey(const ValueKey('coin_star_asset')),
    );

    expect(
      (frame.image as AssetImage).assetName,
      'assets/images/ui/coin_balance_frame_v1.png',
    );
    expect(
      (coin.image as AssetImage).assetName,
      'assets/images/ui/coin_star_v1.png',
    );
  });
}
