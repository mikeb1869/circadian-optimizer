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

  static const _notificationDetails = NotificationDetails(iOS: _iosDetails);

  Future<void> init() async {
    tz.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(const InitializationSettings(iOS: iosSettings));
  }

  Future<bool> requestPermission() async {
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
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

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> scheduleAllCueNotifications(
    CircadianSchedule today,
    CircadianSchedule tomorrow,
  ) async {
    await _plugin.cancelAll();

    final nudgeDate = DateTime.now().add(const Duration(days: 2));

    await Future.wait([
      // Today's cues — IDs 1–4
      scheduleNotification(
        id: 1,
        title: 'Morning sunlight ☀️',
        body: 'Time to get outside for your morning light exposure.',
        scheduledDate: today.morningSunlightStart,
      ),
      scheduleNotification(
        id: 2,
        title: 'Caffeine cutoff ☕',
        body: 'Last call for caffeine — avoid it after this to protect your sleep.',
        scheduledDate: today.caffeineCutoff,
      ),
      scheduleNotification(
        id: 3,
        title: 'Afternoon sunlight 🌤️',
        body: 'Step outside for your afternoon light anchor.',
        scheduledDate: today.afternoonSunlightStart,
      ),
      scheduleNotification(
        id: 4,
        title: 'Dim the lights 🌙',
        body: 'Time to dim overhead lights and ease into the evening.',
        scheduledDate: today.dimLights,
      ),
      // Tomorrow's cues — IDs 5–8
      scheduleNotification(
        id: 5,
        title: 'Morning sunlight ☀️',
        body: 'Time to get outside for your morning light exposure.',
        scheduledDate: tomorrow.morningSunlightStart,
      ),
      scheduleNotification(
        id: 6,
        title: 'Caffeine cutoff ☕',
        body: 'Last call for caffeine — avoid it after this to protect your sleep.',
        scheduledDate: tomorrow.caffeineCutoff,
      ),
      scheduleNotification(
        id: 7,
        title: 'Afternoon sunlight 🌤️',
        body: 'Step outside for your afternoon light anchor.',
        scheduledDate: tomorrow.afternoonSunlightStart,
      ),
      scheduleNotification(
        id: 8,
        title: 'Dim the lights 🌙',
        body: 'Time to dim overhead lights and ease into the evening.',
        scheduledDate: tomorrow.dimLights,
      ),
      // Nudge — ID 9
      scheduleNotification(
        id: 9,
        title: 'Helio needs a refresh 📅',
        body: 'It\'s been a couple of days — tap to refresh your Helio schedule.',
        scheduledDate: nudgeDate,
      ),
    ]);
  }
}
