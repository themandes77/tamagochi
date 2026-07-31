import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_application_1/features/store/presentation/store_access_button.dart';
import 'package:flutter_application_1/gui.dart';
import 'package:flutter_application_1/nti_tamagochi.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NtiTamagochi creates the shared game components', () {
    final game = NtiTamagochi();

    expect(game.nti, isA<Nti>());
    expect(game.toolBar, isA<ToolBar>());
    expect(game.storeAccessButton, isA<StoreAccessButton>());
  });
}
