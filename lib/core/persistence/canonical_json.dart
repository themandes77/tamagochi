import 'dart:convert';

class CanonicalJson {
  const CanonicalJson._();

  static String encode(Object? value) {
    return jsonEncode(_normalize(value));
  }

  static Object? _normalize(Object? value) {
    if (value == null || value is bool || value is String) {
      return value;
    }

    if (value is num) {
      if (value is double && !value.isFinite) {
        throw const FormatException(
          'El JSON canónico no admite números no finitos.',
        );
      }
      return value;
    }

    if (value is List) {
      return value.map<Object?>(_normalize).toList(growable: false);
    }

    if (value is Map) {
      final keys = value.keys.map((key) {
        if (key is! String) {
          throw const FormatException(
            'El JSON canónico solo admite claves String.',
          );
        }
        return key;
      }).toList()
        ..sort();

      return <String, Object?>{
        for (final key in keys) key: _normalize(value[key]),
      };
    }

    throw FormatException(
      'Tipo no compatible con JSON canónico: ${value.runtimeType}.',
    );
  }
}

Map<String, Object?> requireStringObjectMap(
  Object? value, {
  String description = 'valor',
}) {
  if (value is! Map) {
    throw FormatException('$description debe ser un objeto JSON.');
  }

  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is! String) {
      throw FormatException('$description contiene una clave no textual.');
    }
    result[key] = entry.value;
  }
  return result;
}


Map<String, Object?> deepCopyStringObjectMap(Map<String, Object?> value) {
  return requireStringObjectMap(
    jsonDecode(CanonicalJson.encode(value)),
    description: 'copia JSON',
  );
}
