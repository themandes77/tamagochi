enum NotificationPromptDecision { notAsked, declined, accepted }

class AppPreferences {
  const AppPreferences({
    required this.musicVolume,
    required this.effectsVolume,
    required this.vibrationEnabled,
    this.notificationPromptDecision = NotificationPromptDecision.notAsked,
    this.notificationLastVariants = const <String, String>{},
  });

  static const AppPreferences initial = AppPreferences(
    musicVolume: 1.0,
    effectsVolume: 1.0,
    vibrationEnabled: true,
  );

  final double musicVolume;
  final double effectsVolume;
  final bool vibrationEnabled;
  final NotificationPromptDecision notificationPromptDecision;
  final Map<String, String> notificationLastVariants;

  AppPreferences copyWith({
    double? musicVolume,
    double? effectsVolume,
    bool? vibrationEnabled,
    NotificationPromptDecision? notificationPromptDecision,
    Map<String, String>? notificationLastVariants,
  }) {
    return AppPreferences(
      musicVolume: musicVolume ?? this.musicVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationPromptDecision:
          notificationPromptDecision ?? this.notificationPromptDecision,
      notificationLastVariants:
          notificationLastVariants ?? this.notificationLastVariants,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'musicVolume': musicVolume,
      'effectsVolume': effectsVolume,
      'vibrationEnabled': vibrationEnabled,
      'notificationPromptDecision': notificationPromptDecision.name,
      'notificationLastVariants': notificationLastVariants,
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

    final promptDecision = _readPromptDecision(
      json['notificationPromptDecision'],
    );
    final lastVariants = _readLastVariants(json['notificationLastVariants']);

    return AppPreferences(
      musicVolume: musicVolume.toDouble(),
      effectsVolume: effectsVolume.toDouble(),
      vibrationEnabled: vibrationEnabled,
      notificationPromptDecision: promptDecision,
      notificationLastVariants: lastVariants,
    );
  }

  static NotificationPromptDecision _readPromptDecision(Object? value) {
    if (value == null) {
      return NotificationPromptDecision.notAsked;
    }
    if (value is! String) {
      throw const FormatException(
        'notificationPromptDecision debe ser un String.',
      );
    }
    return NotificationPromptDecision.values.firstWhere(
      (item) => item.name == value,
      orElse: () => throw FormatException(
        'notificationPromptDecision no reconocido: $value',
      ),
    );
  }

  static Map<String, String> _readLastVariants(Object? value) {
    if (value == null) {
      return const <String, String>{};
    }
    if (value is! Map) {
      throw const FormatException(
        'notificationLastVariants debe ser un objeto JSON.',
      );
    }

    final result = <String, String>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final variant = entry.value;
      if (key is! String || variant is! String || (variant != 'a' && variant != 'b')) {
        throw const FormatException(
          'notificationLastVariants contiene un valor inválido.',
        );
      }
      result[key] = variant;
    }
    return result;
  }
}
