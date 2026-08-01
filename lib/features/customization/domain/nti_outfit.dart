enum NtiOutfit {
  original(
    id: 'original',
    displayName: 'Original',
    eyeCenterY: 0.43,
    mouthCenterY: 0.50,
  ),
  anniversary(
    id: 'anniversary',
    displayName: 'Aniversario',
    overlayAssetPath: 'outfits/nti_anniversary_overlay.png',
    eyeCenterY: 0.36,
    mouthCenterY: 0.44,
  ),
  techno(
    id: 'techno',
    displayName: 'Techno',
    overlayAssetPath: 'outfits/nti_techno_overlay.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.52,
  ),
  adventurer(
    id: 'adventurer',
    displayName: 'Aventurero',
    overlayAssetPath: 'outfits/nti_adventurer_overlay.png',
    eyeCenterY: 0.45,
    mouthCenterY: 0.50,
  );

  const NtiOutfit({
    required this.id,
    required this.displayName,
    this.overlayAssetPath,
    required this.eyeCenterY,
    required this.mouthCenterY,
  });

  static const bodyAssetPath = 'outfits/nti_body_master.png';

  final String id;
  final String displayName;
  final String? overlayAssetPath;
  final double eyeCenterY;
  final double mouthCenterY;

  static const flutterBodyAssetPath = 'assets/images/$bodyAssetPath';

  String? get flutterOverlayAssetPath {
    final path = overlayAssetPath;
    return path == null ? null : 'assets/images/$path';
  }
}
