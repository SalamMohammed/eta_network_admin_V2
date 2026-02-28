// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Pushto Pashto (`ps`).
class AppLocalizationsPs extends AppLocalizations {
  AppLocalizationsPs([String locale = 'ps']) : super(locale);

  @override
  String get totalBalance => 'ټوله پانګه';

  @override
  String joinedDate(String link, Object date) {
    return 'په $date کې یوځای شو';
  }

  @override
  String get inviteEarn => 'بلنه ورکړئ او وګټئ';

  @override
  String get shareCodeDescription =>
      'د خپل کان کیندنې کچه لوړولو لپاره خپل ځانګړی کوډ د ملګرو سره شریک کړئ.';

  @override
  String get shareLink => 'لینک شریک کړئ';

  @override
  String get totalInvited => 'ټول بلل شوي';

  @override
  String get activeNow => 'اوس فعال';

  @override
  String get viewAll => 'ټول وګورئ';

  @override
  String get createCoin => 'سکه جوړه کړئ';

  @override
  String get mining => 'کان کیندنه';

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'ژبه';

  @override
  String get languageSubtitle => 'د اپلیکیشن ژبه بدل کړئ';

  @override
  String get selectLanguage => 'ژبه وټاکئ';

  @override
  String get balanceTitle => 'بیلنس';

  @override
  String get home => 'کور';

  @override
  String get referral => 'ریفرل';

  @override
  String get profile => 'پروفایل';

  @override
  String get dayStreak => 'د ورځې لړۍ';

  @override
  String dayStreakValue(int count) {
    return '$count ورځ لړۍ';
  }

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیر فعال';

  @override
  String get sessionEndsIn => 'ناسته پای ته رسیږي په';

  @override
  String get startEarning => 'ګټل پیل کړئ';

  @override
  String get loadingAd => 'اعلان بار کیږي...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds ثانیې انتظار وکړئ';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'انعام +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'انعام لرونکی اعلان شتون نلري';

  @override
  String rateBoosted(String rate) {
    return 'کچه لوړه شوې: +$rate ETA/ساعت';
  }

  @override
  String adBonusFailed(String message) {
    return 'د اعلان بونس ناکام شو: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'د نرخ تفصیل: اساس $base، لړۍ +$streak، رتبه +$rank، ریفرل +$referrals = $total ETA/ساعت';
  }

  @override
  String get unableToStartMining =>
      'د کان کیندنې پیل کولو توان نلري. مهرباني وکړئ خپل انټرنیټ پیوستون وګورئ او بیا هڅه وکړئ.';

  @override
  String get createCommunityCoin => 'د ټولنې سکه جوړه کړئ';

  @override
  String get launchCoinDescription => 'په ETA شبکه کې خپله سکه سمدستي پیل کړئ.';

  @override
  String get createYourOwnCoin => 'خپله سکه جوړه کړئ';

  @override
  String get launchCommunityCoinDescription =>
      'خپله د ټولنې سکه پیل کړئ چې نور ETA کاروونکي یې کان کیندلی شي.';

  @override
  String get editCoin => 'سکه سم کړئ';

  @override
  String baseRate(String rate) {
    return 'بنسټیز نرخ: $rate سکې/ساعت';
  }

  @override
  String createdBy(String username) {
    return 'د @$username لخوا جوړ شوی';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ساعت';
  }

  @override
  String get noCoinsYet => 'تر اوسه هیڅ سکې نشته. د ژوندی سکې څخه اضافه کړئ.';

  @override
  String get mine => 'کان کیندنه';

  @override
  String get remaining => 'پاتې';

  @override
  String get holders => 'لرونکي';

  @override
  String get close => 'بند کړئ';

  @override
  String get readMore => 'نور ولولئ';

  @override
  String get readLess => 'لږ ولولئ';

  @override
  String get projectLinks => 'د پروژې لینکونه';

  @override
  String get verifyEmailTitle => 'خپل بریښنالیک تایید کړئ';

  @override
  String get verifyEmailMessage =>
      'موږ ستاسو بریښنالیک ته د تایید لینک لیږلی دی. مهرباني وکړئ د ټولو ځانګړتیاو خلاصولو لپاره خپل حساب تایید کړئ.';

  @override
  String get resendEmail => 'بریښنالیک بیا ولېږئ';

  @override
  String get iHaveVerified => 'ما تایید کړی دی';

  @override
  String get logout => 'لاګ آوټ';

  @override
  String get emailVerifiedSuccess => 'بریښنالیک په بریالیتوب سره تایید شو!';

  @override
  String get emailNotVerified =>
      'بریښنالیک لاهم تایید شوی نه دی. مهرباني وکړئ خپل ان باکس وګورئ.';

  @override
  String get verificationEmailSent => 'د تایید بریښنالیک لیږل شوی';

  @override
  String get startMining => 'کان کیندنه پیل کړئ';

  @override
  String get minedCoins => 'استخراج شوي سکې';

  @override
  String get liveCoins => 'ژوندي سکې';

  @override
  String get asset => 'شتمني';

  @override
  String get filterStatus => 'حالت';

  @override
  String get filterPopular => 'مشهور';

  @override
  String get filterNames => 'نومونه';

  @override
  String get filterOldNew => 'زوړ - نوی';

  @override
  String get filterNewOld => 'نوی - زوړ';

  @override
  String startMiningWithCount(int count) {
    return 'کان کیندنه پیل کړئ ($count)';
  }

  @override
  String get clearSelection => 'انتخاب پاک کړئ';

  @override
  String get cancel => 'لغوه کړئ';

  @override
  String get refreshStatus => 'حالت تازه کړئ';

  @override
  String get purchaseFailed => 'پیرود ناکام شو';

  @override
  String get securePaymentViaGooglePlay => 'د ګوګل پلی له لارې خوندي تادیه';

  @override
  String get addedToMinedCoins => 'په استخراج شوي سکو کې اضافه شو';

  @override
  String failedToAdd(String message) {
    return 'اضافه کول ناکام شول: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'ګډون یوازې په Android/iOS کې شتون لري.';

  @override
  String get miningRate => 'د کان کیندنې کچه';

  @override
  String get about => 'په اړه';

  @override
  String get yourMined => 'ستاسو استخراج شوی';

  @override
  String get totalMined => 'ټول استخراج شوي';

  @override
  String get noReferrals => 'تر اوسه هیڅ ریفرل نشته';

  @override
  String get linkCopied => 'لینک کاپي شو';

  @override
  String get copy => 'کاپي';

  @override
  String get howItWorks => 'دا څنګه کار کوي';

  @override
  String get referralDescription =>
      'خپل کوډ د ملګرو سره شریک کړئ. کله چې دوی یوځای شي او فعال شي، تاسو خپله ډله وده کوئ او د ګټلو وړتیا مو ښه کوئ.';

  @override
  String get yourTeam => 'ستاسو ټیم';

  @override
  String get referralsTitle => 'ریفرلونه';

  @override
  String get shareLinkTitle => 'لینک شریک کړئ';

  @override
  String get copyLinkInstruction => 'د شریکولو لپاره دا لینک کاپي کړئ:';

  @override
  String get referralCodeCopied => 'د ریفرل کوډ کاپي شو';

  @override
  String joinMeText(String code, String link) {
    return 'په Eta شبکه کې زما سره یوځای شئ! زما کوډ وکاروئ: $code $link';
  }

  @override
  String get etaNetwork => 'د ETA شبکه';

  @override
  String get noLiveCommunityCoins => 'هیچ د ټولنې سکې ژوندۍ نه دي';

  @override
  String get rate => 'کچه';

  @override
  String get filterRandom => 'تصادفي';

  @override
  String get baseRateLabel => 'بنسټیز نرخ';

  @override
  String startFailed(String error) {
    return 'پیل ناکام شو: $error';
  }

  @override
  String get sessionProgress => 'د ناستې پرمختګ';

  @override
  String get remainingLabel => 'پاتې';

  @override
  String get boostRate => 'د ودې کچه';

  @override
  String get minedLabel => 'استخراج شوی';

  @override
  String get noSubscriptionPlansAvailable => 'د ګډون هیڅ پلان شتون نلري';

  @override
  String get subscriptionPlans => 'د ګډون پلانونه';

  @override
  String get recommended => 'وړاندیز شوی';

  @override
  String get editCommunityCoin => 'د ټولنې سکه ایډیټ کړئ';

  @override
  String get launchCoinEcosystemDescription =>
      'خپله سکه د ETA ایکوسیستم کې دننه د خپلې ټولنې لپاره پیل کړئ.';

  @override
  String get upload => 'اپلوډ';

  @override
  String get recommendedImageSize => 'وړاندیز شوی 200×200px';

  @override
  String get coinNameLabel => 'د سکې نوم';

  @override
  String get symbolLabel => 'سمبول';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get baseMiningRateLabel => 'د کان کیندنې بنسټیز نرخ (سکې/ساعت)';

  @override
  String maxAllowed(String max) {
    return 'اعظمي اجازه: $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'ټولنیز او د پروژې لینکونه (اختیاري)';

  @override
  String get linkTypeWebsite => 'ویب پاڼه';

  @override
  String get linkTypeYouTube => 'یوټیوب';

  @override
  String get linkTypeFacebook => 'فیسبوک';

  @override
  String get linkTypeTwitter => 'X / ټویټر';

  @override
  String get linkTypeInstagram => 'انسټاګرام';

  @override
  String get linkTypeTelegram => 'ټیلیګرام';

  @override
  String get linkTypeOther => 'نور';

  @override
  String get pasteUrl => 'URL پیسټ کړئ';

  @override
  String get importantNoticeTitle => 'مهم خبرتیا';

  @override
  String get importantNoticeBody =>
      'دا سکه د ETA شبکې ایکوسیستم برخه ده او په مخ پر ودې ډیجیټل ټولنه کې د ګډون استازیتوب کوي. د ټولنې سکې د کاروونکو لخوا د شبکې دننه جوړولو، تجربه کولو او ښکیل کیدو لپاره رامینځته کیږي. د ETA شبکه د پراختیا په لومړیو مرحلو کې ده. لکه څنګه چې ایکوسیستم وده کوي، نوي اسانتیاوې، ځانګړتیاوې او ادغامونه ممکن د ټولنې فعالیت، پلیټ فارم ارتقاء او پلي کیدونکو لارښوونو پراساس معرفي شي.';

  @override
  String get pleaseWait => 'مهرباني وکړئ انتظار وکړئ...';

  @override
  String get save => 'خوندي کړئ';

  @override
  String createCoinFailed(String error) {
    return 'د سکې جوړول ناکام شول: $error';
  }

  @override
  String get coinNameLengthError => 'د سکې نوم باید 3-30 حروف وي.';

  @override
  String get symbolRequiredError => 'سمبول اړین دی.';

  @override
  String get symbolLengthError => 'سمبول باید 2-6 حروف/شمیرې وي.';

  @override
  String get descriptionTooLongError => 'تفصیل ډیر اوږد دی.';

  @override
  String baseRateRangeError(String max) {
    return 'د کان کیندنې بنسټیز نرخ باید د 0.000000001 او $max ترمنځ وي.';
  }

  @override
  String get coinNameExistsError =>
      'د سکې نوم لا دمخه شتون لري. مهرباني وکړئ بل غوره کړئ.';

  @override
  String get symbolExistsError =>
      'سمبول لا دمخه شتون لري. مهرباني وکړئ بل غوره کړئ.';

  @override
  String get urlInvalidError => 'یو URL غلط دی.';

  @override
  String get subscribeAndBoost => 'ګډون وکړئ او کان کیندنه وده ورکړئ';

  @override
  String get autoCollect => 'اټومات راټولول';

  @override
  String autoMineCoins(int count) {
    return 'اټومات کان کیندنه $count سکې';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% سرعت';
  }

  @override
  String get perHourSuffix => '/ساعت';

  @override
  String get etaPerHourSuffix => 'ETA/ساعت';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'هیڅ تفصیل شتون نلري.';

  @override
  String get unknownUser => 'نامعلوم';

  @override
  String get streakLabel => 'لړۍ';

  @override
  String get referralsLabel => 'ریفرلونه';

  @override
  String get sessionsLabel => 'ناستې';

  @override
  String get accountInfoSection => 'د حساب معلومات';

  @override
  String get accountInfoTile => 'د حساب معلومات';

  @override
  String get invitedByPrompt => 'چا بلنه ورکړې؟';

  @override
  String get enterReferralCode => 'د ریفرل کوډ دننه کړئ';

  @override
  String get invitedStatus => 'بلنه ورکړل شوې';

  @override
  String get lockedStatus => 'لاک شوی';

  @override
  String get applyButton => 'تطبیق کړئ';

  @override
  String get aboutPageTitle => 'په اړه';

  @override
  String get faqTile => 'پوښتل شوي پوښتنې';

  @override
  String get whitePaperTile => 'سپین کاغذ';

  @override
  String get contactUsTile => 'موږ سره اړیکه ونیسئ';

  @override
  String get securitySettingsTile => 'امنیتي ترتیبات';

  @override
  String get securitySettingsPageTitle => 'امنیتي ترتیبات';

  @override
  String get deleteAccountTile => 'حساب حذف کړئ';

  @override
  String get deleteAccountSubtitle => 'خپل حساب او ډاټا د تل لپاره حذف کړئ';

  @override
  String get deleteAccountDialogTitle => 'حساب حذف کړئ؟';

  @override
  String get deleteAccountDialogContent =>
      'دا به ستاسو حساب، ډاټا او ناستې د تل لپاره حذف کړي. دا عمل بیرته نه راګرځیدونکی دی.';

  @override
  String get deleteButton => 'حذف کړئ';

  @override
  String get kycVerificationTile => 'KYC تایید';

  @override
  String get kycVerificationDialogTitle => 'KYC تایید';

  @override
  String get kycComingSoonMessage => 'په راتلونکو مرحلو کې به فعال شي.';

  @override
  String get okButton => 'سمه ده';

  @override
  String get logOutLabel => 'لاګ آوټ';

  @override
  String get confirmDeletionTitle => 'د حذف کولو تایید وکړئ';

  @override
  String get enterAccountPassword => 'د حساب پاسورډ دننه کړئ';

  @override
  String get confirmButton => 'تایید کړئ';

  @override
  String get usernameLabel => 'کارن نوم';

  @override
  String get emailLabel => 'بریښنالیک';

  @override
  String get nameLabel => 'نوم';

  @override
  String get ageLabel => 'عمر';

  @override
  String get countryLabel => 'هیواد';

  @override
  String get addressLabel => 'پته';

  @override
  String get genderLabel => 'جنس';

  @override
  String get enterUsernameHint => 'کارن نوم دننه کړئ';

  @override
  String get enterNameHint => 'نوم دننه کړئ';

  @override
  String get enterAgeHint => 'عمر دننه کړئ';

  @override
  String get enterCountryHint => 'هیواد دننه کړئ';

  @override
  String get enterAddressHint => 'پته دننه کړئ';

  @override
  String get enterGenderHint => 'جنس دننه کړئ';

  @override
  String get savingLabel => 'خوندي کیږي...';

  @override
  String get usernameEmptyError => 'کارن نوم خالي نشي کیدی';

  @override
  String get invalidAgeError => 'د عمر ارزښت غلط دی';

  @override
  String get saveError => 'بدلونونه خوندي کولو کې پاتې راغلي';

  @override
  String get cancelButton => 'لغوه کړئ';
}
