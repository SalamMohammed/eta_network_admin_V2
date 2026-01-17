import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_constants.dart';

const bool kIsDev = !kReleaseMode;

enum UserActivityStatus { notStarted, active, inactive }

enum AppEntryMode { selector, mobile, admin }

class AppEntryConfig {
  static AppEntryMode mode = AppEntryMode.selector;
}

UserActivityStatus userActivityStatusFromUserData(Map<String, dynamic> data) {
  final ts = data[FirestoreUserFields.lastMiningEnd] as Timestamp?;
  if (ts == null) {
    return UserActivityStatus.notStarted;
  }
  final end = ts.toDate();
  final now = DateTime.now();
  if (now.isBefore(end)) {
    return UserActivityStatus.active;
  }
  final diffHours = now.difference(end).inHours;
  if (diffHours < 48) {
    return UserActivityStatus.active;
  }
  return UserActivityStatus.inactive;
}

bool isUserActiveWithin48h(Map<String, dynamic> data) {
  return userActivityStatusFromUserData(data) == UserActivityStatus.active;
}
