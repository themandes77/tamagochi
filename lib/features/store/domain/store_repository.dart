import 'package:flutter_application_1/features/store/domain/store_snapshot.dart';

abstract interface class StoreRepository {
  Future<StoreSnapshot?> load();

  Future<void> save(StoreSnapshot snapshot);
}
