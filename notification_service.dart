import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/subscription.dart';

/// Schedules a local notification a few days before each subscription
/// renews. Fully on-device — no server or push service involved.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const int reminderDaysBefore = 3;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  /// Call once at startup (e.g. after the first frame) to ask the user
  /// for notification permission. Required on Android 13+ and iOS.
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Schedules a reminder `reminderDaysBefore` days before renewal.
  /// Uses the subscription id's hashCode as a stable notification id,
  /// so re-scheduling (on edit) naturally replaces the old one.
  Future<void> scheduleRenewalReminder(Subscription sub) async {
    await cancelReminder(sub);

    final reminderTime =
        sub.renewalDate.subtract(const Duration(days: reminderDaysBefore));
    if (reminderTime.isBefore(DateTime.now())) {
      return; // renewal is too soon or already past; nothing to schedule
    }

    const androidDetails = AndroidNotificationDetails(
      'subly_renewals',
      'Subscription renewals',
      channelDescription: 'Reminders before a subscription renews',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      sub.id.hashCode,
      '${sub.name} renews soon',
      '\$${sub.price.toStringAsFixed(2)} renews on '
          '${sub.renewalDate.month}/${sub.renewalDate.day}',
      tz.TZDateTime.from(reminderTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(Subscription sub) async {
    await _plugin.cancel(sub.id.hashCode);
  }
}
