class ThemeOption {
  const ThemeOption({
    required this.id,
    required this.displayName,
    required this.backgroundColorValue,
    required this.surfaceColorValue,
    required this.accentColorValue,
  });

  final String id;
  final String displayName;
  final int backgroundColorValue;
  final int surfaceColorValue;
  final int accentColorValue;
}
