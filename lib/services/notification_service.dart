import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
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
  static const String _prefsMiningFinishedAtMsKey =
      'localNotifMiningFinishedAtMs';
  static const String _prefsMiningFinishedResultKey =
      'localNotifMiningFinishedResult';
  static const String _prefsStreakAtMsKey = 'localNotifStreakAtMs';
  static const String _prefsStreakResultKey = 'localNotifStreakResult';

  Future<void> init() async {
    if (_initialized) return;

    // 1. Initialize Timezone
    tz_data.initializeTimeZones();
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
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
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

    final ios = _localNotifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    try {
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('iOS local notifications permission request failed: $e');
    }

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefsMiningFinishedAtMsKey,
      endTime.millisecondsSinceEpoch,
    );
    if (!_initialized) {
      await prefs.setString(_prefsMiningFinishedResultKey, 'not_initialized');
      return;
    }
    final now = DateTime.now();
    if (endTime.isBefore(now)) {
      await prefs.setString(
        _prefsMiningFinishedResultKey,
        'skipped_past now=${now.toIso8601String()} end=${endTime.toIso8601String()}',
      );
      return;
    }

    await _localNotifications.cancel(_miningFinishedId);

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
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      await prefs.setString(_prefsMiningFinishedResultKey, 'scheduled_exact');
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
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        await prefs.setString(
          _prefsMiningFinishedResultKey,
          'scheduled_inexact',
        );
        debugPrint('Scheduled inexact mining finish notification at $endTime');
      } catch (e2) {
        await prefs.setString(
          _prefsMiningFinishedResultKey,
          'error_inexact $e2',
        );
        debugPrint('Error scheduling inexact mining notification: $e2');
      }
    }
  }

  /// Schedules a streak reminder (e.g. 20 hours after session ends).
  Future<void> scheduleStreakReminder(DateTime endTime) async {
    final reminderTime = endTime.add(const Duration(hours: 23));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefsStreakAtMsKey,
      reminderTime.millisecondsSinceEpoch,
    );
    if (!_initialized) {
      await prefs.setString(_prefsStreakResultKey, 'not_initialized');
      return;
    }
    final now = DateTime.now();
    if (reminderTime.isBefore(now)) {
      await prefs.setString(
        _prefsStreakResultKey,
        'skipped_past now=${now.toIso8601String()} reminder=${reminderTime.toIso8601String()}',
      );
      return;
    }

    await _localNotifications.cancel(_streakReminderId);

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
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      await prefs.setString(_prefsStreakResultKey, 'scheduled_inexact');
      debugPrint('Scheduled streak reminder at $reminderTime');
    } catch (e) {
      await prefs.setString(_prefsStreakResultKey, 'error $e');
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<String> buildDiagnostics() async {
    final lines = <String>[];
    lines.add('=== Notification Diagnostics ===');
    lines.add('initialized=$_initialized');
    lines.add('kIsWeb=$kIsWeb');
    lines.add('platform=${defaultTargetPlatform.name}');
    final now = DateTime.now();
    lines.add('now=${now.toIso8601String()}');
    lines.add('tzLocal=${tz.local.name}');

    try {
      final prefs = await SharedPreferences.getInstance();
      final miningAtMs = prefs.getInt(_prefsMiningFinishedAtMsKey);
      final miningRes = prefs.getString(_prefsMiningFinishedResultKey);
      if (miningAtMs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(miningAtMs);
        lines.add('miningFinishedAt=${dt.toIso8601String()}');
        lines.add('miningFinishedIn=${dt.difference(now).inSeconds}s');
      }
      if (miningRes != null && miningRes.isNotEmpty) {
        lines.add('miningFinishedResult=$miningRes');
      }

      final streakAtMs = prefs.getInt(_prefsStreakAtMsKey);
      final streakRes = prefs.getString(_prefsStreakResultKey);
      if (streakAtMs != null) {
        final dt = DateTime.fromMillisecondsSinceEpoch(streakAtMs);
        lines.add('streakReminderAt=${dt.toIso8601String()}');
        lines.add('streakReminderIn=${dt.difference(now).inSeconds}s');
      }
      if (streakRes != null && streakRes.isNotEmpty) {
        lines.add('streakReminderResult=$streakRes');
      }
    } catch (e) {
      lines.add('localScheduleStateError=$e');
    }

    try {
      final tzName = await FlutterTimezone.getLocalTimezone();
      lines.add('deviceTimeZone=$tzName');
    } catch (e) {
      lines.add('deviceTimeZoneError=$e');
    }

    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      lines.add('fcmAuthorization=${settings.authorizationStatus.name}');
      lines.add('fcmAlert=${settings.alert.name}');
      lines.add('fcmBadge=${settings.badge.name}');
      lines.add('fcmSound=${settings.sound.name}');
    } catch (e) {
      lines.add('fcmSettingsError=$e');
    }

    try {
      final android = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final enabled = await android.areNotificationsEnabled();
        lines.add('androidNotificationsEnabled=$enabled');
        final canExact = await android.canScheduleExactNotifications();
        lines.add('androidCanScheduleExact=$canExact');
      } else {
        lines.add('androidImplementation=null');
      }
    } catch (e) {
      lines.add('androidStatusError=$e');
    }

    try {
      final ios = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      lines.add('iosImplementation=${ios != null}');
    } catch (e) {
      lines.add('iosStatusError=$e');
    }

    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      lines.add('pendingCount=${pending.length}');
      for (final p in pending) {
        lines.add('pending id=${p.id} title=${p.title} body=${p.body}');
      }
    } catch (e) {
      lines.add('pendingError=$e');
    }

    return lines.join('\n');
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
