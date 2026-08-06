import 'dart:convert';
import 'dart:developer' as developer;

class StorageIncident {
  const StorageIncident({
    required this.code,
    required this.moduleKey,
    required this.fileName,
    required this.occurredAt,
    this.details = const <String, Object?>{},
  });

  final String code;
  final String moduleKey;
  final String fileName;
  final DateTime occurredAt;
  final Map<String, Object?> details;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'code': code,
      'moduleKey': moduleKey,
      'fileName': fileName,
      'occurredAt': occurredAt.toUtc().toIso8601String(),
      'details': details,
    };
  }
}

abstract interface class StorageIncidentReporter {
  void report(StorageIncident incident);
}

class DeveloperStorageIncidentReporter implements StorageIncidentReporter {
  const DeveloperStorageIncidentReporter();

  @override
  void report(StorageIncident incident) {
    developer.log(
      jsonEncode(incident.toJson()),
      name: 'nt_tamagochi.storage',
    );
  }
}

class NoOpStorageIncidentReporter implements StorageIncidentReporter {
  const NoOpStorageIncidentReporter();

  @override
  void report(StorageIncident incident) {}
}
