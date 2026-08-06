import 'package:flame/components.dart';
import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NTI idle animation changes its scale over time', () {
    final nti = Nti();

    nti.update(0.5);

    expect(nti.scale.x, greaterThan(1));
    expect(nti.scale.y, greaterThan(1));
  });

  test('NTI reaction starts and finishes cleanly', () {
    final nti = Nti();

    nti.react();
    expect(nti.isReacting, isTrue);

    nti.update(0.28);
    expect(nti.scale.y, closeTo(nti.scale.x, 0.0001));

    nti.update(1);
    expect(nti.isReacting, isFalse);
  });

  test('NTI scales down for compact game viewports', () {
    final nti = Nti();

    nti.onGameResize(Vector2(320, 568));
    nti.update(0);

    expect(nti.scale.x, closeTo(0.72, 0.001));
    expect(nti.position.x, closeTo(160, 0.001));
  });
}
