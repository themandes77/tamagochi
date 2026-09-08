abstract interface class TransactionParticipant {
  String get participantKey;

  /// Estado lógico/runtime actual del participante.
  Future<Map<String, Object?>> readPayload();

  /// Ruta tradicional: aplica el payload y lo deja durable antes de terminar.
  Future<void> writePayload(Map<String, Object?> payload);

  void validatePayload(Map<String, Object?> payload);
}

/// Contrato adicional para transacciones write-ahead.
///
/// Permite separar el cambio runtime (rápido, después del commit del journal)
/// de su materialización durable (serializada en segundo plano). El journal es
/// la evidencia que permite terminar la operación si la app se interrumpe.
abstract interface class WriteAheadTransactionParticipant
    implements TransactionParticipant {
  Future<void> applyRuntimePayload(Map<String, Object?> payload);

  Future<void> persistPayload(Map<String, Object?> payload);
}
