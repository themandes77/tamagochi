enum NtiOutfit {
  original(
    id: 'original',
    displayName: 'Original',
    integratedAssetPath: 'outfits/nti_body_master.png',
    eyeCenterY: 0.43,
    mouthCenterY: 0.50,
  ),
  anniversary(
    id: 'anniversary',
    displayName: 'Aniversario',
    integratedAssetPath: 'outfits/nti_anniversary_integrated_v1.png',
    eyeCenterY: 0.36,
    mouthCenterY: 0.44,
  ),
  techno(
    id: 'techno',
    displayName: 'Techno',
    integratedAssetPath: 'outfits/nti_techno_integrated_v3.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.52,
  ),
  adventurer(
    id: 'adventurer',
    displayName: 'Aventurero',
    integratedAssetPath: 'outfits/nti_adventurer_integrated_v5.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.50,
  );

  const NtiOutfit({
    required this.id,
    required this.displayName,
    required this.integratedAssetPath,
    required this.eyeCenterY,
    required this.mouthCenterY,
  });

  static const bodyAssetPath = 'outfits/nti_body_master.png';

  final String id;
  final String displayName;
  final String integratedAssetPath;
  final double eyeCenterY;
  final double mouthCenterY;

  static const flutterBodyAssetPath = 'assets/images/$bodyAssetPath';

  String get artworkAssetPath => integratedAssetPath;

  String get flutterArtworkAssetPath => 'assets/images/$artworkAssetPath';
}
