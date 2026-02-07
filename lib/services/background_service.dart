import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../firebase_options.dart';
import 'mining_state_service.dart';

// Top-level callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('[BackgroundService] Workmanager task: $task');
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (task == BackgroundService.taskManagerWakeup) {
        await MiningStateService().runManagerLogic();
      }
    } catch (e) {
      debugPrint('[BackgroundService] Error in Workmanager task: $e');
    }
    return Future.value(true);
  });
}

// Top-level AlarmManager callback
@pragma('vm:entry-point')
void alarmCallback() async {
  debugPrint('[BackgroundService] AlarmManager callback fired');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MiningStateService().runManagerLogic();
  } catch (e) {
    debugPrint('[BackgroundService] Error in AlarmManager callback: $e');
  }
}

class BackgroundService {
  static const String taskManagerWakeup =
      'com.eta_network.admin.manager_wakeup';
  static const int _alarmId = 777;

  static Future<void> init() async {
    try {
      if (!kIsWeb) {
        // Initialize Workmanager (iOS mainly, Android fallback)
        await Workmanager().initialize(
          callbackDispatcher,
          isInDebugMode: kDebugMode,
        );

        // Initialize AlarmManager (Android exact timing)
        // Note: android_alarm_manager_plus may show deprecation warnings during build.
        // This is expected and harmless; we need it for 'exact: true' precision
        // which Workmanager cannot provide.
        if (defaultTargetPlatform == TargetPlatform.android) {
          await AndroidAlarmManager.initialize();
        }
      }
    } catch (e) {
      debugPrint('[BackgroundService] Init failed: $e');
    }
  }

  /// Schedules a wake-up call at the specified [targetTime].
  /// Uses AndroidAlarmManager for exact timing on Android,
  /// and Workmanager for iOS (best effort).
  static Future<void> scheduleManagerWakeup(DateTime targetTime) async {
    final now = DateTime.now();
    if (targetTime.isBefore(now)) {
      debugPrint(
        '[BackgroundService] Target time is in past, running immediately',
      );
      await MiningStateService().runManagerLogic();
      return;
    }

    debugPrint('[BackgroundService] Scheduling wakeup at $targetTime');

    if (defaultTargetPlatform == TargetPlatform.android) {
      await AndroidAlarmManager.oneShotAt(
        targetTime,
        _alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } else {
      // iOS / Other: Use Workmanager
      // Workmanager minimum interval is 15min usually for periodic,
      // but oneOff can be scheduled with initialDelay.
      final delay = targetTime.difference(now);
      await Workmanager().registerOneOffTask(
        "${taskManagerWakeup}_${targetTime.millisecondsSinceEpoch}",
        taskManagerWakeup,
        initialDelay: delay,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(networkType: NetworkType.connected),
      );
    }
  }
}
