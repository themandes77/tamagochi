abstract interface class TransactionParticipant {
  String get participantKey;

  Future<Map<String, Object?>> readPayload();

  Future<void> writePayload(Map<String, Object?> payload);

  void validatePayload(Map<String, Object?> payload);
}
