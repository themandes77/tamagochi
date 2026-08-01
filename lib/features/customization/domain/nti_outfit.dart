enum NtiOutfit {
  original(
    id: 'original',
    displayName: 'Original',
    assetPath: 'outfits/nti_original_round.png',
    eyeCenterY: 0.43,
    mouthCenterY: 0.50,
  ),
  anniversary(
    id: 'anniversary',
    displayName: 'Aniversario',
    assetPath: 'outfits/nti_anniversary_round.png',
    eyeCenterY: 0.36,
    mouthCenterY: 0.44,
  ),
  techno(
    id: 'techno',
    displayName: 'Techno',
    assetPath: 'outfits/nti_techno_round.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.52,
  ),
  adventurer(
    id: 'adventurer',
    displayName: 'Aventurero',
    assetPath: 'outfits/nti_adventurer_round.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.50,
  );

  const NtiOutfit({
    required this.id,
    required this.displayName,
    required this.assetPath,
    required this.eyeCenterY,
    required this.mouthCenterY,
  });

  final String id;
  final String displayName;
  final String assetPath;
  final double eyeCenterY;
  final double mouthCenterY;

  String get flutterAssetPath => 'assets/images/$assetPath';
}
