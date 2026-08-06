import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_1/core/persistence/canonical_json.dart';
import 'package:flutter_application_1/core/persistence/checksum_service.dart';
import 'package:flutter_application_1/core/persistence/json_storage_policy.dart';
import 'package:flutter_application_1/core/persistence/storage_directory_provider.dart';
import 'package:flutter_application_1/core/persistence/storage_incident.dart';
import 'package:flutter_application_1/core/persistence/storage_migration.dart';
import 'package:flutter_application_1/core/time/app_clock.dart';

enum JsonStorageReadStatus {
  missing,
  current,
  migrated,
  temporaryRecovered,
  backupRecovered,
  partiallyRecovered,
  resetRequired,
}

class JsonStorageReadResult {
  const JsonStorageReadResult({
    required this.status,
    this.payload,
  });

  final JsonStorageReadStatus status;
  final JsonPayload? payload;

  bool get hasPayload => payload != null;
}

class JsonFileStorage {
  JsonFileStorage({
    required this.fileName,
    required this.policy,
    required this.directoryProvider,
    required this.checksumService,
    required this.clock,
    this.incidentReporter = const DeveloperStorageIncidentReporter(),
  }) {
    _validateFileName(fileName);
  }

  final String fileName;
  final JsonStoragePolicy policy;
  final StorageDirectoryProvider directoryProvider;
  final ChecksumService checksumService;
  final AppClock clock;
  final StorageIncidentReporter incidentReporter;

  Future<void> _operationTail = Future<void>.value();

  Future<JsonStorageReadResult> read() {
    return _enqueue<JsonStorageReadResult>(_readInternal);
  }

  Future<void> write(JsonPayload payload) {
    final snapshot = deepCopyStringObjectMap(payload);
    return _enqueue<void>(() async {
      policy.validatePayload(snapshot);
      await _writeInternal(snapshot);
    });
  }

  Future<void> deleteAll() {
    return _enqueue<void>(() async {
      final paths = await _paths();
      for (final file in <File>[
        paths.current,
        paths.temporary,
        paths.backup,
        paths.currentCorrupt,
        paths.backupCorrupt,
        paths.temporaryCorrupt,
      ]) {
        if (await file.exists()) {
          await file.delete();
        }
      }
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _operationTail = _operationTail.then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<JsonStorageReadResult> _readInternal() async {
    final paths = await _paths();
    final current = await _inspect(
      paths.current,
      JsonRecoverySource.current,
    );

    if (current.isValid) {
      await _deleteIfExists(paths.temporary);
      if (current.wasMigrated) {
        await _writeInternal(current.payload!);
        return JsonStorageReadResult(
          status: JsonStorageReadStatus.migrated,
          payload: current.payload,
        );
      }
      return JsonStorageReadResult(
        status: JsonStorageReadStatus.current,
        payload: current.payload,
      );
    }

    final temporary = await _inspect(
      paths.temporary,
      JsonRecoverySource.temporary,
    );
    final backup = await _inspect(
      paths.backup,
      JsonRecoverySource.backup,
    );

    if (current.exists) {
      await _archiveCorrupt(paths.current, paths.currentCorrupt);
      _report(
        code: 'current_file_invalid',
        details: <String, Object?>{'failure': current.failureCode},
      );
    }

    if (temporary.isValid) {
      await _writeInternal(temporary.payload!);
      await _deleteIfExists(paths.temporary);
      _report(
        code: 'interrupted_write_recovered',
        details: const <String, Object?>{'source': 'temporary'},
      );
      return JsonStorageReadResult(
        status: JsonStorageReadStatus.temporaryRecovered,
        payload: temporary.payload,
      );
    }

    if (temporary.exists) {
      await _archiveCorrupt(paths.temporary, paths.temporaryCorrupt);
    }

    if (backup.isValid) {
      await _writeInternal(backup.payload!);
      _report(
        code: 'backup_recovered',
        details: const <String, Object?>{'source': 'backup'},
      );
      return JsonStorageReadResult(
        status: JsonStorageReadStatus.backupRecovered,
        payload: backup.payload,
      );
    }

    if (backup.exists) {
      await _archiveCorrupt(paths.backup, paths.backupCorrupt);
      _report(
        code: 'backup_file_invalid',
        details: <String, Object?>{'failure': backup.failureCode},
      );
    }

    if (!current.exists && !temporary.exists && !backup.exists) {
      return const JsonStorageReadResult(
        status: JsonStorageReadStatus.missing,
      );
    }

    final recovered = policy.recoverPartial(
      candidates: <JsonRecoveryCandidate>[
        if (current.exists) current.toRecoveryCandidate(),
        if (backup.exists) backup.toRecoveryCandidate(),
        if (temporary.exists) temporary.toRecoveryCandidate(),
      ],
      nowUtc: clock.nowUtc(),
    );

    if (recovered != null) {
      policy.validatePayload(recovered);
      await _writeInternal(recovered);
      _report(
        code: 'partial_recovery_succeeded',
        details: const <String, Object?>{},
      );
      return JsonStorageReadResult(
        status: JsonStorageReadStatus.partiallyRecovered,
        payload: recovered,
      );
    }

    _report(
      code: 'recovery_failed',
      details: const <String, Object?>{},
    );
    return const JsonStorageReadResult(
      status: JsonStorageReadStatus.resetRequired,
    );
  }

  Future<void> _writeInternal(JsonPayload payload) async {
    policy.validatePayload(payload);
    final paths = await _paths();
    final writtenAt = clock.nowUtc();
    final document = _buildDocument(payload: payload, writtenAt: writtenAt);

    await _deleteIfExists(paths.temporary);
    await paths.temporary.writeAsString(
      jsonEncode(document),
      flush: true,
    );

    final temporaryCheck = await _inspect(
      paths.temporary,
      JsonRecoverySource.temporary,
    );
    if (!temporaryCheck.isValid) {
      await _archiveCorrupt(paths.temporary, paths.temporaryCorrupt);
      throw FileSystemException(
        'El archivo temporal no superó la validación.',
        paths.temporary.path,
      );
    }

    final currentCheck = await _inspect(
      paths.current,
      JsonRecoverySource.current,
    );

    if (currentCheck.exists && currentCheck.isValid) {
      await _deleteIfExists(paths.backup);
      await paths.current.rename(paths.backup.path);
    } else if (currentCheck.exists) {
      await _archiveCorrupt(paths.current, paths.currentCorrupt);
    }

    try {
      await paths.temporary.rename(paths.current.path);
    } catch (_) {
      if (!await paths.current.exists() && await paths.backup.exists()) {
        await paths.backup.copy(paths.current.path);
      }
      rethrow;
    }

    final finalCheck = await _inspect(
      paths.current,
      JsonRecoverySource.current,
    );
    if (!finalCheck.isValid) {
      await _archiveCorrupt(paths.current, paths.currentCorrupt);
      if (await paths.backup.exists()) {
        await paths.backup.copy(paths.current.path);
      }
      throw FileSystemException(
        'El archivo vigente no superó la validación posterior.',
        paths.current.path,
      );
    }
  }

  Map<String, Object?> _buildDocument({
    required JsonPayload payload,
    required DateTime writtenAt,
  }) {
    final protectedContent = <String, Object?>{
      'schemaVersion': policy.currentSchemaVersion,
      'writtenAt': writtenAt.toUtc().toIso8601String(),
      'payload': payload,
    };

    return <String, Object?>{
      ...protectedContent,
      'integrity': <String, Object?>{
        'algorithm': 'sha256',
        'checksum': checksumService.checksumCanonical(protectedContent),
      },
    };
  }

  Future<_InspectedDocument> _inspect(
    File file,
    JsonRecoverySource source,
  ) async {
    if (!await file.exists()) {
      return _InspectedDocument.missing(source);
    }

    String rawText;
    try {
      rawText = await file.readAsString();
    } catch (_) {
      return _InspectedDocument.invalid(
        source: source,
        rawText: '',
        failureCode: 'read_failed',
      );
    }

    JsonPayload? root;
    JsonPayload? payload;
    int? schemaVersion;

    try {
      root = requireStringObjectMap(
        jsonDecode(rawText),
        description: 'El documento persistente',
      );
      schemaVersion = _readInt(root, 'schemaVersion');
      final writtenAtValue = root['writtenAt'];
      if (writtenAtValue is! String ||
          DateTime.tryParse(writtenAtValue) == null) {
        throw const FormatException('writtenAt no es una fecha válida.');
      }

      payload = requireStringObjectMap(
        root['payload'],
        description: 'payload',
      );
      final integrity = requireStringObjectMap(
        root['integrity'],
        description: 'integrity',
      );
      if (integrity['algorithm'] != 'sha256') {
        throw const FormatException('Algoritmo de integridad desconocido.');
      }
      final storedChecksum = integrity['checksum'];
      if (storedChecksum is! String || storedChecksum.isEmpty) {
        throw const FormatException('Checksum ausente.');
      }

      final protectedContent = <String, Object?>{
        'schemaVersion': schemaVersion,
        'writtenAt': writtenAtValue,
        'payload': payload,
      };
      final calculated = checksumService.checksumCanonical(protectedContent);
      if (calculated != storedChecksum) {
        return _InspectedDocument.invalid(
          source: source,
          rawText: rawText,
          payload: payload,
          schemaVersion: schemaVersion,
          failureCode: 'checksum_mismatch',
        );
      }

      var normalizedPayload = payload;
      var wasMigrated = false;
      if (schemaVersion != policy.currentSchemaVersion) {
        normalizedPayload = policy.migrate(
          fromVersion: schemaVersion,
          payload: payload,
        );
        wasMigrated = true;
      }

      policy.validatePayload(normalizedPayload);
      return _InspectedDocument.valid(
        source: source,
        rawText: rawText,
        payload: normalizedPayload,
        schemaVersion: policy.currentSchemaVersion,
        wasMigrated: wasMigrated,
      );
    } catch (error) {
      return _InspectedDocument.invalid(
        source: source,
        rawText: rawText,
        payload: payload,
        schemaVersion: schemaVersion,
        failureCode: error.runtimeType.toString(),
      );
    }
  }

  Future<_StoragePaths> _paths() async {
    final directory = await directoryProvider.getDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    final separator = Platform.pathSeparator;
    final currentPath = '${directory.path}$separator$fileName';
    final stem = fileName.toLowerCase().endsWith('.json')
        ? fileName.substring(0, fileName.length - 5)
        : fileName;

    return _StoragePaths(
      current: File(currentPath),
      temporary: File('${directory.path}$separator$stem.tmp'),
      backup: File('${directory.path}$separator$stem.bak'),
      currentCorrupt: File(
        '${directory.path}$separator$stem.corrupt.current.json',
      ),
      backupCorrupt: File(
        '${directory.path}$separator$stem.corrupt.backup.json',
      ),
      temporaryCorrupt: File(
        '${directory.path}$separator$stem.corrupt.temporary.json',
      ),
    );
  }

  Future<void> _archiveCorrupt(File source, File destination) async {
    if (!await source.exists()) {
      return;
    }
    await _deleteIfExists(destination);
    await source.rename(destination.path);
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _report({
    required String code,
    required Map<String, Object?> details,
  }) {
    incidentReporter.report(
      StorageIncident(
        code: code,
        moduleKey: policy.moduleKey,
        fileName: fileName,
        occurredAt: clock.nowUtc(),
        details: details,
      ),
    );
  }

  static int _readInt(JsonPayload json, String key) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('$key debe ser un entero.');
  }

  static void _validateFileName(String value) {
    if (value.trim().isEmpty ||
        value.contains('/') ||
        value.contains('\\') ||
        value == '.' ||
        value == '..') {
      throw ArgumentError.value(
        value,
        'fileName',
        'El nombre debe representar un archivo simple.',
      );
    }
  }
}

class _StoragePaths {
  const _StoragePaths({
    required this.current,
    required this.temporary,
    required this.backup,
    required this.currentCorrupt,
    required this.backupCorrupt,
    required this.temporaryCorrupt,
  });

  final File current;
  final File temporary;
  final File backup;
  final File currentCorrupt;
  final File backupCorrupt;
  final File temporaryCorrupt;
}

class _InspectedDocument {
  const _InspectedDocument._({
    required this.source,
    required this.exists,
    required this.isValid,
    required this.rawText,
    this.payload,
    this.schemaVersion,
    this.wasMigrated = false,
    this.failureCode,
  });

  factory _InspectedDocument.missing(JsonRecoverySource source) {
    return _InspectedDocument._(
      source: source,
      exists: false,
      isValid: false,
      rawText: '',
      failureCode: 'missing',
    );
  }

  factory _InspectedDocument.valid({
    required JsonRecoverySource source,
    required String rawText,
    required JsonPayload payload,
    required int schemaVersion,
    required bool wasMigrated,
  }) {
    return _InspectedDocument._(
      source: source,
      exists: true,
      isValid: true,
      rawText: rawText,
      payload: payload,
      schemaVersion: schemaVersion,
      wasMigrated: wasMigrated,
    );
  }

  factory _InspectedDocument.invalid({
    required JsonRecoverySource source,
    required String rawText,
    required String failureCode,
    JsonPayload? payload,
    int? schemaVersion,
  }) {
    return _InspectedDocument._(
      source: source,
      exists: true,
      isValid: false,
      rawText: rawText,
      payload: payload,
      schemaVersion: schemaVersion,
      failureCode: failureCode,
    );
  }

  final JsonRecoverySource source;
  final bool exists;
  final bool isValid;
  final String rawText;
  final JsonPayload? payload;
  final int? schemaVersion;
  final bool wasMigrated;
  final String? failureCode;

  JsonRecoveryCandidate toRecoveryCandidate() {
    return JsonRecoveryCandidate(
      source: source,
      rawText: rawText,
      payload: payload,
      schemaVersion: schemaVersion,
      failureCode: failureCode,
    );
  }
}
