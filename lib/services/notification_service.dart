import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import '../shared/firestore_constants.dart';

// Top-level function for handling background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('BG msg ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _initialized = false;
  static const String _prefsLastVerifiedKey = 'fcmLastVerifiedAt';
  static const String _prefsTokenKey = 'fcmLastToken';

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Timezone
    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Could not set local timezone: $e');
      // Fallback to UTC or system default if this fails
    }

    // 2. Initialize Local Notifications
    // Ensure you have an icon named 'ic_launcher' in android/app/src/main/res/mipmap-*
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification clicked: ${details.payload}');
        // Handle navigation if needed
      },
    );

    // 3. Create Notification Channels (Android)
    // Channel for Mining/Streak (Local)
    const AndroidNotificationChannel localChannel = AndroidNotificationChannel(
      'mining_reminders',
      'Mining Reminders',
      description: 'Notifications for mining sessions and streaks',
      importance: Importance.high,
    );

    // Channel for Firebase (Remote)
    const AndroidNotificationChannel fcmChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important announcements.',
      importance: Importance.max,
    );

    final platform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (platform != null) {
      await platform.createNotificationChannel(localChannel);
      await platform.createNotificationChannel(fcmChannel);
      try {
        await platform.requestNotificationsPermission();
      } catch (e) {
        debugPrint('Android notifications permission request failed: $e');
      }
      try {
        await platform.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Android exact alarm permission request failed: $e');
      }
    }

    // 4. Initialize Firebase Messaging
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        // If we receive a notification while in foreground, show it locally
        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                fcmChannel.id,
                fcmChannel.name,
                channelDescription: fcmChannel.description,
                icon: android.smallIcon ?? '@mipmap/ic_launcher',
                importance: Importance.max,
                priority: Priority.high,
              ),
            ),
          );
        }
      });

      String? token = await _firebaseMessaging.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && token != null && token.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .set({
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
              FirestoreUserFields.fcmToken: token,
            }, SetOptions(merge: true));
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefsTokenKey, token);
        await prefs.setInt(
          _prefsLastVerifiedKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
      _firebaseMessaging.onTokenRefresh.listen((tok) async {
        final u = FirebaseAuth.instance.currentUser?.uid;
        if (u != null && tok.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection(FirestoreConstants.users)
              .doc(u)
              .set({
                FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
                FirestoreUserFields.fcmToken: tok,
              }, SetOptions(merge: true));
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsTokenKey, tok);
          await prefs.setInt(
            _prefsLastVerifiedKey,
            DateTime.now().millisecondsSinceEpoch,
          );
        }
      });
    } else {
      debugPrint('notif permission declined');
    }

    _initialized = true;
  }

  // --- Scheduling ---

  static const int _miningFinishedId = 100;
  static const int _streakReminderId = 101;

  /// Schedules a notification when the mining session ends.
  Future<void> scheduleMiningFinished(DateTime endTime) async {
    if (!_initialized) return;
    await _localNotifications.cancel(_miningFinishedId);

    if (endTime.isBefore(DateTime.now())) return;

    try {
      await _localNotifications.zonedSchedule(
        _miningFinishedId,
        'Mining Session Ended',
        'Your mining session has finished! Tap to start a new session and keep earning.',
        tz.TZDateTime.from(endTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mining_reminders',
            'Mining Reminders',
            channelDescription: 'Notifications for mining sessions and streaks',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Scheduled mining finish notification at $endTime');
    } catch (e) {
      debugPrint('Error scheduling exact mining notification: $e');
      try {
        await _localNotifications.zonedSchedule(
          _miningFinishedId,
          'Mining Session Ended',
          'Your mining session has finished! Tap to start a new session and keep earning.',
          tz.TZDateTime.from(endTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'mining_reminders',
              'Mining Reminders',
              channelDescription:
                  'Notifications for mining sessions and streaks',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('Scheduled inexact mining finish notification at $endTime');
      } catch (e2) {
        debugPrint('Error scheduling inexact mining notification: $e2');
      }
    }
  }

  /// Schedules a streak reminder (e.g. 20 hours after session ends).
  Future<void> scheduleStreakReminder(DateTime endTime) async {
    if (!_initialized) return;
    await _localNotifications.cancel(_streakReminderId);

    // Schedule for 23 hours after session ENDS (so they have 1 hour left in 24h grace period)
    final reminderTime = endTime.add(const Duration(hours: 23));

    if (reminderTime.isBefore(DateTime.now())) return;

    try {
      await _localNotifications.zonedSchedule(
        _streakReminderId,
        'Keep your streak alive!',
        'You haven\'t mined in a while. Start a session now to maintain your streak.',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mining_reminders',
            'Mining Reminders',
            channelDescription: 'Notifications for mining sessions and streaks',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Scheduled streak reminder at $reminderTime');
    } catch (e) {
      debugPrint('Error scheduling streak notification: $e');
    }
  }

  /// Cancels all mining-related notifications (e.g. when starting a new session).
  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _localNotifications.cancel(_miningFinishedId);
    await _localNotifications.cancel(_streakReminderId);
  }

  Future<void> showTestLocalNow() async {
    if (!_initialized) return;
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      'Test Local',
      'This is a test local notification',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mining_reminders',
          'Mining Reminders',
          channelDescription: 'Notifications for mining sessions and streaks',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<String?> getFcmToken() async {
    return _firebaseMessaging.getToken();
  }

  Future<void> ensureTokenRegistered({bool force = false}) async {
    if (!_initialized) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_prefsLastVerifiedKey) ?? 0;
    final lastToken = prefs.getString(_prefsTokenKey) ?? '';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dayMs = 24 * 60 * 60 * 1000;
    final token = await _firebaseMessaging.getToken() ?? '';
    final shouldVerify =
        force ||
        (nowMs - lastMs > dayMs) ||
        (token.isNotEmpty && token != lastToken);
    if (!shouldVerify) return;
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .set({
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          FirestoreUserFields.fcmToken: token,
        }, SetOptions(merge: true));
    await prefs.setString(_prefsTokenKey, token);
    await prefs.setInt(_prefsLastVerifiedKey, nowMs);
  }
}
