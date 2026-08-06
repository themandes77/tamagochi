class AppPreferences {
  const AppPreferences({
    required this.musicVolume,
    required this.effectsVolume,
    required this.vibrationEnabled,
  });

  static const AppPreferences initial = AppPreferences(
    musicVolume: 1.0,
    effectsVolume: 1.0,
    vibrationEnabled: true,
  );

  final double musicVolume;
  final double effectsVolume;
  final bool vibrationEnabled;

  AppPreferences copyWith({
    double? musicVolume,
    double? effectsVolume,
    bool? vibrationEnabled,
  }) {
    return AppPreferences(
      musicVolume: musicVolume ?? this.musicVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'musicVolume': musicVolume,
      'effectsVolume': effectsVolume,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory AppPreferences.fromJson(Map<String, Object?> json) {
    final musicVolume = json['musicVolume'];
    final effectsVolume = json['effectsVolume'];
    final vibrationEnabled = json['vibrationEnabled'];

    if (musicVolume is! num || effectsVolume is! num) {
      throw const FormatException(
        'Los volúmenes deben ser valores numéricos.',
      );
    }
    if (vibrationEnabled is! bool) {
      throw const FormatException(
        'vibrationEnabled debe ser un valor booleano.',
      );
    }

    return AppPreferences(
      musicVolume: musicVolume.toDouble(),
      effectsVolume: effectsVolume.toDouble(),
      vibrationEnabled: vibrationEnabled,
    );
  }
}
