// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get totalBalance => 'إجمالي الرصيد';

  @override
  String joinedDate(String link, Object date) {
    return 'انضم في $date';
  }

  @override
  String get inviteEarn => 'ادعُ واكسب';

  @override
  String get shareCodeDescription =>
      'شارك رمزك الفريد مع الأصدقاء لزيادة معدل التعدين الخاص بك.';

  @override
  String get shareLink => 'مشاركة الرابط';

  @override
  String get totalInvited => 'إجمالي المدعوين';

  @override
  String get activeNow => 'نشط الآن';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get createCoin => 'إنشاء عملة';

  @override
  String get mining => 'تعدين';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get languageSubtitle => 'تغيير لغة التطبيق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get balanceTitle => 'الرصيد';

  @override
  String get home => 'الرئيسية';

  @override
  String get referral => 'الإحالة';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get dayStreak => 'أيام متتالية';

  @override
  String dayStreakValue(int count) {
    return '$count أيام متتالية';
  }

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get sessionEndsIn => 'تنتهي الجلسة خلال';

  @override
  String get startEarning => 'ابدأ الكسب';

  @override
  String get loadingAd => 'جاري تحميل الإعلان...';

  @override
  String waitSeconds(int seconds) {
    return 'انتظر $seconds ثانية';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'مكافأة +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'الإعلان بمكافأة غير متوفر';

  @override
  String rateBoosted(String rate) {
    return 'تم تعزيز المعدل: +$rate ETA/ساعة';
  }

  @override
  String adBonusFailed(String message) {
    return 'فشلت مكافأة الإعلان: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'تفاصيل المعدل: الأساسي $base، المتتالي +$streak، الرتبة +$rank، الإحالات +$referrals = $total ETA/ساعة';
  }

  @override
  String get unableToStartMining =>
      'تعذر بدء التعدين. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';

  @override
  String get createCommunityCoin => 'إنشاء عملة مجتمعية';

  @override
  String get launchCoinDescription => 'أطلق عملتك الخاصة على شبكة ETA فورًا.';

  @override
  String get createYourOwnCoin => 'أنشئ عملتك الخاصة';

  @override
  String get launchCommunityCoinDescription =>
      'أطلق عملة مجتمعية خاصة بك يمكن لمستخدمي ETA الآخرين تعدينها.';

  @override
  String get editCoin => 'تعديل العملة';

  @override
  String baseRate(String rate) {
    return 'المعدل الأساسي: $rate عملة/ساعة';
  }

  @override
  String createdBy(String username) {
    return 'تم الإنشاء بواسطة @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ساعة';
  }

  @override
  String get noCoinsYet => 'لا توجد عملات بعد. أضف من العملات الحية.';

  @override
  String get mine => 'تعدين';

  @override
  String get remaining => 'متبقي';

  @override
  String get holders => 'حاملي العملة';

  @override
  String get close => 'إغلاق';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get readLess => 'اقرأ أقل';

  @override
  String get projectLinks => 'روابط المشروع';

  @override
  String get verifyEmailTitle => 'تحقق من بريدك الإلكتروني';

  @override
  String get verifyEmailMessage =>
      'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني. يرجى التحقق من حسابك لفتح جميع الميزات.';

  @override
  String get resendEmail => 'إعادة إرسال البريد الإلكتروني';

  @override
  String get iHaveVerified => 'لقد تحققت';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get emailVerifiedSuccess => 'تم التحقق من البريد الإلكتروني بنجاح!';

  @override
  String get emailNotVerified =>
      'لم يتم التحقق من البريد الإلكتروني بعد. يرجى التحقق من صندوق الوارد الخاص بك.';

  @override
  String get verificationEmailSent => 'تم إرسال بريد التحقق';

  @override
  String get startMining => 'ابدأ التعدين';

  @override
  String get minedCoins => 'العملات المعدنة';

  @override
  String get liveCoins => 'العملات الحية';

  @override
  String get asset => 'أصل';

  @override
  String get filterStatus => 'الحالة';

  @override
  String get filterPopular => 'شائع';

  @override
  String get filterNames => 'الأسماء';

  @override
  String get filterOldNew => 'قديم - جديد';

  @override
  String get filterNewOld => 'جديد - قديم';

  @override
  String startMiningWithCount(int count) {
    return 'ابدأ التعدين ($count)';
  }

  @override
  String get clearSelection => 'مسح التحديد';

  @override
  String get cancel => 'إلغاء';

  @override
  String get refreshStatus => 'تحديث الحالة';

  @override
  String get purchaseFailed => 'فشل الشراء';

  @override
  String get securePaymentViaGooglePlay => 'دفع آمن عبر Google Play';

  @override
  String get addedToMinedCoins => 'تمت الإضافة إلى العملات المعدنة';

  @override
  String failedToAdd(String message) {
    return 'فشل في الإضافة: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'الاشتراكات متاحة فقط على Android/iOS.';

  @override
  String get miningRate => 'معدل التعدين';

  @override
  String get about => 'حول';

  @override
  String get yourMined => 'ما قمت بتعدينه';

  @override
  String get totalMined => 'إجمالي ما تم تعدينه';

  @override
  String get noReferrals => 'لا توجد إحالات بعد';

  @override
  String get linkCopied => 'تم نسخ الرابط';

  @override
  String get copy => 'نسخ';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get referralDescription =>
      'شارك رمزك مع الأصدقاء. عندما ينضمون ويصبحون نشطين، ينمو فريقك وتتحسن إمكاناتك في الكسب.';

  @override
  String get yourTeam => 'فريقك';

  @override
  String get referralsTitle => 'الإحالات';

  @override
  String get shareLinkTitle => 'مشاركة الرابط';

  @override
  String get copyLinkInstruction => 'انسخ هذا الرابط للمشاركة:';

  @override
  String get referralCodeCopied => 'تم نسخ رمز الإحالة';

  @override
  String joinMeText(String code, String link) {
    return 'انضم إلي في شبكة Eta! استخدم الرمز الخاص بي: $code $link';
  }

  @override
  String get etaNetwork => 'شبكة ETA';

  @override
  String get noLiveCommunityCoins => 'لا توجد عملات مجتمعية حية';

  @override
  String get rate => 'المعدل';

  @override
  String get filterRandom => 'عشوائي';

  @override
  String get baseRateLabel => 'المعدل الأساسي';

  @override
  String startFailed(String error) {
    return 'فشل البدء: $error';
  }

  @override
  String get sessionProgress => 'تقدم الجلسة';

  @override
  String get remainingLabel => 'متبقي';

  @override
  String get boostRate => 'معدل التعزيز';

  @override
  String get minedLabel => 'تم تعدينه';

  @override
  String get noSubscriptionPlansAvailable => 'لا توجد خطط اشتراك متاحة';

  @override
  String get subscriptionPlans => 'خطط الاشتراك';

  @override
  String get recommended => 'موصى به';

  @override
  String get editCommunityCoin => 'تعديل العملة المجتمعية';

  @override
  String get launchCoinEcosystemDescription =>
      'أطلق عملتك الخاصة داخل نظام ETA لمجتمعك.';

  @override
  String get upload => 'رفع';

  @override
  String get recommendedImageSize => 'موصى به 200x200 بكسل';

  @override
  String get coinNameLabel => 'اسم العملة';

  @override
  String get symbolLabel => 'الرمز';

  @override
  String get descriptionLabel => 'الوصف';

  @override
  String get baseMiningRateLabel => 'معدل التعدين الأساسي (عملة/ساعة)';

  @override
  String maxAllowed(String max) {
    return 'الحد الأقصى المسموح به : $max';
  }

  @override
  String get socialProjectLinksOptional => 'روابط اجتماعية ومشروع (اختياري)';

  @override
  String get linkTypeWebsite => 'الموقع الإلكتروني';

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
  String get linkTypeOther => 'أخرى';

  @override
  String get pasteUrl => 'لصق الرابط';

  @override
  String get importantNoticeTitle => 'إشعار هام';

  @override
  String get importantNoticeBody =>
      'هذه العملة هي جزء من نظام شبكة ETA وتمثل المشاركة في مجتمع رقمي متنامٍ. يتم إنشاء العملات المجتمعية بواسطة المستخدمين للبناء والتجربة والتفاعل داخل الشبكة. شبكة ETA في مرحلة مبكرة من التطوير. مع نمو النظام البيئي، قد يتم تقديم أدوات وميزات وتكاملات جديدة بناءً على نشاط المجتمع وتطور المنصة والمبادئ التوجيهية المعمول بها.';

  @override
  String get pleaseWait => 'يرجى الانتظار...';

  @override
  String get save => 'حفظ';

  @override
  String createCoinFailed(String error) {
    return 'فشل إنشاء العملة: $error';
  }

  @override
  String get coinNameLengthError => 'يجب أن يكون اسم العملة 3-30 حرفًا.';

  @override
  String get symbolRequiredError => 'الرمز مطلوب.';

  @override
  String get symbolLengthError => 'يجب أن يكون الرمز 2-6 أحرف/أرقام.';

  @override
  String get descriptionTooLongError => 'الوصف طويل جدًا.';

  @override
  String baseRateRangeError(String max) {
    return 'يجب أن يكون معدل التعدين الأساسي بين 0.000000001 و $max.';
  }

  @override
  String get coinNameExistsError =>
      'اسم العملة موجود بالفعل. يرجى اختيار اسم آخر.';

  @override
  String get symbolExistsError => 'الرمز موجود بالفعل. يرجى اختيار رمز آخر.';

  @override
  String get urlInvalidError => 'أحد الروابط غير صالح.';

  @override
  String get subscribeAndBoost => 'اشترك وعزز التعدين';

  @override
  String get autoCollect => 'جمع تلقائي';

  @override
  String autoMineCoins(int count) {
    return 'تعدين تلقائي لـ $count عملات';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% سرعة';
  }

  @override
  String get perHourSuffix => '/ساعة';

  @override
  String get etaPerHourSuffix => 'ETA/ساعة';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'لا يوجد وصف متاح.';

  @override
  String get unknownUser => 'غير معروف';

  @override
  String get streakLabel => 'متتالية';

  @override
  String get referralsLabel => 'الإحالات';

  @override
  String get sessionsLabel => 'الجلسات';

  @override
  String get accountInfoSection => 'معلومات الحساب';

  @override
  String get accountInfoTile => 'معلومات الحساب';

  @override
  String get invitedByPrompt => 'هل تمت دعوتك بواسطة شخص ما؟';

  @override
  String get enterReferralCode => 'أدخل رمز الإحالة';

  @override
  String get invitedStatus => 'تمت الدعوة';

  @override
  String get lockedStatus => 'مقفل';

  @override
  String get applyButton => 'تطبيق';

  @override
  String get aboutPageTitle => 'حول';

  @override
  String get faqTile => 'الأسئلة الشائعة';

  @override
  String get whitePaperTile => 'الورقة البيضاء';

  @override
  String get contactUsTile => 'اتصل بنا';

  @override
  String get securitySettingsTile => 'إعدادات الأمان';

  @override
  String get securitySettingsPageTitle => 'إعدادات الأمان';

  @override
  String get deleteAccountTile => 'حذف الحساب';

  @override
  String get deleteAccountSubtitle => 'حذف حسابك وبياناتك بشكل دائم';

  @override
  String get deleteAccountDialogTitle => 'حذف الحساب؟';

  @override
  String get deleteAccountDialogContent =>
      'سيؤدي هذا إلى حذف حسابك وبياناتك وجلساتك بشكل دائم. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get deleteButton => 'حذف';

  @override
  String get kycVerificationTile => 'تحقق KYC';

  @override
  String get kycVerificationDialogTitle => 'تحقق KYC';

  @override
  String get kycComingSoonMessage => 'سيتم تفعيله في المراحل القادمة.';

  @override
  String get okButton => 'موافق';

  @override
  String get logOutLabel => 'تسجيل الخروج';

  @override
  String get confirmDeletionTitle => 'تأكيد الحذف';

  @override
  String get enterAccountPassword => 'أدخل كلمة مرور الحساب';

  @override
  String get confirmButton => 'تأكيد';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get ageLabel => 'العمر';

  @override
  String get countryLabel => 'الدولة';

  @override
  String get addressLabel => 'العنوان';

  @override
  String get genderLabel => 'الجنس';

  @override
  String get enterUsernameHint => 'أدخل اسم المستخدم';

  @override
  String get enterNameHint => 'أدخل الاسم';

  @override
  String get enterAgeHint => 'أدخل العمر';

  @override
  String get enterCountryHint => 'أدخل الدولة';

  @override
  String get enterAddressHint => 'أدخل العنوان';

  @override
  String get enterGenderHint => 'أدخل الجنس';

  @override
  String get savingLabel => 'جاري الحفظ...';

  @override
  String get usernameEmptyError => 'لا يمكن أن يكون اسم المستخدم فارغًا';

  @override
  String get invalidAgeError => 'قيمة العمر غير صالحة';

  @override
  String get saveError => 'فشل حفظ التغييرات';

  @override
  String get cancelButton => 'إلغاء';
}
