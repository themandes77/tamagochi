class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.displayName,
    required this.backgroundAssetPath,
    required this.backgroundColorValue,
    required this.surfaceColorValue,
    required this.accentColorValue,
  });

  final String id;
  final String displayName;
  final String? backgroundAssetPath;
  final int backgroundColorValue;
  final int surfaceColorValue;
  final int accentColorValue;
}
