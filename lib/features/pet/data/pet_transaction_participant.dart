import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetTransactionParticipant implements TransactionParticipant {
  PetTransactionParticipant({
    required this.controller,
    required this.repository,
    this.rules = const PetRules(),
  });

  final PetController controller;
  final PetRepository repository;
  final PetRules rules;

  @override
  String get participantKey => 'pet';

  @override
  Future<Map<String, Object?>> readPayload() async {
    return controller.state.toJson();
  }

  @override
  Future<void> writePayload(Map<String, Object?> payload) async {
    final state = PetState.fromJson(payload, rules: rules);
    if (state != controller.state) {
      controller.replaceState(state);
    }
    await repository.save(controller.state);
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    PetState.fromJson(payload, rules: rules);
  }
}
