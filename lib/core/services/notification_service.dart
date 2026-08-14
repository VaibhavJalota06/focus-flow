import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_model.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  NotificationService._init();

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.actionId == 'snooze_15') {
          snoozeTaskReminder(response.id ?? 0, const Duration(minutes: 15));
        } else if (response.actionId == 'snooze_1h') {
          snoozeTaskReminder(response.id ?? 0, const Duration(hours: 1));
        }
      },
    );

    // Create Notification Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'daily_task_reminders',
      'Task Reminders',
      description: 'Notifications for upcoming task deadlines and focus timer',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(androidChannel);
      try {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      } catch (e) {
        // Fallback for older Android versions
      }
    }

    _isInitialized = true;
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming task deadlines and focus timer',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (task.reminderTime == null || task.dueTime == null) return;

    final parts = task.dueTime!.split(':');
    if (parts.length != 2) return;

    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts[1]) ?? 0;

    var dueDateTime = DateTime(
      task.date.year,
      task.date.month,
      task.date.day,
      hour,
      minute,
    );

    int offsetMinutes = 0;
    if (task.reminderTime == '10_MIN_BEFORE') {
      offsetMinutes = 10;
    } else if (task.reminderTime == '30_MIN_BEFORE') {
      offsetMinutes = 30;
    } else if (task.reminderTime == '1_HOUR_BEFORE') {
      offsetMinutes = 60;
    }

    final reminderDateTime =
        dueDateTime.subtract(Duration(minutes: offsetMinutes));
    if (reminderDateTime.isBefore(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(reminderDateTime, tz.local);
    final notificationId = task.id.hashCode.abs();

    const androidDetails = AndroidNotificationDetails(
      'daily_task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming task deadlines and focus timer',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('snooze_15', 'Snooze 15m'),
        AndroidNotificationAction('snooze_1h', 'Snooze 1h'),
      ],
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '⏰ Task Reminder: ${task.title}',
      task.description.isNotEmpty
          ? task.description
          : 'Due at ${task.dueTime}',
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> snoozeTaskReminder(int notificationId, Duration snoozeDuration) async {
    final rescheduleTime = DateTime.now().add(snoozeDuration);
    final tzDateTime = tz.TZDateTime.from(rescheduleTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'daily_task_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming task deadlines and focus timer',
      importance: Importance.high,
      priority: Priority.high,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction('snooze_15', 'Snooze 15m'),
        AndroidNotificationAction('snooze_1h', 'Snooze 1h'),
      ],
    );

    const details = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      '⏰ Snoozed Task Reminder',
      'Rescheduled reminder',
      tzDateTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
