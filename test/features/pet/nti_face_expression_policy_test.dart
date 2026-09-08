import 'package:flutter_application_1/actors/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('awake eye opening is controlled only by energy and bottoms at 82%', () {
    expect(NtiFace.awakeEyeOpenFractionFor(0), 1);
    expect(NtiFace.awakeEyeOpenFractionFor(0.5), closeTo(0.91, 0.0001));
    expect(
      NtiFace.awakeEyeOpenFractionFor(1),
      NtiFace.minimumAwakeEyeOpenFraction,
    );
  });

  test('cleaning reaction uses the approved soft duration', () {
    expect(Nti.cleanReactionDuration, 0.78);
  });
}
