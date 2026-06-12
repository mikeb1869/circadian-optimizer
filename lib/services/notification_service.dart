import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/circadian_schedule.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
  );

  static const _notificationDetails = NotificationDetails(
    iOS: _iosDetails,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    final timezoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneName));

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(iOS: iosSettings),
    );
  }

  Future<bool> requestPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, sound: true);
    return granted ?? false;
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      _notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  Future<void> scheduleAllCueNotifications(CircadianSchedule schedule) async {
    await _plugin.cancelAll();

    await Future.wait([
      scheduleNotification(
        id: 1,
        title: 'Morning sunlight ☀️',
        body: 'Time to get outside for your morning light exposure.',
        scheduledDate: schedule.morningSunlightStart,
      ),
      scheduleNotification(
        id: 2,
        title: 'Caffeine cutoff ☕',
        body: 'Last call for caffeine — avoid it after this to protect your sleep.',
        scheduledDate: schedule.caffeineCutoff,
      ),
      scheduleNotification(
        id: 3,
        title: 'Afternoon sunlight 🌤️',
        body: 'Step outside for your afternoon light anchor.',
        scheduledDate: schedule.afternoonSunlightStart,
      ),
      scheduleNotification(
        id: 4,
        title: 'Dim the lights 🌙',
        body: 'Time to dim overhead lights and ease into the evening.',
        scheduledDate: schedule.dimLights,
      ),
    ]);
  }
}
