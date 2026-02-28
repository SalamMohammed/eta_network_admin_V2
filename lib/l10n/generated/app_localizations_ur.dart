// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get totalBalance => 'کل بیلنس';

  @override
  String joinedDate(String link, Object date) {
    return '$date کو شامل ہوا';
  }

  @override
  String get inviteEarn => 'مدعو کریں اور کمائیں';

  @override
  String get shareCodeDescription =>
      'اپنی کان کنی کی شرح بڑھانے کے لیے اپنا منفرد کوڈ دوستوں کے ساتھ شیئر کریں۔';

  @override
  String get shareLink => 'لنک شیئر کریں';

  @override
  String get totalInvited => 'کل مدعو کردہ';

  @override
  String get activeNow => 'ابھی فعال';

  @override
  String get viewAll => 'سب دیکھیں';

  @override
  String get createCoin => 'سکہ بنائیں';

  @override
  String get mining => 'کان کنی';

  @override
  String get settings => 'ترتیبات';

  @override
  String get language => 'زبان';

  @override
  String get languageSubtitle => 'ایپ کی زبان تبدیل کریں';

  @override
  String get selectLanguage => 'زبان منتخب کریں';

  @override
  String get balanceTitle => 'بیلنس';

  @override
  String get home => 'ہوم';

  @override
  String get referral => 'ریفرل';

  @override
  String get profile => 'پروفائل';

  @override
  String get dayStreak => 'دن کا سلسلہ';

  @override
  String dayStreakValue(int count) {
    return '$count دن کا سلسلہ';
  }

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیر فعال';

  @override
  String get sessionEndsIn => 'سیشن ختم ہونے میں';

  @override
  String get startEarning => 'کمانا شروع کریں';

  @override
  String get loadingAd => 'اشتہار لوڈ ہو رہا ہے...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds سیکنڈ انتظار کریں';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'انعام +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'انعام یافتہ اشتہار دستیاب نہیں ہے';

  @override
  String rateBoosted(String rate) {
    return 'شرح میں اضافہ: +$rate ETA/گھنٹہ';
  }

  @override
  String adBonusFailed(String message) {
    return 'اشتہار کا بونس ناکام: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'شرح کی تفصیل: بنیادی $base، سلسلہ +$streak، درجہ +$rank، ریفرلز +$referrals = $total ETA/گھنٹہ';
  }

  @override
  String get unableToStartMining =>
      'کان کنی شروع کرنے سے قاصر۔ براہ کرم اپنا انٹرنیٹ کنکشن چیک کریں اور دوبارہ کوشش کریں۔';

  @override
  String get createCommunityCoin => 'کمیونٹی کوائن بنائیں';

  @override
  String get launchCoinDescription =>
      'ETA نیٹ ورک پر اپنا سکہ فوری طور پر لانچ کریں۔';

  @override
  String get createYourOwnCoin => 'اپنا سکہ بنائیں';

  @override
  String get launchCommunityCoinDescription =>
      'اپنا کمیونٹی کوائن لانچ کریں جسے دوسرے ETA صارفین مائن کر سکیں۔';

  @override
  String get editCoin => 'سکے میں ترمیم کریں';

  @override
  String baseRate(String rate) {
    return 'بنیادی شرح: $rate سکے/گھنٹہ';
  }

  @override
  String createdBy(String username) {
    return 'تخلیق کردہ @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/گھنٹہ';
  }

  @override
  String get noCoinsYet =>
      'ابھی تک کوئی سکے نہیں ہیں۔ لائیو کوائنز سے شامل کریں۔';

  @override
  String get mine => 'مائن';

  @override
  String get remaining => 'باقی';

  @override
  String get holders => 'ہولڈرز';

  @override
  String get close => 'بند کریں';

  @override
  String get readMore => 'مزید پڑھیں';

  @override
  String get readLess => 'کم پڑھیں';

  @override
  String get projectLinks => 'پروجیکٹ لنکس';

  @override
  String get verifyEmailTitle => 'اپنے ای میل کی تصدیق کریں';

  @override
  String get verifyEmailMessage =>
      'ہم نے آپ کے ای میل ایڈریس پر تصدیقی لنک بھیجا ہے۔ تمام خصوصیات کو غیر مقفل کرنے کے لیے براہ کرم اپنے اکاؤنٹ کی تصدیق کریں۔';

  @override
  String get resendEmail => 'ای میل دوبارہ بھیجیں';

  @override
  String get iHaveVerified => 'میں نے تصدیق کر لی ہے';

  @override
  String get logout => 'لاگ آؤٹ';

  @override
  String get emailVerifiedSuccess => 'ای میل کی کامیابی سے تصدیق ہو گئی!';

  @override
  String get emailNotVerified =>
      'ای میل کی ابھی تک تصدیق نہیں ہوئی ہے۔ براہ کرم اپنا ان باکس چیک کریں۔';

  @override
  String get verificationEmailSent => 'تصدیقی ای میل بھیج دی گئی';

  @override
  String get startMining => 'کان کنی شروع کریں';

  @override
  String get minedCoins => 'مائن شدہ سکے';

  @override
  String get liveCoins => 'لائیو کوائنز';

  @override
  String get asset => 'اثاثہ';

  @override
  String get filterStatus => 'حیثیت';

  @override
  String get filterPopular => 'مقبول';

  @override
  String get filterNames => 'نام';

  @override
  String get filterOldNew => 'پرانا - نیا';

  @override
  String get filterNewOld => 'نیا - پرانا';

  @override
  String startMiningWithCount(int count) {
    return 'کان کنی شروع کریں ($count)';
  }

  @override
  String get clearSelection => 'انتخاب صاف کریں';

  @override
  String get cancel => 'منسوخ کریں';

  @override
  String get refreshStatus => 'حیثیت کو تازہ کریں';

  @override
  String get purchaseFailed => 'خریداری ناکام';

  @override
  String get securePaymentViaGooglePlay => 'گوگل پلے کے ذریعے محفوظ ادائیگی';

  @override
  String get addedToMinedCoins => 'مائن شدہ سکوں میں شامل کر دیا گیا';

  @override
  String failedToAdd(String message) {
    return 'شامل کرنے میں ناکام: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'سبسکرپشنز صرف اینڈرائیڈ/آئی او ایس پر دستیاب ہیں۔';

  @override
  String get miningRate => 'کان کنی کی شرح';

  @override
  String get about => 'کے بارے میں';

  @override
  String get yourMined => 'آپ کا مائن شدہ';

  @override
  String get totalMined => 'کل مائن شدہ';

  @override
  String get noReferrals => 'ابھی تک کوئی ریفرل نہیں';

  @override
  String get linkCopied => 'لنک کاپی ہو گیا';

  @override
  String get copy => 'کاپی';

  @override
  String get howItWorks => 'یہ کیسے کام کرتا ہے';

  @override
  String get referralDescription =>
      'اپنا کوڈ دوستوں کے ساتھ شیئر کریں۔ جب وہ شامل ہوں گے اور فعال ہوں گے، آپ اپنی ٹیم کو بڑھائیں گے اور اپنی کمائی کی صلاحیت کو بہتر بنائیں گے۔';

  @override
  String get yourTeam => 'آپ کی ٹیم';

  @override
  String get referralsTitle => 'ریفرلز';

  @override
  String get shareLinkTitle => 'لنک شیئر کریں';

  @override
  String get copyLinkInstruction => 'شیئر کرنے کے لیے یہ لنک کاپی کریں:';

  @override
  String get referralCodeCopied => 'ریفرل کوڈ کاپی ہو گیا';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network پر میرے ساتھ شامل ہوں! میرا کوڈ استعمال کریں: $code $link';
  }

  @override
  String get etaNetwork => 'ETA نیٹ ورک';

  @override
  String get noLiveCommunityCoins => 'کوئی لائیو کمیونٹی کوائنز نہیں';

  @override
  String get rate => 'شرح';

  @override
  String get filterRandom => 'بے ترتیب';

  @override
  String get baseRateLabel => 'بنیادی شرح';

  @override
  String startFailed(String error) {
    return 'شروع ناکام: $error';
  }

  @override
  String get sessionProgress => 'سیشن کی پیشرفت';

  @override
  String get remainingLabel => 'باقی';

  @override
  String get boostRate => 'بوسٹ ریٹ';

  @override
  String get minedLabel => 'مائن شدہ';

  @override
  String get noSubscriptionPlansAvailable => 'کوئی سبسکرپشن پلان دستیاب نہیں';

  @override
  String get subscriptionPlans => 'سبسکرپشن پلانز';

  @override
  String get recommended => 'تجویز کردہ';

  @override
  String get editCommunityCoin => 'کمیونٹی کوائن میں ترمیم کریں';

  @override
  String get launchCoinEcosystemDescription =>
      'اپنی کمیونٹی کے لیے ETA ایکو سسٹم کے اندر اپنا سکہ لانچ کریں۔';

  @override
  String get upload => 'اپ لوڈ کریں';

  @override
  String get recommendedImageSize => 'تجویز کردہ 200×200px';

  @override
  String get coinNameLabel => 'سکے کا نام';

  @override
  String get symbolLabel => 'علامت';

  @override
  String get descriptionLabel => 'تفصیل';

  @override
  String get baseMiningRateLabel => 'بنیادی کان کنی کی شرح (سکے/گھنٹہ)';

  @override
  String maxAllowed(String max) {
    return 'زیادہ سے زیادہ اجازت: $max';
  }

  @override
  String get socialProjectLinksOptional => 'سماجی اور پروجیکٹ لنکس (اختیاری)';

  @override
  String get linkTypeWebsite => 'ویب سائٹ';

  @override
  String get linkTypeYouTube => 'یوٹیوب';

  @override
  String get linkTypeFacebook => 'فیس بک';

  @override
  String get linkTypeTwitter => 'X / ٹویٹر';

  @override
  String get linkTypeInstagram => 'انسٹاگرام';

  @override
  String get linkTypeTelegram => 'ٹیلی گرام';

  @override
  String get linkTypeOther => 'دیگر';

  @override
  String get pasteUrl => 'یو آر ایل پیسٹ کریں';

  @override
  String get importantNoticeTitle => 'اہم نوٹس';

  @override
  String get importantNoticeBody =>
      'یہ سکہ ETA نیٹ ورک ایکو سسٹم کا حصہ ہے اور بڑھتی ہوئی ڈیجیٹل کمیونٹی میں شرکت کی نمائندگی کرتا ہے۔ کمیونٹی کوائنز صارفین کے ذریعہ نیٹ ورک کے اندر تعمیر، تجربہ اور مشغول ہونے کے لیے بنائے جاتے ہیں۔ ETA نیٹ ورک ترقی کے ابتدائی مرحلے میں ہے۔ جیسے جیسے ایکو سسٹم بڑھتا ہے، کمیونٹی کی سرگرمی، پلیٹ فارم کے ارتقاء اور قابل اطلاق رہنما خطوط کی بنیاد پر نئی افادیت، خصوصیات اور انضمام متعارف کرائے جا سکتے ہیں۔';

  @override
  String get pleaseWait => 'براہ کرم انتظار کریں...';

  @override
  String get save => 'محفوظ کریں';

  @override
  String createCoinFailed(String error) {
    return 'سکہ بنانے میں ناکام: $error';
  }

  @override
  String get coinNameLengthError => 'سکے کا نام 3-30 حروف کا ہونا چاہیے۔';

  @override
  String get symbolRequiredError => 'علامت درکار ہے۔';

  @override
  String get symbolLengthError => 'علامت 2-6 حروف/نمبر ہونی چاہیے۔';

  @override
  String get descriptionTooLongError => 'تفصیل بہت لمبی ہے۔';

  @override
  String baseRateRangeError(String max) {
    return 'بنیادی کان کنی کی شرح 0.000000001 اور $max کے درمیان ہونی چاہیے۔';
  }

  @override
  String get coinNameExistsError =>
      'سکے کا نام پہلے سے موجود ہے۔ براہ کرم کوئی اور منتخب کریں۔';

  @override
  String get symbolExistsError =>
      'علامت پہلے سے موجود ہے۔ براہ کرم کوئی اور منتخب کریں۔';

  @override
  String get urlInvalidError => 'یو آر ایل میں سے ایک غلط ہے۔';

  @override
  String get subscribeAndBoost => 'سبسکرائب کریں اور کان کنی کو فروغ دیں';

  @override
  String get autoCollect => 'خودکار جمع';

  @override
  String autoMineCoins(int count) {
    return 'خودکار مائن $count سکے';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% رفتار';
  }

  @override
  String get perHourSuffix => '/گھنٹہ';

  @override
  String get etaPerHourSuffix => 'ETA/گھنٹہ';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'کوئی تفصیل دستیاب نہیں۔';

  @override
  String get unknownUser => 'نامعلوم';

  @override
  String get streakLabel => 'سلسلہ';

  @override
  String get referralsLabel => 'ریفرلز';

  @override
  String get sessionsLabel => 'سیشنز';

  @override
  String get accountInfoSection => 'اکاؤنٹ کی معلومات';

  @override
  String get accountInfoTile => 'اکاؤنٹ کی معلومات';

  @override
  String get invitedByPrompt => 'کسی نے مدعو کیا؟';

  @override
  String get enterReferralCode => 'ریفرل کوڈ درج کریں';

  @override
  String get invitedStatus => 'مدعو کیا گیا';

  @override
  String get lockedStatus => 'مقفل';

  @override
  String get applyButton => 'لاگو کریں';

  @override
  String get aboutPageTitle => 'کے بارے میں';

  @override
  String get faqTile => 'عمومی سوالات';

  @override
  String get whitePaperTile => 'وائٹ پیپر';

  @override
  String get contactUsTile => 'ہم سے رابطہ کریں';

  @override
  String get securitySettingsTile => 'حفاظتی ترتیبات';

  @override
  String get securitySettingsPageTitle => 'حفاظتی ترتیبات';

  @override
  String get deleteAccountTile => 'اکاؤنٹ حذف کریں';

  @override
  String get deleteAccountSubtitle =>
      'اپنا اکاؤنٹ اور ڈیٹا مستقل طور پر حذف کریں';

  @override
  String get deleteAccountDialogTitle => 'اکاؤنٹ حذف کریں؟';

  @override
  String get deleteAccountDialogContent =>
      'یہ آپ کے اکاؤنٹ، ڈیٹا اور سیشنز کو مستقل طور پر حذف کر دے گا۔ یہ عمل واپس نہیں کیا جا سکتا۔';

  @override
  String get deleteButton => 'حذف کریں';

  @override
  String get kycVerificationTile => 'KYC تصدیق';

  @override
  String get kycVerificationDialogTitle => 'KYC تصدیق';

  @override
  String get kycComingSoonMessage => 'آنے والے مراحل میں فعال کیا جائے گا۔';

  @override
  String get okButton => 'ٹھیک ہے';

  @override
  String get logOutLabel => 'لاگ آؤٹ';

  @override
  String get confirmDeletionTitle => 'حذف کرنے کی تصدیق کریں';

  @override
  String get enterAccountPassword => 'اکاؤنٹ کا پاس ورڈ درج کریں';

  @override
  String get confirmButton => 'تصدیق کریں';

  @override
  String get usernameLabel => 'صارف کا نام';

  @override
  String get emailLabel => 'ای میل';

  @override
  String get nameLabel => 'نام';

  @override
  String get ageLabel => 'عمر';

  @override
  String get countryLabel => 'ملک';

  @override
  String get addressLabel => 'پتہ';

  @override
  String get genderLabel => 'جنس';

  @override
  String get enterUsernameHint => 'صارف کا نام درج کریں';

  @override
  String get enterNameHint => 'نام درج کریں';

  @override
  String get enterAgeHint => 'عمر درج کریں';

  @override
  String get enterCountryHint => 'ملک درج کریں';

  @override
  String get enterAddressHint => 'پتہ درج کریں';

  @override
  String get enterGenderHint => 'جنس درج کریں';

  @override
  String get savingLabel => 'محفوظ ہو رہا ہے...';

  @override
  String get usernameEmptyError => 'صارف کا نام خالی نہیں ہو سکتا';

  @override
  String get invalidAgeError => 'غلط عمر کی قدر';

  @override
  String get saveError => 'تبدیلیاں محفوظ کرنے میں ناکام';

  @override
  String get cancelButton => 'منسوخ کریں';
}
