import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';

void main() {
  test('NtiTamagochi can be created as a Flame game', () {
    expect(NtiTamagochi(), isA<FlameGame>());
  });
}
