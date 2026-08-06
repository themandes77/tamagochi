import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/store/application/store_controller.dart';
import 'package:flutter_application_1/features/store/data/in_memory_store_repository.dart';
import 'package:flutter_application_1/features/store/presentation/store_preview_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = StoreController(repository: InMemoryStoreRepository());
  await controller.initialize();

  runApp(StorePreviewApp(controller: controller));
}
