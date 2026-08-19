import 'package:flutter_application_1/core/persistence/journal/transaction_participant.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/domain/store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class StoreTransactionParticipant implements WriteAheadTransactionParticipant {
  StoreTransactionParticipant({
    required this.controller,
    required this.repository,
  });

  final StoreController controller;
  final StoreRepository repository;

  @override
  String get participantKey => 'store';

  @override
  Future<Map<String, Object?>> readPayload() async {
    return _snapshotFromController().toJson();
  }

  @override
  Future<void> writePayload(Map<String, Object?> payload) async {
    final snapshot = StoreSnapshot.fromJson(payload);
    await repository.save(snapshot);
    await controller.initialize();
  }

  @override
  Future<void> applyRuntimePayload(Map<String, Object?> payload) async {
    controller.applyTransactionSnapshot(StoreSnapshot.fromJson(payload));
  }

  @override
  Future<void> persistPayload(Map<String, Object?> payload) async {
    await repository.save(StoreSnapshot.fromJson(payload));
  }

  @override
  void validatePayload(Map<String, Object?> payload) {
    StoreSnapshot.fromJson(payload);
  }

  StoreSnapshot _snapshotFromController() {
    return StoreSnapshot(
      coins: controller.coins,
      ownedItemIds: controller.ownedItemIds.toSet(),
      equippedOutfitId: controller.equippedOutfitId,
      equippedThemeId: controller.equippedThemeId,
      foodInventory: controller.foodInventory,
    );
  }
}
