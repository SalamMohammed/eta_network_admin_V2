// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get totalBalance => 'ਕੁੱਲ ਬਕਾਇਆ';

  @override
  String joinedDate(String link, Object date) {
    return '$date ਨੂੰ ਸ਼ਾਮਲ ਹੋਇਆ';
  }

  @override
  String get inviteEarn => 'ਸੱਦਾ ਦਿਓ ਅਤੇ ਕਮਾਓ';

  @override
  String get shareCodeDescription =>
      'ਆਪਣੀ ਮਾਈਨਿੰਗ ਦਰ ਵਧਾਉਣ ਲਈ ਆਪਣਾ ਵਿਲੱਖਣ ਕੋਡ ਦੋਸਤਾਂ ਨਾਲ ਸਾਂਝਾ ਕਰੋ।';

  @override
  String get shareLink => 'ਲਿੰਕ ਸਾਂਝਾ ਕਰੋ';

  @override
  String get totalInvited => 'ਕੁੱਲ ਸੱਦੇ ਗਏ';

  @override
  String get activeNow => 'ਹੁਣੇ ਸਰਗਰਮ';

  @override
  String get viewAll => 'ਸਭ ਦੇਖੋ';

  @override
  String get createCoin => 'ਸਿੱਕਾ ਬਣਾਓ';

  @override
  String get mining => 'ਮਾਈਨਿੰਗ';

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get languageSubtitle => 'ਐਪ ਭਾਸ਼ਾ ਬਦਲੋ';

  @override
  String get selectLanguage => 'ਭਾਸ਼ਾ ਚੁਣੋ';

  @override
  String get balanceTitle => 'ਬਕਾਇਆ';

  @override
  String get home => 'ਹੋਮ';

  @override
  String get referral => 'ਰੈਫਰਲ';

  @override
  String get profile => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get dayStreak => 'ਦਿਨ ਦੀ ਲੜੀ';

  @override
  String dayStreakValue(int count) {
    return '$count ਦਿਨ ਦੀ ਲੜੀ';
  }

  @override
  String get active => 'ਸਰਗਰਮ';

  @override
  String get inactive => 'ਗੈਰ-ਸਰਗਰਮ';

  @override
  String get sessionEndsIn => 'ਸੈਸ਼ਨ ਸਮਾਪਤ ਹੋਵੇਗਾ';

  @override
  String get startEarning => 'ਕਮਾਈ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get loadingAd => 'ਵਿਗਿਆਪਨ ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds ਸਕਿੰਟ ਉਡੀਕ ਕਰੋ';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'ਇਨਾਮ +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'ਇਨਾਮ ਵਾਲਾ ਵਿਗਿਆਪਨ ਉਪਲਬਧ ਨਹੀਂ ਹੈ';

  @override
  String rateBoosted(String rate) {
    return 'ਦਰ ਵਧਾਈ ਗਈ: +$rate ETA/ਘੰਟਾ';
  }

  @override
  String adBonusFailed(String message) {
    return 'ਵਿਗਿਆਪਨ ਬੋਨਸ ਅਸਫਲ: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'ਦਰ ਦਾ ਵੇਰਵਾ: ਅਧਾਰ $base, ਲੜੀ +$streak, ਦਰਜਾ +$rank, ਰੈਫਰਲ +$referrals = $total ETA/ਘੰਟਾ';
  }

  @override
  String get unableToStartMining =>
      'ਮਾਈਨਿੰਗ ਸ਼ੁਰੂ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਇੰਟਰਨੈਟ ਕਨੈਕਸ਼ਨ ਚੈੱਕ ਕਰੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get createCommunityCoin => 'ਕਮਿਊਨਿਟੀ ਸਿੱਕਾ ਬਣਾਓ';

  @override
  String get launchCoinDescription =>
      'ETA ਨੈੱਟਵਰਕ \'ਤੇ ਆਪਣਾ ਸਿੱਕਾ ਤੁਰੰਤ ਲਾਂਚ ਕਰੋ।';

  @override
  String get createYourOwnCoin => 'ਆਪਣਾ ਸਿੱਕਾ ਬਣਾਓ';

  @override
  String get launchCommunityCoinDescription =>
      'ਆਪਣਾ ਕਮਿਊਨਿਟੀ ਸਿੱਕਾ ਲਾਂਚ ਕਰੋ ਜਿਸ ਨੂੰ ਹੋਰ ETA ਉਪਭੋਗਤਾ ਮਾਈਨ ਕਰ ਸਕਣ।';

  @override
  String get editCoin => 'ਸਿੱਕਾ ਸੰਪਾਦਿਤ ਕਰੋ';

  @override
  String baseRate(String rate) {
    return 'ਅਧਾਰ ਦਰ: $rate ਸਿੱਕੇ/ਘੰਟਾ';
  }

  @override
  String createdBy(String username) {
    return '@$username ਦੁਆਰਾ ਬਣਾਇਆ ਗਿਆ';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ਘੰਟਾ';
  }

  @override
  String get noCoinsYet => 'ਅਜੇ ਕੋਈ ਸਿੱਕੇ ਨਹੀਂ। ਲਾਈਵ ਸਿੱਕਿਆਂ ਤੋਂ ਸ਼ਾਮਲ ਕਰੋ।';

  @override
  String get mine => 'ਮਾਈਨ';

  @override
  String get remaining => 'ਬਾਕੀ';

  @override
  String get holders => 'ਧਾਰਕ';

  @override
  String get close => 'ਬੰਦ ਕਰੋ';

  @override
  String get readMore => 'ਹੋਰ ਪੜ੍ਹੋ';

  @override
  String get readLess => 'ਘੱਟ ਪੜ੍ਹੋ';

  @override
  String get projectLinks => 'ਪ੍ਰੋਜੈਕਟ ਲਿੰਕ';

  @override
  String get verifyEmailTitle => 'ਆਪਣੇ ਈਮੇਲ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ';

  @override
  String get verifyEmailMessage =>
      'ਅਸੀਂ ਤੁਹਾਡੇ ਈਮੇਲ ਪਤੇ \'ਤੇ ਇੱਕ ਪੁਸ਼ਟੀਕਰਨ ਲਿੰਕ ਭੇਜਿਆ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਸਾਰੀਆਂ ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ ਨੂੰ ਅਨਲੌਕ ਕਰਨ ਲਈ ਆਪਣੇ ਖਾਤੇ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ।';

  @override
  String get resendEmail => 'ਈਮੇਲ ਦੁਬਾਰਾ ਭੇਜੋ';

  @override
  String get iHaveVerified => 'ਮੈਂ ਪੁਸ਼ਟੀ ਕਰ ਲਈ ਹੈ';

  @override
  String get logout => 'ਲਾਗ ਆਉਟ';

  @override
  String get emailVerifiedSuccess => 'ਈਮੇਲ ਦੀ ਸਫਲਤਾਪੂਰਵਕ ਪੁਸ਼ਟੀ ਕੀਤੀ ਗਈ!';

  @override
  String get emailNotVerified =>
      'ਈਮੇਲ ਦੀ ਅਜੇ ਤੱਕ ਪੁਸ਼ਟੀ ਨਹੀਂ ਹੋਈ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਇਨਬਾਕਸ ਚੈੱਕ ਕਰੋ।';

  @override
  String get verificationEmailSent => 'ਪੁਸ਼ਟੀਕਰਨ ਈਮੇਲ ਭੇਜੀ ਗਈ';

  @override
  String get startMining => 'ਮਾਈਨਿੰਗ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String get minedCoins => 'ਮਾਈਨ ਕੀਤੇ ਸਿੱਕੇ';

  @override
  String get liveCoins => 'ਲਾਈਵ ਸਿੱਕੇ';

  @override
  String get asset => 'ਸੰਪਤੀ';

  @override
  String get filterStatus => 'ਸਥਿਤੀ';

  @override
  String get filterPopular => 'ਪ੍ਰਸਿੱਧ';

  @override
  String get filterNames => 'ਨਾਮ';

  @override
  String get filterOldNew => 'ਪੁਰਾਣਾ - ਨਵਾਂ';

  @override
  String get filterNewOld => 'ਨਵਾਂ - ਪੁਰਾਣਾ';

  @override
  String startMiningWithCount(int count) {
    return 'ਮਾਈਨਿੰਗ ਸ਼ੁਰੂ ਕਰੋ ($count)';
  }

  @override
  String get clearSelection => 'ਚੋਣ ਸਾਫ਼ ਕਰੋ';

  @override
  String get cancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get refreshStatus => 'ਸਥਿਤੀ ਤਾਜ਼ਾ ਕਰੋ';

  @override
  String get purchaseFailed => 'ਖਰੀਦ ਅਸਫਲ';

  @override
  String get securePaymentViaGooglePlay => 'ਗੂਗਲ ਪਲੇ ਦੁਆਰਾ ਸੁਰੱਖਿਅਤ ਭੁਗਤਾਨ';

  @override
  String get addedToMinedCoins => 'ਮਾਈਨ ਕੀਤੇ ਸਿੱਕਿਆਂ ਵਿੱਚ ਸ਼ਾਮਲ ਕੀਤਾ ਗਿਆ';

  @override
  String failedToAdd(String message) {
    return 'ਸ਼ਾਮਲ ਕਰਨ ਵਿੱਚ ਅਸਫਲ: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'ਗਾਹਕੀਆਂ ਸਿਰਫ ਐਂਡਰਾਇਡ/ਆਈਓਐਸ \'ਤੇ ਉਪਲਬਧ ਹਨ।';

  @override
  String get miningRate => 'ਮਾਈਨਿੰਗ ਦਰ';

  @override
  String get about => 'ਬਾਰੇ';

  @override
  String get yourMined => 'ਤੁਹਾਡਾ ਮਾਈਨ ਕੀਤਾ';

  @override
  String get totalMined => 'ਕੁੱਲ ਮਾਈਨ ਕੀਤਾ';

  @override
  String get noReferrals => 'ਅਜੇ ਕੋਈ ਰੈਫਰਲ ਨਹੀਂ';

  @override
  String get linkCopied => 'ਲਿੰਕ ਕਾਪੀ ਹੋ ਗਿਆ';

  @override
  String get copy => 'ਕਾਪੀ';

  @override
  String get howItWorks => 'ਇਹ ਕਿਵੇਂ ਕੰਮ ਕਰਦਾ ਹੈ';

  @override
  String get referralDescription =>
      'ਆਪਣਾ ਕੋਡ ਦੋਸਤਾਂ ਨਾਲ ਸਾਂਝਾ ਕਰੋ। ਜਦੋਂ ਉਹ ਸ਼ਾਮਲ ਹੁੰਦੇ ਹਨ ਅਤੇ ਸਰਗਰਮ ਹੁੰਦੇ ਹਨ, ਤੁਸੀਂ ਆਪਣੀ ਟੀਮ ਨੂੰ ਵਧਾਉਂਦੇ ਹੋ ਅਤੇ ਆਪਣੀ ਕਮਾਈ ਦੀ ਸੰਭਾਵਨਾ ਨੂੰ ਬਿਹਤਰ ਬਣਾਉਂਦੇ ਹੋ।';

  @override
  String get yourTeam => 'ਤੁਹਾਡੀ ਟੀਮ';

  @override
  String get referralsTitle => 'ਰੈਫਰਲ';

  @override
  String get shareLinkTitle => 'ਲਿੰਕ ਸਾਂਝਾ ਕਰੋ';

  @override
  String get copyLinkInstruction => 'ਸਾਂਝਾ ਕਰਨ ਲਈ ਇਹ ਲਿੰਕ ਕਾਪੀ ਕਰੋ:';

  @override
  String get referralCodeCopied => 'ਰੈਫਰਲ ਕੋਡ ਕਾਪੀ ਹੋ ਗਿਆ';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network \'ਤੇ ਮੇਰੇ ਨਾਲ ਸ਼ਾਮਲ ਹੋਵੋ! ਮੇਰਾ ਕੋਡ ਵਰਤੋ: $code $link';
  }

  @override
  String get etaNetwork => 'ETA ਨੈੱਟਵਰਕ';

  @override
  String get noLiveCommunityCoins => 'ਕੋਈ ਲਾਈਵ ਕਮਿਊਨਿਟੀ ਸਿੱਕੇ ਨਹੀਂ';

  @override
  String get rate => 'ਦਰ';

  @override
  String get filterRandom => 'ਬੇਤਰਤੀਬ';

  @override
  String get baseRateLabel => 'ਅਧਾਰ ਦਰ';

  @override
  String startFailed(String error) {
    return 'ਸ਼ੁਰੂ ਅਸਫਲ: $error';
  }

  @override
  String get sessionProgress => 'ਸੈਸ਼ਨ ਦੀ ਪ੍ਰਗਤੀ';

  @override
  String get remainingLabel => 'ਬਾਕੀ';

  @override
  String get boostRate => 'ਬੂਸਟ ਦਰ';

  @override
  String get minedLabel => 'ਮਾਈਨ ਕੀਤਾ';

  @override
  String get noSubscriptionPlansAvailable => 'ਕੋਈ ਗਾਹਕੀ ਯੋਜਨਾਵਾਂ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get subscriptionPlans => 'ਗਾਹਕੀ ਯੋਜਨਾਵਾਂ';

  @override
  String get recommended => 'ਸਿਫਾਰਸ਼ ਕੀਤੀ';

  @override
  String get editCommunityCoin => 'ਕਮਿਊਨਿਟੀ ਸਿੱਕਾ ਸੰਪਾਦਿਤ ਕਰੋ';

  @override
  String get launchCoinEcosystemDescription =>
      'ਆਪਣੀ ਕਮਿਊਨਿਟੀ ਲਈ ETA ਈਕੋਸਿਸਟਮ ਦੇ ਅੰਦਰ ਆਪਣਾ ਸਿੱਕਾ ਲਾਂਚ ਕਰੋ।';

  @override
  String get upload => 'ਅਪਲੋਡ ਕਰੋ';

  @override
  String get recommendedImageSize => 'ਸਿਫਾਰਸ਼ ਕੀਤਾ 200×200px';

  @override
  String get coinNameLabel => 'ਸਿੱਕੇ ਦਾ ਨਾਮ';

  @override
  String get symbolLabel => 'ਪ੍ਰਤੀਕ';

  @override
  String get descriptionLabel => 'ਵੇਰਵਾ';

  @override
  String get baseMiningRateLabel => 'ਅਧਾਰ ਮਾਈਨਿੰਗ ਦਰ (ਸਿੱਕੇ/ਘੰਟਾ)';

  @override
  String maxAllowed(String max) {
    return 'ਵੱਧ ਤੋਂ ਵੱਧ ਆਗਿਆ: $max';
  }

  @override
  String get socialProjectLinksOptional => 'ਸੋਸ਼ਲ ਅਤੇ ਪ੍ਰੋਜੈਕਟ ਲਿੰਕ (ਵਿਕਲਪਿਕ)';

  @override
  String get linkTypeWebsite => 'ਵੈਬਸਾਈਟ';

  @override
  String get linkTypeYouTube => 'ਯੂਟਿਊਬ';

  @override
  String get linkTypeFacebook => 'ਫੇਸਬੁੱਕ';

  @override
  String get linkTypeTwitter => 'X / ਟਵਿੱਟਰ';

  @override
  String get linkTypeInstagram => 'ਇੰਸਟਾਗ੍ਰਾਮ';

  @override
  String get linkTypeTelegram => 'ਟੈਲੀਗ੍ਰਾਮ';

  @override
  String get linkTypeOther => 'ਹੋਰ';

  @override
  String get pasteUrl => 'URL ਪੇਸਟ ਕਰੋ';

  @override
  String get importantNoticeTitle => 'ਮਹੱਤਵਪੂਰਨ ਸੂਚਨਾ';

  @override
  String get importantNoticeBody =>
      'ਇਹ ਸਿੱਕਾ ETA ਨੈੱਟਵਰਕ ਈਕੋਸਿਸਟਮ ਦਾ ਹਿੱਸਾ ਹੈ ਅਤੇ ਵਧ ਰਹੀ ਡਿਜੀਟਲ ਕਮਿਊਨਿਟੀ ਵਿੱਚ ਭਾਗੀਦਾਰੀ ਦੀ ਨੁਮਾਇੰਦਗੀ ਕਰਦਾ ਹੈ। ਕਮਿਊਨਿਟੀ ਸਿੱਕੇ ਉਪਭੋਗਤਾਵਾਂ ਦੁਆਰਾ ਨੈੱਟਵਰਕ ਦੇ ਅੰਦਰ ਬਣਾਉਣ, ਤਜਰਬਾ ਕਰਨ ਅਤੇ ਸ਼ਾਮਲ ਹੋਣ ਲਈ ਬਣਾਏ ਜਾਂਦੇ ਹਨ। ETA ਨੈੱਟਵਰਕ ਵਿਕਾਸ ਦੇ ਸ਼ੁਰੂਆਤੀ ਪੜਾਅ ਵਿੱਚ ਹੈ। ਜਿਵੇਂ-ਜਿਵੇਂ ਈਕੋਸਿਸਟਮ ਵਧਦਾ ਹੈ, ਕਮਿਊਨਿਟੀ ਦੀ ਗਤੀਵਿਧੀ, ਪਲੇਟਫਾਰਮ ਦੇ ਵਿਕਾਸ ਅਤੇ ਲਾਗੂ ਦਿਸ਼ਾ-ਨਿਰਦੇਸ਼ਾਂ ਦੇ ਅਧਾਰ \'ਤੇ ਨਵੀਆਂ ਉਪਯੋਗਤਾਵਾਂ, ਵਿਸ਼ੇਸ਼ਤਾਵਾਂ ਅਤੇ ਏਕੀਕਰਣ ਪੇਸ਼ ਕੀਤੇ ਜਾ ਸਕਦੇ ਹਨ।';

  @override
  String get pleaseWait => 'ਕਿਰਪਾ ਕਰਕੇ ਉਡੀਕ ਕਰੋ...';

  @override
  String get save => 'ਸੇਵ ਕਰੋ';

  @override
  String createCoinFailed(String error) {
    return 'ਸਿੱਕਾ ਬਣਾਉਣ ਵਿੱਚ ਅਸਫਲ: $error';
  }

  @override
  String get coinNameLengthError =>
      'ਸਿੱਕੇ ਦਾ ਨਾਮ 3-30 ਅੱਖਰਾਂ ਦਾ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ।';

  @override
  String get symbolRequiredError => 'ਪ੍ਰਤੀਕ ਲੋੜੀਂਦਾ ਹੈ।';

  @override
  String get symbolLengthError => 'ਪ੍ਰਤੀਕ 2-6 ਅੱਖਰ/ਨੰਬਰ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ।';

  @override
  String get descriptionTooLongError => 'ਵੇਰਵਾ ਬਹੁਤ ਲੰਬਾ ਹੈ।';

  @override
  String baseRateRangeError(String max) {
    return 'ਅਧਾਰ ਮਾਈਨਿੰਗ ਦਰ 0.000000001 ਅਤੇ $max ਦੇ ਵਿਚਕਾਰ ਹੋਣੀ ਚਾਹੀਦੀ ਹੈ।';
  }

  @override
  String get coinNameExistsError =>
      'ਸਿੱਕੇ ਦਾ ਨਾਮ ਪਹਿਲਾਂ ਹੀ ਮੌਜੂਦ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਕੋਈ ਹੋਰ ਚੁਣੋ।';

  @override
  String get symbolExistsError =>
      'ਪ੍ਰਤੀਕ ਪਹਿਲਾਂ ਹੀ ਮੌਜੂਦ ਹੈ। ਕਿਰਪਾ ਕਰਕੇ ਕੋਈ ਹੋਰ ਚੁਣੋ।';

  @override
  String get urlInvalidError => 'ਇੱਕ URL ਗਲਤ ਹੈ।';

  @override
  String get subscribeAndBoost => 'ਗਾਹਕ ਬਣੋ ਅਤੇ ਮਾਈਨਿੰਗ ਵਧਾਓ';

  @override
  String get autoCollect => 'ਆਟੋ-ਕਲੈਕਟ';

  @override
  String autoMineCoins(int count) {
    return 'ਆਟੋ ਮਾਈਨ $count ਸਿੱਕੇ';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% ਗਤੀ';
  }

  @override
  String get perHourSuffix => '/ਘੰਟਾ';

  @override
  String get etaPerHourSuffix => 'ETA/ਘੰਟਾ';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'ਕੋਈ ਵੇਰਵਾ ਉਪਲਬਧ ਨਹੀਂ।';

  @override
  String get unknownUser => 'ਅਣਜਾਣ';

  @override
  String get streakLabel => 'ਲੜੀ';

  @override
  String get referralsLabel => 'ਰੈਫਰਲ';

  @override
  String get sessionsLabel => 'ਸੈਸ਼ਨ';

  @override
  String get accountInfoSection => 'ਖਾਤਾ ਜਾਣਕਾਰੀ';

  @override
  String get accountInfoTile => 'ਖਾਤਾ ਜਾਣਕਾਰੀ';

  @override
  String get invitedByPrompt => 'ਕਿਸੇ ਨੇ ਸੱਦਾ ਦਿੱਤਾ?';

  @override
  String get enterReferralCode => 'ਰੈਫਰਲ ਕੋਡ ਦਰਜ ਕਰੋ';

  @override
  String get invitedStatus => 'ਸੱਦਾ ਦਿੱਤਾ ਗਿਆ';

  @override
  String get lockedStatus => 'ਲਾਕ ਹੈ';

  @override
  String get applyButton => 'ਲਾਗੂ ਕਰੋ';

  @override
  String get aboutPageTitle => 'ਬਾਰੇ';

  @override
  String get faqTile => 'ਅਕਸਰ ਪੁੱਛੇ ਜਾਣ ਵਾਲੇ ਸਵਾਲ';

  @override
  String get whitePaperTile => 'ਵਾਈਟ ਪੇਪਰ';

  @override
  String get contactUsTile => 'ਸਾਡੇ ਨਾਲ ਸੰਪਰਕ ਕਰੋ';

  @override
  String get securitySettingsTile => 'ਸੁਰੱਖਿਆ ਸੈਟਿੰਗਾਂ';

  @override
  String get securitySettingsPageTitle => 'ਸੁਰੱਖਿਆ ਸੈਟਿੰਗਾਂ';

  @override
  String get deleteAccountTile => 'ਖਾਤਾ ਮਿਟਾਓ';

  @override
  String get deleteAccountSubtitle => 'ਆਪਣਾ ਖਾਤਾ ਅਤੇ ਡਾਟਾ ਸਥਾਈ ਤੌਰ \'ਤੇ ਮਿਟਾਓ';

  @override
  String get deleteAccountDialogTitle => 'ਖਾਤਾ ਮਿਟਾਓ?';

  @override
  String get deleteAccountDialogContent =>
      'ਇਹ ਤੁਹਾਡੇ ਖਾਤੇ, ਡਾਟਾ ਅਤੇ ਸੈਸ਼ਨਾਂ ਨੂੰ ਸਥਾਈ ਤੌਰ \'ਤੇ ਮਿਟਾ ਦੇਵੇਗਾ। ਇਹ ਕਾਰਵਾਈ ਵਾਪਸ ਨਹੀਂ ਕੀਤੀ ਜਾ ਸਕਦੀ।';

  @override
  String get deleteButton => 'ਮਿਟਾਓ';

  @override
  String get kycVerificationTile => 'KYC ਪੁਸ਼ਟੀਕਰਨ';

  @override
  String get kycVerificationDialogTitle => 'KYC ਪੁਸ਼ਟੀਕਰਨ';

  @override
  String get kycComingSoonMessage =>
      'ਆਉਣ ਵਾਲੇ ਪੜਾਵਾਂ ਵਿੱਚ ਕਿਰਿਆਸ਼ੀਲ ਕੀਤਾ ਜਾਵੇਗਾ।';

  @override
  String get okButton => 'ਠੀਕ ਹੈ';

  @override
  String get logOutLabel => 'ਲਾਗ ਆਉਟ';

  @override
  String get confirmDeletionTitle => 'ਮਿਟਾਉਣ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ';

  @override
  String get enterAccountPassword => 'ਖਾਤਾ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ';

  @override
  String get confirmButton => 'ਪੁਸ਼ਟੀ ਕਰੋ';

  @override
  String get usernameLabel => 'ਯੂਜ਼ਰਨਾਮ';

  @override
  String get emailLabel => 'ਈਮੇਲ';

  @override
  String get nameLabel => 'ਨਾਮ';

  @override
  String get ageLabel => 'ਉਮਰ';

  @override
  String get countryLabel => 'ਦੇਸ਼';

  @override
  String get addressLabel => 'ਪਤਾ';

  @override
  String get genderLabel => 'ਲਿੰਗ';

  @override
  String get enterUsernameHint => 'ਯੂਜ਼ਰਨਾਮ ਦਰਜ ਕਰੋ';

  @override
  String get enterNameHint => 'ਨਾਮ ਦਰਜ ਕਰੋ';

  @override
  String get enterAgeHint => 'ਉਮਰ ਦਰਜ ਕਰੋ';

  @override
  String get enterCountryHint => 'ਦੇਸ਼ ਦਰਜ ਕਰੋ';

  @override
  String get enterAddressHint => 'ਪਤਾ ਦਰਜ ਕਰੋ';

  @override
  String get enterGenderHint => 'ਲਿੰਗ ਦਰਜ ਕਰੋ';

  @override
  String get savingLabel => 'ਸੇਵ ਹੋ ਰਿਹਾ ਹੈ...';

  @override
  String get usernameEmptyError => 'ਯੂਜ਼ਰਨਾਮ ਖਾਲੀ ਨਹੀਂ ਹੋ ਸਕਦਾ';

  @override
  String get invalidAgeError => 'ਗਲਤ ਉਮਰ ਮੁੱਲ';

  @override
  String get saveError => 'ਤਬਦੀਲੀਆਂ ਸੇਵ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get cancelButton => 'ਰੱਦ ਕਰੋ';
}
