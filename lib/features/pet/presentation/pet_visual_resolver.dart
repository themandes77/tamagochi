import 'package:flutter_application_1/features/pet/domain/pet_activity.dart';

class PetHitboxProfile {
  const PetHitboxProfile({
    this.leftInsetFraction = 0.12,
    this.topInsetFraction = 0.08,
    this.rightInsetFraction = 0.12,
    this.bottomInsetFraction = 0.06,
  }) : assert(leftInsetFraction >= 0.0 && leftInsetFraction < 0.5),
       assert(topInsetFraction >= 0.0 && topInsetFraction < 0.5),
       assert(rightInsetFraction >= 0.0 && rightInsetFraction < 0.5),
       assert(bottomInsetFraction >= 0.0 && bottomInsetFraction < 0.5),
       assert(leftInsetFraction + rightInsetFraction < 1.0),
       assert(topInsetFraction + bottomInsetFraction < 1.0);

  final double leftInsetFraction;
  final double topInsetFraction;
  final double rightInsetFraction;
  final double bottomInsetFraction;
}

class PetVisualDefinition {
  const PetVisualDefinition({
    required this.assetName,
    required this.aspectRatio,
    required this.hitbox,
  }) : assert(aspectRatio > 0.0);

  final String assetName;
  final double aspectRatio;
  final PetHitboxProfile hitbox;
}

class PetVisualResolver {
  const PetVisualResolver();

  static const PetVisualDefinition _currentNti = PetVisualDefinition(
    assetName: 'nti.png',
    aspectRatio: 224 / 280,
    hitbox: PetHitboxProfile(),
  );

  PetVisualDefinition resolve(PetActivity activity) {
    return switch (activity) {
      PetActivity.idle ||
      PetActivity.eating ||
      PetActivity.cleaning ||
      PetActivity.sleeping ||
      PetActivity.playing => _currentNti,
    };
  }
}
