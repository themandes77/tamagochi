class StorageNotice {
  const StorageNotice({
    required this.code,
    required this.message,
    required this.moduleKey,
  });

  final String code;
  final String message;
  final String moduleKey;
}

class StorageNoticeCenter {
  final List<StorageNotice> _pending = <StorageNotice>[];

  void publish(StorageNotice notice) {
    _pending.add(notice);
  }

  List<StorageNotice> drain() {
    final notices = List<StorageNotice>.unmodifiable(_pending);
    _pending.clear();
    return notices;
  }

  bool get hasPending => _pending.isNotEmpty;
}
