// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get totalBalance => 'Total Balance';

  @override
  String joinedDate(String link, Object date) {
    return 'Joined $date';
  }

  @override
  String get inviteEarn => 'Invite & Earn';

  @override
  String get shareCodeDescription =>
      'Share your unique code with friends to boost your mining rate.';

  @override
  String get shareLink => 'Share Link';

  @override
  String get totalInvited => 'TOTAL INVITED';

  @override
  String get activeNow => 'ACTIVE NOW';

  @override
  String get viewAll => 'View All';

  @override
  String get createCoin => 'Create Coin';

  @override
  String get mining => 'Mining';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Change app language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get balanceTitle => 'Balance';

  @override
  String get home => 'Home';

  @override
  String get referral => 'Referral';

  @override
  String get profile => 'Profile';

  @override
  String get dayStreak => 'Day Streak';

  @override
  String dayStreakValue(int count) {
    return '$count Day Streak';
  }

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get sessionEndsIn => 'Session ends in';

  @override
  String get startEarning => 'Start Earning';

  @override
  String get loadingAd => 'Loading ad…';

  @override
  String waitSeconds(int seconds) {
    return 'Wait ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Reward +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Rewarded ad not available';

  @override
  String rateBoosted(String rate) {
    return 'Rate boosted: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ad bonus failed: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Rate breakdown: Base $base, Streak +$streak, Rank +$rank, Referrals +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Unable to start mining. Please check your internet connection and try again.';

  @override
  String get createCommunityCoin => 'Create Community Coin';

  @override
  String get launchCoinDescription =>
      'Launch your own coin on ETA Network instantly.';

  @override
  String get createYourOwnCoin => 'Create your own coin';

  @override
  String get launchCommunityCoinDescription =>
      'Launch your own community coin that other ETA users can mine.';

  @override
  String get editCoin => 'Edit coin';

  @override
  String baseRate(String rate) {
    return 'Base rate: $rate coins/hour';
  }

  @override
  String createdBy(String username) {
    return 'Created by @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'No coins yet. Add from Live Coins.';

  @override
  String get mine => 'Mine';

  @override
  String get remaining => 'remaining';

  @override
  String get holders => 'Holders';

  @override
  String get close => 'Close';

  @override
  String get readMore => 'Read More';

  @override
  String get readLess => 'Read Less';

  @override
  String get projectLinks => 'Project Links';

  @override
  String get verifyEmailTitle => 'Verify Your Email';

  @override
  String get verifyEmailMessage =>
      'We have sent a verification link to your email address. Please verify your account to unlock all features.';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get iHaveVerified => 'I have verified';

  @override
  String get logout => 'Logout';

  @override
  String get emailVerifiedSuccess => 'Email verified successfully!';

  @override
  String get emailNotVerified =>
      'Email not verified yet. Please check your inbox.';

  @override
  String get verificationEmailSent => 'Verification email sent';

  @override
  String get startMining => 'Start Mining';

  @override
  String get minedCoins => 'Mined Coins';

  @override
  String get liveCoins => 'Live Coins';

  @override
  String get asset => 'Asset';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterNames => 'Names';

  @override
  String get filterOldNew => 'Old - New';

  @override
  String get filterNewOld => 'New - Old';

  @override
  String startMiningWithCount(int count) {
    return 'Start Mining ($count)';
  }

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get cancel => 'Cancel';

  @override
  String get refreshStatus => 'Refresh Status';

  @override
  String get purchaseFailed => 'Purchase failed';

  @override
  String get securePaymentViaGooglePlay => 'Secure payment via Google Play';

  @override
  String get addedToMinedCoins => 'Added to Mined Coins';

  @override
  String failedToAdd(String message) {
    return 'Failed to add: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Subscriptions are only available on Android/iOS.';

  @override
  String get miningRate => 'Mining rate';

  @override
  String get about => 'About';

  @override
  String get yourMined => 'Your Mined';

  @override
  String get totalMined => 'Total Mined';

  @override
  String get noReferrals => 'No referrals yet';

  @override
  String get linkCopied => 'Link copied';

  @override
  String get copy => 'Copy';

  @override
  String get howItWorks => 'How it works';

  @override
  String get referralDescription =>
      'Share your code with friends. When they join and become active, you grow your team and improve your earning potential.';

  @override
  String get yourTeam => 'Your Team';

  @override
  String get referralsTitle => 'Referrals';

  @override
  String get shareLinkTitle => 'Share Link';

  @override
  String get copyLinkInstruction => 'Copy this link to share:';

  @override
  String get referralCodeCopied => 'Referral code copied';

  @override
  String joinMeText(String code, String link) {
    return 'Join me on Eta Network! Use my code: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'No live community coins';

  @override
  String get rate => 'RATE';

  @override
  String get filterRandom => 'Random';

  @override
  String get baseRateLabel => 'Base Rate';

  @override
  String startFailed(String error) {
    return 'Start failed: $error';
  }

  @override
  String get sessionProgress => 'Session Progress';

  @override
  String get remainingLabel => 'remaining';

  @override
  String get boostRate => 'Boost Rate';

  @override
  String get minedLabel => 'Mined';

  @override
  String get noSubscriptionPlansAvailable => 'No subscription plans available';

  @override
  String get subscriptionPlans => 'Subscription Plans';

  @override
  String get recommended => 'Recommended';

  @override
  String get editCommunityCoin => 'Edit Community Coin';

  @override
  String get launchCoinEcosystemDescription =>
      'Launch your own coin inside ETA ecosystem for your community.';

  @override
  String get upload => 'Upload';

  @override
  String get recommendedImageSize => 'Recommended 200×200px';

  @override
  String get coinNameLabel => 'Coin name';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get baseMiningRateLabel => 'Base mining rate (coins/hour)';

  @override
  String maxAllowed(String max) {
    return 'Max Allowed : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Social & project links (optional)';

  @override
  String get linkTypeWebsite => 'Website';

  @override
  String get linkTypeYouTube => 'YouTube';

  @override
  String get linkTypeFacebook => 'Facebook';

  @override
  String get linkTypeTwitter => 'X / Twitter';

  @override
  String get linkTypeInstagram => 'Instagram';

  @override
  String get linkTypeTelegram => 'Telegram';

  @override
  String get linkTypeOther => 'Other';

  @override
  String get pasteUrl => 'Paste URL';

  @override
  String get importantNoticeTitle => 'Important Notice';

  @override
  String get importantNoticeBody =>
      'This coin is part of the ETA Network ecosystem and represents participation in a growing digital community. Community coins are created by users to build, experiment, and engage within the network. ETA Network is in an early stage of development. As the ecosystem grows, new utilities, features, and integrations may be introduced based on community activity, platform evolution, and applicable guidelines.';

  @override
  String get pleaseWait => 'Please wait…';

  @override
  String get save => 'Save';

  @override
  String createCoinFailed(String error) {
    return 'Failed to create coin: $error';
  }

  @override
  String get coinNameLengthError => 'Coin name must be 3–30 characters.';

  @override
  String get symbolRequiredError => 'Symbol is required.';

  @override
  String get symbolLengthError => 'Symbol must be 2–6 letters/numbers.';

  @override
  String get descriptionTooLongError => 'Description is too long.';

  @override
  String baseRateRangeError(String max) {
    return 'Base mining rate must be between 0.000000001 and $max.';
  }

  @override
  String get coinNameExistsError =>
      'Coin name already exists. Please choose another.';

  @override
  String get symbolExistsError =>
      'Symbol already exists. Please choose another.';

  @override
  String get urlInvalidError => 'One of the URLs is invalid.';

  @override
  String get subscribeAndBoost => 'Subscribe & Boost Mining';

  @override
  String get autoCollect => 'Auto-collect';

  @override
  String autoMineCoins(int count) {
    return 'Auto mine $count coins';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Speed';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'No description available.';

  @override
  String get unknownUser => 'Unknown';
}
