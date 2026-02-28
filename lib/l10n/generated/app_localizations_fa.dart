// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get totalBalance => 'موجودی کل';

  @override
  String joinedDate(String link, Object date) {
    return 'عضویت در $date';
  }

  @override
  String get inviteEarn => 'دعوت و کسب درآمد';

  @override
  String get shareCodeDescription =>
      'کد منحصر به فرد خود را با دوستان به اشتراک بگذارید تا نرخ استخراج خود را افزایش دهید.';

  @override
  String get shareLink => 'اشتراک گذاری لینک';

  @override
  String get totalInvited => 'کل دعوت شده‌ها';

  @override
  String get activeNow => 'فعال اکنون';

  @override
  String get viewAll => 'مشاهده همه';

  @override
  String get createCoin => 'ایجاد سکه';

  @override
  String get mining => 'استخراج';

  @override
  String get settings => 'تنظیمات';

  @override
  String get language => 'زبان';

  @override
  String get languageSubtitle => 'تغییر زبان برنامه';

  @override
  String get selectLanguage => 'انتخاب زبان';

  @override
  String get balanceTitle => 'موجودی';

  @override
  String get home => 'خانه';

  @override
  String get referral => 'ارجاع';

  @override
  String get profile => 'پروفایل';

  @override
  String get dayStreak => 'زنجیره روزانه';

  @override
  String dayStreakValue(int count) {
    return '$count روز متوالی';
  }

  @override
  String get active => 'فعال';

  @override
  String get inactive => 'غیرفعال';

  @override
  String get sessionEndsIn => 'پایان جلسه در';

  @override
  String get startEarning => 'شروع کسب درآمد';

  @override
  String get loadingAd => 'بارگذاری تبلیغ...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds ثانیه صبر کنید';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'پاداش +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'تبلیغ جایزه‌دار در دسترس نیست';

  @override
  String rateBoosted(String rate) {
    return 'افزایش نرخ: +$rate ETA/ساعت';
  }

  @override
  String adBonusFailed(String message) {
    return 'پاداش تبلیغ ناموفق: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'جزئیات نرخ: پایه $base، زنجیره +$streak، رتبه +$rank، ارجاع‌ها +$referrals = $total ETA/ساعت';
  }

  @override
  String get unableToStartMining =>
      'امکان شروع استخراج وجود ندارد. لطفاً اتصال اینترنت خود را بررسی کنید و دوباره تلاش کنید.';

  @override
  String get createCommunityCoin => 'ایجاد سکه اجتماعی';

  @override
  String get launchCoinDescription =>
      'سکه خود را فوراً در شبکه ETA راه‌اندازی کنید.';

  @override
  String get createYourOwnCoin => 'سکه خود را بسازید';

  @override
  String get launchCommunityCoinDescription =>
      'سکه اجتماعی خود را راه‌اندازی کنید که سایر کاربران ETA بتوانند استخراج کنند.';

  @override
  String get editCoin => 'ویرایش سکه';

  @override
  String baseRate(String rate) {
    return 'نرخ پایه: $rate سکه/ساعت';
  }

  @override
  String createdBy(String username) {
    return 'ایجاد شده توسط @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ساعت';
  }

  @override
  String get noCoinsYet =>
      'هنوز سکه‌ای وجود ندارد. از سکه‌های زنده اضافه کنید.';

  @override
  String get mine => 'استخراج';

  @override
  String get remaining => 'باقی‌مانده';

  @override
  String get holders => 'دارندگان';

  @override
  String get close => 'بستن';

  @override
  String get readMore => 'بیشتر بخوانید';

  @override
  String get readLess => 'کمتر بخوانید';

  @override
  String get projectLinks => 'لینک‌های پروژه';

  @override
  String get verifyEmailTitle => 'تایید ایمیل';

  @override
  String get verifyEmailMessage =>
      'ما یک لینک تایید به آدرس ایمیل شما ارسال کرده‌ایم. لطفاً برای باز کردن قفل تمام ویژگی‌ها، حساب خود را تایید کنید.';

  @override
  String get resendEmail => 'ارسال مجدد ایمیل';

  @override
  String get iHaveVerified => 'من تایید کرده‌ام';

  @override
  String get logout => 'خروج';

  @override
  String get emailVerifiedSuccess => 'ایمیل با موفقیت تایید شد!';

  @override
  String get emailNotVerified =>
      'ایمیل هنوز تایید نشده است. لطفاً صندوق ورودی خود را بررسی کنید.';

  @override
  String get verificationEmailSent => 'ایمیل تایید ارسال شد';

  @override
  String get startMining => 'شروع استخراج';

  @override
  String get minedCoins => 'سکه‌های استخراج شده';

  @override
  String get liveCoins => 'سکه‌های زنده';

  @override
  String get asset => 'دارایی';

  @override
  String get filterStatus => 'وضعیت';

  @override
  String get filterPopular => 'محبوب';

  @override
  String get filterNames => 'نام‌ها';

  @override
  String get filterOldNew => 'قدیمی - جدید';

  @override
  String get filterNewOld => 'جدید - قدیمی';

  @override
  String startMiningWithCount(int count) {
    return 'شروع استخراج ($count)';
  }

  @override
  String get clearSelection => 'پاک کردن انتخاب';

  @override
  String get cancel => 'لغو';

  @override
  String get refreshStatus => 'تجدید وضعیت';

  @override
  String get purchaseFailed => 'خرید ناموفق';

  @override
  String get securePaymentViaGooglePlay => 'پرداخت امن از طریق Google Play';

  @override
  String get addedToMinedCoins => 'به سکه‌های استخراج شده اضافه شد';

  @override
  String failedToAdd(String message) {
    return 'اضافه کردن ناموفق بود: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'اشتراک‌ها فقط در اندروید/iOS در دسترس هستند.';

  @override
  String get miningRate => 'نرخ استخراج';

  @override
  String get about => 'درباره';

  @override
  String get yourMined => 'استخراج شده شما';

  @override
  String get totalMined => 'کل استخراج شده';

  @override
  String get noReferrals => 'هنوز هیچ ارجاعی وجود ندارد';

  @override
  String get linkCopied => 'لینک کپی شد';

  @override
  String get copy => 'کپی';

  @override
  String get howItWorks => 'چگونه کار می‌کند';

  @override
  String get referralDescription =>
      'کد خود را با دوستان به اشتراک بگذارید. وقتی آن‌ها می‌پیوندند و فعال می‌شوند، تیم خود را رشد می‌دهید و پتانسیل درآمد خود را بهبود می‌بخشید.';

  @override
  String get yourTeam => 'تیم شما';

  @override
  String get referralsTitle => 'ارجاع‌ها';

  @override
  String get shareLinkTitle => 'اشتراک گذاری لینک';

  @override
  String get copyLinkInstruction => 'این لینک را برای اشتراک کپی کنید:';

  @override
  String get referralCodeCopied => 'کد ارجاع کپی شد';

  @override
  String joinMeText(String code, String link) {
    return 'در شبکه Eta به من بپیوندید! از کد من استفاده کنید: $code $link';
  }

  @override
  String get etaNetwork => 'شبکه ETA';

  @override
  String get noLiveCommunityCoins => 'هیچ سکه اجتماعی زنده‌ای وجود ندارد';

  @override
  String get rate => 'نرخ';

  @override
  String get filterRandom => 'تصادفی';

  @override
  String get baseRateLabel => 'نرخ پایه';

  @override
  String startFailed(String error) {
    return 'شروع ناموفق: $error';
  }

  @override
  String get sessionProgress => 'پیشرفت جلسه';

  @override
  String get remainingLabel => 'باقی‌مانده';

  @override
  String get boostRate => 'نرخ تقویت';

  @override
  String get minedLabel => 'استخراج شده';

  @override
  String get noSubscriptionPlansAvailable => 'هیچ طرح اشتراکی در دسترس نیست';

  @override
  String get subscriptionPlans => 'طرح‌های اشتراک';

  @override
  String get recommended => 'پیشنهادی';

  @override
  String get editCommunityCoin => 'ویرایش سکه اجتماعی';

  @override
  String get launchCoinEcosystemDescription =>
      'سکه خود را در اکوسیستم ETA برای جامعه خود راه‌اندازی کنید.';

  @override
  String get upload => 'آپلود';

  @override
  String get recommendedImageSize => 'پیشنهادی 200×200px';

  @override
  String get coinNameLabel => 'نام سکه';

  @override
  String get symbolLabel => 'نماد';

  @override
  String get descriptionLabel => 'توضیحات';

  @override
  String get baseMiningRateLabel => 'نرخ پایه استخراج (سکه/ساعت)';

  @override
  String maxAllowed(String max) {
    return 'حداکثر مجاز: $max';
  }

  @override
  String get socialProjectLinksOptional => 'لینک‌های اجتماعی و پروژه (اختیاری)';

  @override
  String get linkTypeWebsite => 'وب‌سایت';

  @override
  String get linkTypeYouTube => 'یوتیوب';

  @override
  String get linkTypeFacebook => 'فیس‌بوک';

  @override
  String get linkTypeTwitter => 'X / توییتر';

  @override
  String get linkTypeInstagram => 'اینستاگرام';

  @override
  String get linkTypeTelegram => 'تلگرام';

  @override
  String get linkTypeOther => 'دیگر';

  @override
  String get pasteUrl => 'چسباندن URL';

  @override
  String get importantNoticeTitle => 'اعلان مهم';

  @override
  String get importantNoticeBody =>
      'این سکه بخشی از اکوسیستم شبکه ETA است و نشان‌دهنده مشارکت در یک جامعه دیجیتال در حال رشد است. سکه‌های اجتماعی توسط کاربران برای ساخت، آزمایش و تعامل در شبکه ایجاد می‌شوند. شبکه ETA در مراحل اولیه توسعه است. با رشد اکوسیستم، ابزارها، ویژگی‌ها و ادغام‌های جدید ممکن است بر اساس فعالیت جامعه، تکامل پلتفرم و دستورالعمل‌های قابل اجرا معرفی شوند.';

  @override
  String get pleaseWait => 'لطفاً صبر کنید...';

  @override
  String get save => 'ذخیره';

  @override
  String createCoinFailed(String error) {
    return 'ایجاد سکه ناموفق بود: $error';
  }

  @override
  String get coinNameLengthError => 'نام سکه باید 3-30 کاراکتر باشد.';

  @override
  String get symbolRequiredError => 'نماد الزامی است.';

  @override
  String get symbolLengthError => 'نماد باید 2-6 حرف/عدد باشد.';

  @override
  String get descriptionTooLongError => 'توضیحات خیلی طولانی است.';

  @override
  String baseRateRangeError(String max) {
    return 'نرخ پایه استخراج باید بین 0.000000001 و $max باشد.';
  }

  @override
  String get coinNameExistsError =>
      'نام سکه قبلاً وجود دارد. لطفاً نام دیگری انتخاب کنید.';

  @override
  String get symbolExistsError =>
      'نماد قبلاً وجود دارد. لطفاً نماد دیگری انتخاب کنید.';

  @override
  String get urlInvalidError => 'یکی از URLها نامعتبر است.';

  @override
  String get subscribeAndBoost => 'اشتراک و تقویت استخراج';

  @override
  String get autoCollect => 'جمع‌آوری خودکار';

  @override
  String autoMineCoins(int count) {
    return 'استخراج خودکار $count سکه';
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
  String get noDescriptionAvailable => 'هیچ توضیحی در دسترس نیست.';

  @override
  String get unknownUser => 'ناشناس';

  @override
  String get streakLabel => 'زنجیره';

  @override
  String get referralsLabel => 'ارجاع‌ها';

  @override
  String get sessionsLabel => 'جلسات';

  @override
  String get accountInfoSection => 'اطلاعات حساب';

  @override
  String get accountInfoTile => 'اطلاعات حساب';

  @override
  String get invitedByPrompt => 'دعوت شده توسط کسی؟';

  @override
  String get enterReferralCode => 'کد ارجاع را وارد کنید';

  @override
  String get invitedStatus => 'دعوت شده';

  @override
  String get lockedStatus => 'قفل شده';

  @override
  String get applyButton => 'اعمال';

  @override
  String get aboutPageTitle => 'درباره';

  @override
  String get faqTile => 'سوالات متداول';

  @override
  String get whitePaperTile => 'وایت پیپر';

  @override
  String get contactUsTile => 'تماس با ما';

  @override
  String get securitySettingsTile => 'تنظیمات امنیتی';

  @override
  String get securitySettingsPageTitle => 'تنظیمات امنیتی';

  @override
  String get deleteAccountTile => 'حذف حساب';

  @override
  String get deleteAccountSubtitle => 'حذف دائمی حساب و داده‌های شما';

  @override
  String get deleteAccountDialogTitle => 'حذف حساب؟';

  @override
  String get deleteAccountDialogContent =>
      'این کار حساب، داده‌ها و جلسات شما را برای همیشه حذف خواهد کرد. این عمل غیرقابل برگشت است.';

  @override
  String get deleteButton => 'حذف';

  @override
  String get kycVerificationTile => 'تایید هویت (KYC)';

  @override
  String get kycVerificationDialogTitle => 'تایید هویت (KYC)';

  @override
  String get kycComingSoonMessage => 'در مراحل آینده فعال خواهد شد.';

  @override
  String get okButton => 'تایید';

  @override
  String get logOutLabel => 'خروج';

  @override
  String get confirmDeletionTitle => 'تایید حذف';

  @override
  String get enterAccountPassword => 'رمز عبور حساب را وارد کنید';

  @override
  String get confirmButton => 'تایید';

  @override
  String get usernameLabel => 'نام کاربری';

  @override
  String get emailLabel => 'ایمیل';

  @override
  String get nameLabel => 'نام';

  @override
  String get ageLabel => 'سن';

  @override
  String get countryLabel => 'کشور';

  @override
  String get addressLabel => 'آدرس';

  @override
  String get genderLabel => 'جنسیت';

  @override
  String get enterUsernameHint => 'نام کاربری را وارد کنید';

  @override
  String get enterNameHint => 'نام را وارد کنید';

  @override
  String get enterAgeHint => 'سن را وارد کنید';

  @override
  String get enterCountryHint => 'کشور را وارد کنید';

  @override
  String get enterAddressHint => 'آدرس را وارد کنید';

  @override
  String get enterGenderHint => 'جنسیت را وارد کنید';

  @override
  String get savingLabel => 'در حال ذخیره...';

  @override
  String get usernameEmptyError => 'نام کاربری نمی‌تواند خالی باشد';

  @override
  String get invalidAgeError => 'مقدار سن نامعتبر است';

  @override
  String get saveError => 'ذخیره تغییرات ناموفق بود';

  @override
  String get cancelButton => 'لغو';
}
