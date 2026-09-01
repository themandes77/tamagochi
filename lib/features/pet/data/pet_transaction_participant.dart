import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/features/pet/application/pet_controller.dart';
import 'package:flutter_application_1/features/pet/domain/pet_repository.dart';
import 'package:flutter_application_1/features/pet/domain/pet_rules.dart';
import 'package:flutter_application_1/features/pet/domain/pet_state.dart';

class PetTransactionParticipant implements WriteAheadTransactionParticipant {
  PetTransactionParticipant({
    required this.controller,
    required this.repository,
    this.rules = const PetRules(),
    this.onDurablePersisted,
  });

  final PetController controller;
  final PetRepository repository;
  final PetRules rules;
  final void Function(PetState state)? onDurablePersisted;

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
    await repository.save(state);
    onDurablePersisted?.call(state);
  }

  @override
  Future<void> applyRuntimePayload(Map<String, Object?> payload) async {
    final state = PetState.fromJson(payload, rules: rules);
    if (state != controller.state) {
      controller.replaceState(state);
    }
  }

  @override
  Future<void> persistPayload(Map<String, Object?> payload) async {
    final state = PetState.fromJson(payload, rules: rules);
    await repository.save(state);
    onDurablePersisted?.call(state);
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    PetState.fromJson(payload, rules: rules);
  }
}
