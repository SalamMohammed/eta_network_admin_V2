// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nigerian Pidgin (`pcm`).
class AppLocalizationsPcm extends AppLocalizations {
  AppLocalizationsPcm([String locale = 'pcm']) : super(locale);

  @override
  String get totalBalance => 'Total Money';

  @override
  String joinedDate(String link, Object date) {
    return 'You join for $date';
  }

  @override
  String get inviteEarn => 'Invite & Gain';

  @override
  String get shareCodeDescription =>
      'Share code give padi make mining speed increase.';

  @override
  String get shareLink => 'Share Dis Link';

  @override
  String get totalInvited => 'Total People Wey U Invite';

  @override
  String get activeNow => 'Dey Active Now';

  @override
  String get viewAll => 'See Everything';

  @override
  String get createCoin => 'Cook Coin';

  @override
  String get mining => 'De Mine';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitle => 'Change app language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get balanceTitle => 'Your Money';

  @override
  String get home => 'House';

  @override
  String get referral => 'Invite';

  @override
  String get profile => 'My Corner';

  @override
  String get dayStreak => 'Day Streak';

  @override
  String dayStreakValue(int count) {
    return '$count Day Waka';
  }

  @override
  String get active => 'Active';

  @override
  String get inactive => 'No Active';

  @override
  String get sessionEndsIn => 'Session go finish inside';

  @override
  String get startEarning => 'Start to Gather';

  @override
  String get loadingAd => 'Ad dey load...';

  @override
  String waitSeconds(int seconds) {
    return 'Wait ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Gain +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Ad bonus no dey';

  @override
  String rateBoosted(String rate) {
    return 'Speed don boost: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ad bonus fall hand: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Speed breakdown: Base $base, Streak +$streak, Rank +$rank, Referrals +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Mining no fit start. Abeg check internet try again.';

  @override
  String get createCommunityCoin => 'Cook Community Coin';

  @override
  String get launchCoinDescription =>
      'Start your own coin inside ETA sharp sharp.';

  @override
  String get createYourOwnCoin => 'Cook your own coin';

  @override
  String get launchCommunityCoinDescription =>
      'Start community coin make others fit mine am.';

  @override
  String get editCoin => 'Adjust coin';

  @override
  String baseRate(String rate) {
    return 'Normal rate: $rate coins/hour';
  }

  @override
  String createdBy(String username) {
    return 'Na @$username cook am';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'No coin dey. Add from Coins Wey Dey Live.';

  @override
  String get mine => 'Mine';

  @override
  String get remaining => 'remain';

  @override
  String get holders => 'Holders';

  @override
  String get close => 'Close';

  @override
  String get readMore => 'Read More';

  @override
  String get readLess => 'Read Small';

  @override
  String get projectLinks => 'Project Links';

  @override
  String get verifyEmailTitle => 'Check Your Email';

  @override
  String get verifyEmailMessage =>
      'We don send link enter email. Abeg verify make u fit use everything.';

  @override
  String get resendEmail => 'Send Email Again';

  @override
  String get iHaveVerified => 'I don verify';

  @override
  String get logout => 'Comot';

  @override
  String get emailVerifiedSuccess => 'Email don set!';

  @override
  String get emailNotVerified => 'Email never set. Check inbox.';

  @override
  String get verificationEmailSent => 'Verification email don land';

  @override
  String get startMining => 'Start Mining';

  @override
  String get minedCoins => 'Coins Wey I Get';

  @override
  String get liveCoins => 'Coins Wey Dey Live';

  @override
  String get asset => 'Property';

  @override
  String get filterStatus => 'Level';

  @override
  String get filterPopular => 'Wetin Dey Reign';

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
  String get refreshStatus => 'Refresh Level';

  @override
  String get purchaseFailed => 'Buying fall hand';

  @override
  String get securePaymentViaGooglePlay => 'Payment sure via Google Play';

  @override
  String get addedToMinedCoins => 'E don enter Coins Wey I Get';

  @override
  String failedToAdd(String message) {
    return 'E no gree add: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Subscription na for Android/iOS only.';

  @override
  String get miningRate => 'Mining Speed';

  @override
  String get about => 'Wetin We Be';

  @override
  String get yourMined => 'Wetin I Get';

  @override
  String get totalMined => 'Total Wetin I Get';

  @override
  String get noReferrals => 'You never invite person';

  @override
  String get linkCopied => 'Link don copy';

  @override
  String get copy => 'Copy';

  @override
  String get howItWorks => 'How e dey waka';

  @override
  String get referralDescription =>
      'Share code give padi. If dem join and active, your team go big and you go gain pass before.';

  @override
  String get yourTeam => 'Your Squad';

  @override
  String get referralsTitle => 'People Wey I Invite';

  @override
  String get shareLinkTitle => 'Share Link';

  @override
  String get copyLinkInstruction => 'Copy dis link share give person:';

  @override
  String get referralCodeCopied => 'Referral code don copy';

  @override
  String joinMeText(String code, String link) {
    return 'Follow me for ETA Network! Use my code: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'No community coins wey dey live';

  @override
  String get rate => 'RATE';

  @override
  String get filterRandom => 'Anyhow';

  @override
  String get baseRateLabel => 'Normal Rate';

  @override
  String startFailed(String error) {
    return 'Start fall hand: $error';
  }

  @override
  String get sessionProgress => 'Session Waka';

  @override
  String get remainingLabel => 'remain';

  @override
  String get boostRate => 'Boost Speed';

  @override
  String get minedLabel => 'Mined';

  @override
  String get noSubscriptionPlansAvailable => 'No plan dey';

  @override
  String get subscriptionPlans => 'Subscription Plans';

  @override
  String get recommended => 'We Recommend';

  @override
  String get editCommunityCoin => 'Adjust Community Coin';

  @override
  String get launchCoinEcosystemDescription =>
      'Start your coin inside ETA ecosystem for your people.';

  @override
  String get upload => 'Upload';

  @override
  String get recommendedImageSize => 'Recommended 200×200px';

  @override
  String get coinNameLabel => 'Coin Name';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get descriptionLabel => 'Wetin E Be';

  @override
  String get baseMiningRateLabel => 'Normal mining rate (coins/hour)';

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
  String get linkTypeOther => 'Others';

  @override
  String get pasteUrl => 'Paste Link';

  @override
  String get importantNoticeTitle => 'Hear Dis One';

  @override
  String get importantNoticeBody =>
      'Dis coin na part of ETA Network ecosystem...';

  @override
  String get pleaseWait => 'Abeg wait...';

  @override
  String get save => 'Save';

  @override
  String createCoinFailed(String error) {
    return 'Cook coin fall hand: $error';
  }

  @override
  String get coinNameLengthError => 'Coin name must get 3–30 characters.';

  @override
  String get symbolRequiredError => 'Symbol dey important.';

  @override
  String get symbolLengthError => 'Symbol must get 2–6 letters/numbers.';

  @override
  String get descriptionTooLongError => 'Wetin you write too long.';

  @override
  String baseRateRangeError(String max) {
    return 'Normal rate must dey between 0.000000001 and $max.';
  }

  @override
  String get coinNameExistsError =>
      'Coin name don dey before. Choose another one.';

  @override
  String get symbolExistsError => 'Symbol don dey before. Choose another one.';

  @override
  String get urlInvalidError => 'One Link no good.';

  @override
  String get subscribeAndBoost => 'Subscribe & Boost Mining';

  @override
  String get autoCollect => 'Auto-gather';

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
  String get noDescriptionAvailable => 'No description dey.';

  @override
  String get unknownUser => 'Unknown';

  @override
  String get streakLabel => 'STREAK';

  @override
  String get referralsLabel => 'PEOPLE WEY U INVITE';

  @override
  String get sessionsLabel => 'TIME WEY U DEY';

  @override
  String get accountInfoSection => 'Account Mata';

  @override
  String get accountInfoTile => 'Account Mata';

  @override
  String get invitedByPrompt => 'Person invite you?';

  @override
  String get enterReferralCode => 'Put referral code';

  @override
  String get invitedStatus => 'Invited';

  @override
  String get lockedStatus => 'Locked';

  @override
  String get applyButton => 'Apply';

  @override
  String get aboutPageTitle => 'Wetin We Be';

  @override
  String get faqTile => 'Question Wey Dem Ask';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Holla At Us';

  @override
  String get securitySettingsTile => 'Security Mata';

  @override
  String get securitySettingsPageTitle => 'Security Mata';

  @override
  String get deleteAccountTile => 'Comot Account';

  @override
  String get deleteAccountSubtitle => 'Comot account and everything kpatakpata';

  @override
  String get deleteAccountDialogTitle => 'Comot account?';

  @override
  String get deleteAccountDialogContent =>
      'Dis one go comot your account, data, and sessions kpatakpata. E no go fit comeback.';

  @override
  String get deleteButton => 'Comot Am';

  @override
  String get kycVerificationTile => 'KYC Verification';

  @override
  String get kycVerificationDialogTitle => 'KYC Verification';

  @override
  String get kycComingSoonMessage => 'E go show later.';

  @override
  String get okButton => 'Oya';

  @override
  String get logOutLabel => 'Comot';

  @override
  String get confirmDeletionTitle => 'Confirm make we comot am';

  @override
  String get enterAccountPassword => 'Put password';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get usernameLabel => 'Your Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get countryLabel => 'Country';

  @override
  String get addressLabel => 'Address';

  @override
  String get genderLabel => 'Man or Woman';

  @override
  String get enterUsernameHint => 'Put username';

  @override
  String get enterNameHint => 'Put name';

  @override
  String get enterAgeHint => 'Put age';

  @override
  String get enterCountryHint => 'Put country';

  @override
  String get enterAddressHint => 'Put address';

  @override
  String get enterGenderHint => 'Put gender';

  @override
  String get savingLabel => 'Saving...';

  @override
  String get usernameEmptyError => 'Username no fit empty';

  @override
  String get invalidAgeError => 'Age no correct';

  @override
  String get saveError => 'Save fall hand';

  @override
  String get cancelButton => 'Cancel';
}
