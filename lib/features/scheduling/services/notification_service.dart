import 'package:flutter/foundation.dart' show kIsWeb;

/// Notification service for scheduling session reminders
/// 
/// Note: This service requires `flutter_local_notifications` and `timezone` packages
/// which are only available on mobile platforms (Android/iOS), not web.
/// 
/// To enable notifications:
/// 1. Run `flutter pub get` to install packages
/// 2. Test on Android/iOS device or emulator (not web)
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    
    // Notifications don't work on web
    if (kIsWeb) {
      // ignore: avoid_print
      print('[NotificationService] Skipping initialization on web platform');
      _initialized = true;
      return;
    }

    // On mobile, packages need to be installed
    // For now, we'll just mark as initialized
    // TODO: Uncomment when packages are installed and testing on mobile
    /*
    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Initialize notifications plugin
      final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();

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
      await notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Request permissions for Android 13+
      await notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
      print('[NotificationService] Initialized');
    } catch (e) {
      print('[NotificationService] Error initializing: $e');
      _initialized = true; // Mark as initialized to prevent retries
    }
    */
    
    _initialized = true;
    // ignore: avoid_print
    print('[NotificationService] Initialized (stub mode - install packages for full functionality)');
  }

  void _onNotificationTapped(dynamic response) {
    // ignore: avoid_print
    print('[NotificationService] Notification tapped: ${response?.payload}');
    // TODO: Navigate to session details or join meeting
  }

  /// Schedule a notification for a session
  /// Schedules notifications 15 minutes before and at session start time
  /// 
  /// Note: This is a stub implementation. Install packages and uncomment code
  /// in initialize() method for full functionality on mobile platforms.
  Future<void> scheduleSessionNotifications({
    required int bookingId,
    required String subject,
    required String tutorOrStudentName,
    required DateTime sessionStartUtc,
    required DateTime sessionEndUtc,
    required bool isStudent, // true for student, false for tutor
  }) async {
    // Skip on web
    if (kIsWeb) {
      // ignore: avoid_print
      print('[NotificationService] Skipping notification scheduling on web');
      return;
    }

    if (!_initialized) {
      await initialize();
    }

    // Stub implementation - logs what would be scheduled
    final reminderTime = sessionStartUtc.subtract(const Duration(minutes: 15));
    final now = DateTime.now().toUtc();

    if (reminderTime.isAfter(now)) {
      // ignore: avoid_print
      print('[NotificationService] Would schedule reminder for booking $bookingId: "$subject" with $tutorOrStudentName at $reminderTime');
    }

    if (sessionStartUtc.isAfter(now)) {
      // ignore: avoid_print
      print('[NotificationService] Would schedule start notification for booking $bookingId: "$subject" with $tutorOrStudentName at $sessionStartUtc');
    }

    // TODO: Uncomment when packages are installed
    /*
    try {
      final sessionStart = tz.TZDateTime.from(sessionStartUtc, tz.UTC);
      final reminderTime = sessionStart.subtract(const Duration(minutes: 15));

      if (reminderTime.isAfter(tz.TZDateTime.now(tz.UTC))) {
        await _scheduleNotification(
          id: bookingId * 10,
          title: 'Session Reminder',
          body: 'Your session "$subject" with $tutorOrStudentName starts in 15 minutes',
          scheduledDate: reminderTime,
          payload: 'booking:$bookingId:reminder',
        );
      }

      if (sessionStart.isAfter(tz.TZDateTime.now(tz.UTC))) {
        await _scheduleNotification(
          id: bookingId * 10 + 1,
          title: 'Session Starting Now!',
          body: 'Your session "$subject" with $tutorOrStudentName is starting now',
          scheduledDate: sessionStart,
          payload: 'booking:$bookingId:start',
        );
      }
    } catch (e) {
      print('[NotificationService] Error scheduling notifications: $e');
    }
    */
  }

  /// Cancel all notifications for a booking
  Future<void> cancelSessionNotifications(int bookingId) async {
    // Stub implementation
    // ignore: avoid_print
    print('[NotificationService] Would cancel notifications for booking $bookingId');
    
    // TODO: Uncomment when packages are installed
    /*
    await _notifications.cancel(bookingId * 10);
    await _notifications.cancel(bookingId * 10 + 1);
    */
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // Stub implementation
    // ignore: avoid_print
    print('[NotificationService] Would cancel all notifications');
    
    // TODO: Uncomment when packages are installed
    /*
    await _notifications.cancelAll();
    */
  }
}
