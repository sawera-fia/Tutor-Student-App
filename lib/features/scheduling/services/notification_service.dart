import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();

    // Android initialization settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for Android 13+
    if (androidSettings.defaultIcon != null) {
      await _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    _initialized = true;
    // ignore: avoid_print
    print('[NotificationService] Initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // ignore: avoid_print
    print('[NotificationService] Notification tapped: ${response.payload}');
    // TODO: Navigate to session details or join meeting
  }

  /// Schedule a notification for a session
  /// Schedules notifications 15 minutes before and at session start time
  Future<void> scheduleSessionNotifications({
    required int bookingId,
    required String subject,
    required String tutorOrStudentName,
    required DateTime sessionStartUtc,
    required DateTime sessionEndUtc,
    required bool isStudent, // true for student, false for tutor
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final sessionStart = tz.TZDateTime.from(sessionStartUtc, tz.UTC);
      final reminderTime = sessionStart.subtract(const Duration(minutes: 15));

      // Only schedule if the reminder time is in the future
      if (reminderTime.isAfter(tz.TZDateTime.now(tz.UTC))) {
        // Schedule reminder 15 minutes before
        await _scheduleNotification(
          id: bookingId * 10, // Unique ID for reminder
          title: 'Session Reminder',
          body: 'Your session "$subject" with $tutorOrStudentName starts in 15 minutes',
          scheduledDate: reminderTime,
          payload: 'booking:$bookingId:reminder',
        );
      }

      // Schedule notification at session start time
      if (sessionStart.isAfter(tz.TZDateTime.now(tz.UTC))) {
        await _scheduleNotification(
          id: bookingId * 10 + 1, // Unique ID for start notification
          title: 'Session Starting Now!',
          body: 'Your session "$subject" with $tutorOrStudentName is starting now',
          scheduledDate: sessionStart,
          payload: 'booking:$bookingId:start',
        );
      }

      // ignore: avoid_print
      print('[NotificationService] Scheduled notifications for booking $bookingId');
    } catch (e) {
      // ignore: avoid_print
      print('[NotificationService] Error scheduling notifications: $e');
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    // Android notification details
    const androidDetails = AndroidNotificationDetails(
      'session_channel',
      'Session Notifications',
      channelDescription: 'Notifications for tutoring sessions',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    // iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Combined notification details
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Schedule the notification
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel all notifications for a booking
  Future<void> cancelSessionNotifications(int bookingId) async {
    await _notifications.cancel(bookingId * 10); // Reminder notification
    await _notifications.cancel(bookingId * 10 + 1); // Start notification
    // ignore: avoid_print
    print('[NotificationService] Cancelled notifications for booking $bookingId');
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    // ignore: avoid_print
    print('[NotificationService] Cancelled all notifications');
  }
}

