class FirestoreConstants {
  static const String users = 'users';
  static const String pointLogs = 'point_logs';
  static const String referrals = 'referrals';
  static const String appConfig = 'app_config';
  static const String roles = 'roles';
  static const String profiles = 'profiles';
  static const String settings = 'settings';
}

class FirestoreUserFields {
  static const String uid = 'uid';
  static const String email = 'email';
  static const String username = 'username';
  static const String referralCode = 'referralCode';
  static const String invitedBy = 'invitedBy';
  static const String role = 'role';
  static const String rank = 'rank';
  static const String totalPoints = 'totalPoints';
  static const String hourlyRate = 'hourlyRate';
  static const String lastMiningStart = 'lastMiningStart';
  static const String lastMiningEnd = 'lastMiningEnd';
  static const String streakDays = 'streakDays';
  static const String country = 'country';
  static const String deviceId = 'deviceId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
}

class FirestoreUserRoles {
  static const String free = 'free';
  static const String pro = 'pro';
  static const String admin = 'admin';
}

class FirestoreUserRanks {
  static const String explorer = 'Explorer';
  static const String builder = 'Builder';
  static const String guardian = 'Guardian';
}

class FirestorePointLogFields {
  static const String userId = 'userId';
  static const String type = 'type';
  static const String amount = 'amount';
  static const String timestamp = 'timestamp';
  static const String description = 'description';
}

class FirestorePointLogTypes {
  static const String tap = 'tap';
  static const String referral = 'referral';
  static const String streak = 'streak';
  static const String bonus = 'bonus';
}

class FirestoreReferralFields {
  static const String inviterId = 'inviterId';
  static const String inviteeId = 'inviteeId';
  static const String timestamp = 'timestamp';
}

class FirestoreAppConfigFields {
  static const String baseRate = 'baseRate';
  static const String maxReferralBonus = 'maxReferralBonus';
  static const String streakBonusTable = 'streakBonusTable';
}
