class FirestoreConstants {
  static const String users = 'users';
  static const String pointLogs = 'point_logs';
  static const String referrals = 'referrals';
  static const String appConfig = 'app_config';
  static const String roles = 'roles';
  static const String profiles = 'profiles';
  static const String settings = 'settings';
  static const String userCoins = 'user_coins';
}

class FirestoreUserSubCollections {
  static const String coins = 'coins';
}

class FirestoreUserFields {
  static const String uid = 'uid';
  static const String email = 'email';
  static const String username = 'username';
  static const String referralCode = 'referralCode';
  static const String invitedBy = 'invitedBy';
  static const String referralLocked = 'referralLocked';
  static const String role = 'role';
  static const String rank = 'rank';
  static const String totalPoints = 'totalPoints';
  static const String hourlyRate = 'hourlyRate';
  static const String lastMiningStart = 'lastMiningStart';
  static const String lastMiningEnd = 'lastMiningEnd';
  static const String lastSyncedAt = 'lastSyncedAt';
  static const String streakDays = 'streakDays';
  static const String streakLastUpdatedDay = 'streakLastUpdatedDay';
  static const String country = 'country';
  static const String deviceId = 'deviceId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String managerEnabled = 'managerEnabled';
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
  static const String isActive = 'isActive';
}

class FirestoreAppConfigFields {
  static const String baseRate = 'baseRate';
  static const String maxReferralBonus = 'maxReferralBonus';
  static const String streakBonusTable = 'streakBonusTable';
  static const String sessionDurationHours = 'sessionDurationHours';
  static const String maxReferralBonusRate = 'maxReferralBonusRate';
  static const String referralBonusStep = 'referralBonusStep';
  static const String deviceSingleUserEnforced = 'deviceSingleUserEnforced';
  static const String minRatePerHour = 'minRatePerHour';
  static const String maxRatePerHour = 'maxRatePerHour';
  static const String maxSocialLinks = 'maxSocialLinks';
  static const String maxDescriptionLength = 'maxDescriptionLength';
  static const String allowImageUpload = 'allowImageUpload';
  static const String allowUserRateEdit = 'allowUserRateEdit';
}

class FirestoreAppConfigDocs {
  static const String general = 'general';
  static const String referrals = 'referrals';
  static const String streak = 'streak';
  static const String ranks = 'ranks';
  static const String userCoin = 'user_coin';
  static const String manager = 'manager';
}

class FirestoreReferralConfigFields {
  static const String referrerBonus = 'referrerBonus';
  static const String inviteeBonus = 'inviteeBonus';
  static const String activateOnFirstSession = 'activateOnFirstSession';
  static const String inviteeFixedBonusPoints = 'inviteeFixedBonusPoints';
  static const String referrerPercentPerReferral = 'referrerPercentPerReferral';
  static const String referrerMaxCount = 'referrerMaxCount';
}

class FirestoreStreakConfigFields {
  static const String maxStreakDays = 'maxStreakDays';
  static const String maxStreakMultiplier = 'maxStreakMultiplier';
}

class FirestoreRankConfigFields {
  static const String rankRules = 'rankRules';
  static const String rankMultipliers = 'rankMultipliers';
}

class FirestoreManagerConfigFields {
  static const String enabledGlobally = 'enabledGlobally';
  static const String enableEtaAuto = 'enableEtaAuto';
  static const String enableUserCoinAuto = 'enableUserCoinAuto';
  static const String maxCommunityCoinsManaged = 'maxCommunityCoinsManaged';
}

class FirestoreUserCoinFields {
  static const String ownerId = 'ownerId';
  static const String name = 'name';
  static const String symbol = 'symbol';
  static const String imageUrl = 'imageUrl';
  static const String description = 'description';
  static const String socialLinks = 'socialLinks';
  static const String baseRatePerHour = 'baseRatePerHour';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isActive = 'isActive';
}

class FirestoreUserCoinMiningFields {
  static const String ownerId = 'ownerId';
  static const String name = 'name';
  static const String symbol = 'symbol';
  static const String imageUrl = 'imageUrl';
  static const String hourlyRate = 'hourlyRate';
  static const String totalPoints = 'totalPoints';
  static const String lastMiningStart = 'lastMiningStart';
  static const String lastMiningEnd = 'lastMiningEnd';
  static const String lastSyncedAt = 'lastSyncedAt';
}
