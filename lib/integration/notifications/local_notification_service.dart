import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class ScheduledLocalNotification {
  const ScheduledLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAtLocal,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAtLocal;
  final String payload;
}

class LocalNotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'nti_care';
  static const String channelName = 'Cuidados de nti';
  static const String channelDescription =
      'Recordatorios suaves cuando nti necesita que vuelvas.';
  static const String androidSmallIcon = 'ic_stat_nti';
  static const String threadIdentifier = 'my_nti_care';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _timezoneReady = false;
  void Function()? _onNotificationTap;

  set onNotificationTap(void Function()? callback) {
    _onNotificationTap = callback;
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
      _timezoneReady = true;
    } catch (_) {
      // Es preferible no programar una hora incorrecta a reinterpretar la
      // hora local como UTC. El coordinator degrada este fallo en silencio.
      _timezoneReady = false;
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(androidSmallIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => _onNotificationTap?.call(),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.defaultImportance,
      ),
    );

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? true;
    }

    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: false,
            sound: true,
          ) ??
          false;
    }

    return false;
  }

  Future<bool> areNotificationsEnabled() async {
    await initialize();

    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.areNotificationsEnabled() ?? true;
    }

    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      return options?.isEnabled ?? false;
    }

    return false;
  }

  Future<void> clearAll() async {
    await initialize();
    await _plugin.cancelAll();
  }

  Future<void> scheduleAll(List<ScheduledLocalNotification> notifications) async {
    await initialize();
    if (!_timezoneReady) {
      throw StateError(
        'No fue posible resolver la zona horaria local para notificaciones.',
      );
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        icon: androidSmallIcon,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        groupKey: threadIdentifier,
      ),
      iOS: DarwinNotificationDetails(
        threadIdentifier: threadIdentifier,
      ),
    );

    for (final item in notifications) {
      final scheduled = tz.TZDateTime(
        tz.local,
        item.scheduledAtLocal.year,
        item.scheduledAtLocal.month,
        item.scheduledAtLocal.day,
        item.scheduledAtLocal.hour,
        item.scheduledAtLocal.minute,
        item.scheduledAtLocal.second,
        item.scheduledAtLocal.millisecond,
        item.scheduledAtLocal.microsecond,
      );

      await _plugin.zonedSchedule(
        id: item.id,
        title: item.title,
        body: item.body,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: item.payload,
      );
    }
  }
}
