import 'package:flutter_application_1/features/store/domain/store_repository.dart';
import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

class InMemoryStoreRepository implements StoreRepository {
  InMemoryStoreRepository({StoreSnapshot? initialSnapshot})
    : _snapshot = initialSnapshot;

  StoreSnapshot? _snapshot;

  @override
  Future<StoreSnapshot?> load() async {
    final snapshot = _snapshot;
    return snapshot == null ? null : StoreSnapshot.fromJson(snapshot.toJson());
  }

  @override
  Future<void> save(StoreSnapshot snapshot) async {
    _snapshot = StoreSnapshot.fromJson(snapshot.toJson());
  }
}
