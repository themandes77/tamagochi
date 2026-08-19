import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract interface class StorageDirectoryProvider {
  Future<Directory> getDirectory();
}

class ApplicationSupportDirectoryProvider implements StorageDirectoryProvider {
  const ApplicationSupportDirectoryProvider();

  @override
  Future<Directory> getDirectory() {
    return getApplicationSupportDirectory();
  }
}

class FixedStorageDirectoryProvider implements StorageDirectoryProvider {
  const FixedStorageDirectoryProvider(this.directory);

  final Directory directory;

  @override
  Future<Directory> getDirectory() async => directory;
}
