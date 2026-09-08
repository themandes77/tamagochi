import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';
import 'package:flutter_application_1/features/pet/presentation/nti_care_visual_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PetState state({
    double hunger = 10,
    double cleanliness = 10,
    double energy = 10,
    double fun = 10,
  }) {
    return PetState(
      hunger: hunger,
      cleanliness: cleanliness,
      energy: energy,
      fun: fun,
      lastSavedAt: DateTime.utc(2026, 8, 17),
    );
  }

  test('necesidades normales no alteran la presentación', () {
    final visual = NtiCareVisualResolver.resolve(
      state: state(),
      activity: PetActivity.idle,
    );

    expect(visual.hungerIntensity, 0);
    expect(visual.cleanlinessIntensity, 0);
    expect(visual.energyIntensity, 0);
    expect(visual.funIntensity, 0);
    expect(visual.criticalNeedCount, 0);
    expect(visual.isMultiCritical, isFalse);
  });

  test('la intensidad crece de forma continua entre 3 y 0', () {
    expect(NtiCareVisualResolver.intensityFor(3), 0);
    expect(NtiCareVisualResolver.intensityFor(2.5), closeTo(1 / 6, 0.0001));
    expect(NtiCareVisualResolver.intensityFor(1.5), closeTo(0.5, 0.0001));
    expect(NtiCareVisualResolver.intensityFor(0), 1);
  });

  test('las necesidades compatibles conservan sus canales simultáneos', () {
    final visual = NtiCareVisualResolver.resolve(
      state: state(
        hunger: 2.4,
        cleanliness: 2.1,
        energy: 1.8,
        fun: 2.7,
      ),
      activity: PetActivity.idle,
    );

    expect(visual.hungerIntensity, greaterThan(0));
    expect(visual.cleanlinessIntensity, greaterThan(0));
    expect(visual.energyIntensity, greaterThan(0));
    expect(visual.funIntensity, greaterThan(0));
    expect(visual.isMultiCritical, isFalse);
  });

  test('dos o más necesidades <= 1 activan multicrítico', () {
    final visual = NtiCareVisualResolver.resolve(
      state: state(hunger: 1, cleanliness: 0.7, energy: 2.4, fun: 8),
      activity: PetActivity.idle,
    );

    expect(visual.criticalNeedCount, 2);
    expect(visual.isMultiCritical, isTrue);
    expect(visual.distressIntensity, inInclusiveRange(0.62, 1.0));
  });

  test('la acción activa se transporta sin modificar necesidades', () {
    final visual = NtiCareVisualResolver.resolve(
      state: state(energy: 0.5),
      activity: PetActivity.sleeping,
    );

    expect(visual.isSleeping, isTrue);
    expect(visual.energyIntensity, greaterThan(0));
  });
}
