class PetSkin {
  const PetSkin({
    required this.id,
    required this.displayName,
    required this.previewColorValue,
    required this.spriteSheetAsset,
    required this.spriteRow,
  });

  final String id;
  final String displayName;
  final int previewColorValue;
  final String spriteSheetAsset;
  final int spriteRow;

  static const double frameWidth = 80;
  static const double frameHeight = 72;
}
