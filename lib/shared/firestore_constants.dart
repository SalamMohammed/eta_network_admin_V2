class FirestoreConstants {
  static const String users = 'users';
  static const String pointLogs = 'point_logs';
  static const String referrals = 'referrals';
  static const String referralStats = 'referral_stats';
  static const String appConfig = 'app_config';
  static const String roles = 'roles';
  static const String profiles = 'profiles';
  static const String settings = 'settings';
  static const String userCoins = 'user_coins';
  static const String managers = 'managers';
}

class FirestoreUserSubCollections {
  static const String coins = 'coins';
}

class FirestoreUserFields {
  static const String uid = 'uid';
  static const String email = 'email';
  static const String username = 'username';
  static const String name = 'name';
  static const String age = 'age';
  static const String referralCode = 'referralCode';
  static const String invitedBy = 'invitedBy';
  static const String referralLocked = 'referralLocked';
  static const String role = 'role';
  static const String rank = 'rank';
  static const String totalPoints = 'totalPoints';
  static const String totalSessions = 'totalSessions';
  static const String hourlyRate = 'hourlyRate';
  static const String lastMiningStart = 'lastMiningStart';
  static const String lastMiningEnd = 'lastMiningEnd';
  static const String lastSyncedAt = 'lastSyncedAt';
  static const String streakDays = 'streakDays';
  static const String streakLastUpdatedDay = 'streakLastUpdatedDay';
  static const String country = 'country';
  static const String address = 'address';
  static const String gender = 'gender';
  static const String deviceId = 'deviceId';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String managerEnabled = 'managerEnabled';
  static const String activeManagerId = 'activeManagerId';
  static const String managedCoinSelections = 'managedCoinSelections';
  static const String managerBonusPerHour = 'managerBonusPerHour';
  static const String subscription = 'subscription';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String fcmToken = 'fcmToken';
}

class FirestoreUserSubscriptionFields {
  static const String status = 'status';
  static const String planId = 'planId';
  static const String provider = 'provider';
  static const String expiresAt = 'expiresAt';
  static const String autoRenew = 'autoRenew';
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
  static const String inviteeUsername = 'inviteeUsername';
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
  static const String revenueCatApiKey = 'revenueCatApiKey';
  static const String revenueCatWebhookAuth = 'revenueCatWebhookAuth';
  static const String enableSubscriptions = 'enableSubscriptions';
  static const String sandboxMode = 'sandboxMode';
}

class FirestoreAppConfigDocs {
  static const String general = 'general';
  static const String referrals = 'referrals';
  static const String streak = 'streak';
  static const String ranks = 'ranks';
  static const String userCoin = 'user_coin';
  static const String manager = 'manager';
  static const String legal = 'legal';
  static const String ads = 'ads';
}

class FirestoreAdsConfigFields {
  static const String enableRewarded = 'enableRewarded';
  static const String enableBannerOnMiningPress = 'enableBannerOnMiningPress';
  static const String maxRewardedPerDay = 'maxRewardedPerDay';
  static const String maxRewardedPerMiningSession =
      'maxRewardedPerMiningSession';
  static const String rewardBonusPercent = 'rewardBonusPercent';
  static const String bannerAdUnitIdAndroid = 'bannerAdUnitIdAndroid';
  static const String bannerAdUnitIdIos = 'bannerAdUnitIdIos';
  static const String rewardedAdUnitIdAndroid = 'rewardedAdUnitIdAndroid';
  static const String rewardedAdUnitIdIos = 'rewardedAdUnitIdIos';
}

class FirestoreLegalFields {
  static const String appName = 'appName';
  static const String tagline = 'tagline';
  static const String about = 'about';
  static const String faq = 'faq';
  static const String whitePaper = 'whitePaper';
  static const String contactUs = 'contactUs';
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

class FirestoreManagerFields {
  static const String name = 'name';
  static const String thumbnailUrl = 'thumbnailUrl';
  static const String enableEtaAuto = 'enableEtaAuto';
  static const String enableUserCoinAuto = 'enableUserCoinAuto';
  static const String globalCommunity = 'globalCommunity';
  static const String maxCommunityCoinsManaged = 'maxCommunityCoinsManaged';
  static const String managerMultiplier = 'managerMultiplier';
  static const String storeProductId = 'storeProductId';
  static const String bestValue = 'bestValue';
  static const String isActive = 'isActive';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
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
  static const String minersCount = 'minersCount';
}

class FirestoreUserCoinMiningFields {
  static const String ownerId = 'ownerId';
  static const String name = 'name';
  static const String symbol = 'symbol';
  static const String imageUrl = 'imageUrl';
  static const String description = 'description';
  static const String hourlyRate = 'hourlyRate';
  static const String totalPoints = 'totalPoints';
  static const String lastMiningStart = 'lastMiningStart';
  static const String lastMiningEnd = 'lastMiningEnd';
  static const String lastSyncedAt = 'lastSyncedAt';
  static const String socialLinks = 'socialLinks';
}
