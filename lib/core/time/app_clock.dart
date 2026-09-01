abstract interface class AppClock {
  DateTime nowUtc();
}

class SystemUtcClock implements AppClock {
  const SystemUtcClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
