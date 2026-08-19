typedef JsonPayload = Map<String, Object?>;
typedef JsonMigrationStep = JsonPayload Function(JsonPayload payload);

class UnsupportedSchemaVersionException implements Exception {
  const UnsupportedSchemaVersionException({
    required this.foundVersion,
    required this.currentVersion,
  });

  final int foundVersion;
  final int currentVersion;

  @override
  String toString() {
    return 'No existe una migración desde el esquema $foundVersion '
        'hacia el esquema $currentVersion.';
  }
}

class JsonMigrationRegistry {
  JsonMigrationRegistry({
    required this.currentVersion,
    Map<int, JsonMigrationStep> steps = const {},
  }) : _steps = Map<int, JsonMigrationStep>.unmodifiable(steps) {
    if (currentVersion < 1) {
      throw ArgumentError.value(
        currentVersion,
        'currentVersion',
        'La versión actual debe ser mayor o igual que uno.',
      );
    }
  }

  final int currentVersion;
  final Map<int, JsonMigrationStep> _steps;

  JsonPayload migrate({
    required int fromVersion,
    required JsonPayload payload,
  }) {
    if (fromVersion > currentVersion || fromVersion < 1) {
      throw UnsupportedSchemaVersionException(
        foundVersion: fromVersion,
        currentVersion: currentVersion,
      );
    }

    var version = fromVersion;
    var currentPayload = Map<String, Object?>.from(payload);

    while (version < currentVersion) {
      final step = _steps[version];
      if (step == null) {
        throw UnsupportedSchemaVersionException(
          foundVersion: version,
          currentVersion: currentVersion,
        );
      }
      currentPayload = step(Map<String, Object?>.from(currentPayload));
      version += 1;
    }

    return currentPayload;
  }
}
