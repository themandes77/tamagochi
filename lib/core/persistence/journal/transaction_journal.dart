import 'package:flutter_application_1/core/persistence/canonical_json.dart';

enum JournalTransactionStatus { pending, completed, conflict }

enum JournalParticipantStatus { pending, applied, conflict }

class JournalParticipantRecord {
  const JournalParticipantRecord({
    required this.participantKey,
    required this.beforeChecksum,
    String? durableBeforeChecksum,
    required this.targetChecksum,
    required this.targetPayload,
    this.beforePayload,
    this.status = JournalParticipantStatus.pending,
    this.appliedAt,
  }) : durableBeforeChecksum = durableBeforeChecksum ?? beforeChecksum;

  factory JournalParticipantRecord.fromJson(Map<String, Object?> json) {
    final rawBeforePayload = json['beforePayload'];
    return JournalParticipantRecord(
      participantKey: _readString(json, 'participantKey'),
      beforeChecksum: _readString(json, 'beforeChecksum'),
      durableBeforeChecksum:
          _readOptionalString(json, 'durableBeforeChecksum') ??
          _readString(json, 'beforeChecksum'),
      targetChecksum: _readString(json, 'targetChecksum'),
      beforePayload: rawBeforePayload == null
          ? null
          : requireStringObjectMap(
              rawBeforePayload,
              description: 'beforePayload',
            ),
      targetPayload: requireStringObjectMap(
        json['targetPayload'],
        description: 'targetPayload',
      ),
      status: JournalParticipantStatus.values.byName(
        _readString(json, 'status'),
      ),
      appliedAt: _readOptionalDate(json, 'appliedAt'),
    );
  }

  final String participantKey;

  /// Payload anterior a la transacción.
  ///
  /// Es nullable únicamente para journals schema 1 migrados. Desde schema 2
  /// se guarda siempre y en schema 3 representa el estado lógico de rollback,
  /// que puede diferir de la última fotografía durable.
  final Map<String, Object?>? beforePayload;

  /// Checksum del estado lógico al que se vuelve si hace falta rollback.
  final String beforeChecksum;

  /// Checksum que se espera encontrar durable antes de materializar target.
  ///
  /// En schema 1/2 coincide con [beforeChecksum]. En schema 3 puede diferir:
  /// Pet puede haber avanzado lógicamente por decay sin checkpoint previo.
  final String durableBeforeChecksum;
  final String targetChecksum;
  final Map<String, Object?> targetPayload;
  final JournalParticipantStatus status;
  final DateTime? appliedAt;

  JournalParticipantRecord copyWith({
    Map<String, Object?>? beforePayload,
    bool replaceBeforePayload = false,
    JournalParticipantStatus? status,
    DateTime? appliedAt,
  }) {
    return JournalParticipantRecord(
      participantKey: participantKey,
      beforePayload: replaceBeforePayload
          ? beforePayload
          : this.beforePayload == null
          ? null
          : Map<String, Object?>.from(this.beforePayload!),
      beforeChecksum: beforeChecksum,
      durableBeforeChecksum: durableBeforeChecksum,
      targetChecksum: targetChecksum,
      targetPayload: Map<String, Object?>.from(targetPayload),
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'participantKey': participantKey,
      'beforePayload': beforePayload,
      'beforeChecksum': beforeChecksum,
      'durableBeforeChecksum': durableBeforeChecksum,
      'targetChecksum': targetChecksum,
      'targetPayload': targetPayload,
      'status': status.name,
      'appliedAt': appliedAt?.toUtc().toIso8601String(),
    };
  }
}

class JournalTransaction {
  const JournalTransaction({
    required this.transactionId,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.participants,
    this.status = JournalTransactionStatus.pending,
  });

  factory JournalTransaction.fromJson(Map<String, Object?> json) {
    final participantValues = json['participants'];
    if (participantValues is! List) {
      throw const FormatException('participants debe ser una lista.');
    }

    final participants = <String, JournalParticipantRecord>{};
    for (final value in participantValues) {
      final record = JournalParticipantRecord.fromJson(
        requireStringObjectMap(value, description: 'participant'),
      );
      if (participants.containsKey(record.participantKey)) {
        throw FormatException(
          'Participante duplicado: ${record.participantKey}.',
        );
      }
      participants[record.participantKey] = record;
    }
    if (participants.isEmpty) {
      throw const FormatException('La transacción no contiene participantes.');
    }

    return JournalTransaction(
      transactionId: _readString(json, 'transactionId'),
      type: _readString(json, 'type'),
      createdAt: _readDate(json, 'createdAt'),
      updatedAt: _readDate(json, 'updatedAt'),
      status: JournalTransactionStatus.values.byName(
        _readString(json, 'status'),
      ),
      participants: Map<String, JournalParticipantRecord>.unmodifiable(
        participants,
      ),
    );
  }

  final String transactionId;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final JournalTransactionStatus status;
  final Map<String, JournalParticipantRecord> participants;

  JournalTransaction copyWith({
    DateTime? updatedAt,
    JournalTransactionStatus? status,
    Map<String, JournalParticipantRecord>? participants,
  }) {
    return JournalTransaction(
      transactionId: transactionId,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      participants: Map<String, JournalParticipantRecord>.unmodifiable(
        participants ?? this.participants,
      ),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'transactionId': transactionId,
      'type': type,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'status': status.name,
      'participants': participants.values
          .map((record) => record.toJson())
          .toList(growable: false),
    };
  }
}

String _readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key debe ser un texto no vacío.');
  }
  return value;
}

String? _readOptionalString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String || value.isEmpty) {
    throw FormatException('$key debe ser un texto no vacío o null.');
  }
  return value;
}

DateTime _readDate(Map<String, Object?> json, String key) {
  final value = _readString(json, key);
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key no contiene una fecha válida.');
  }
  return parsed.toUtc();
}

DateTime? _readOptionalDate(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw FormatException('$key debe ser una fecha o null.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$key no contiene una fecha válida.');
  }
  return parsed.toUtc();
}
