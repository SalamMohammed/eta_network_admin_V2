// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get totalBalance => 'মোট ব্যালেন্স';

  @override
  String joinedDate(String link, Object date) {
    return '$date-এ যোগ দিয়েছেন';
  }

  @override
  String get inviteEarn => 'আমন্ত্রণ জানান এবং উপার্জন করুন';

  @override
  String get shareCodeDescription =>
      'আপনার মাইনিং রেট বাড়াতে বন্ধুদের সাথে আপনার অনন্য কোড শেয়ার করুন।';

  @override
  String get shareLink => 'লিঙ্ক শেয়ার করুন';

  @override
  String get totalInvited => 'মোট আমন্ত্রিত';

  @override
  String get activeNow => 'এখন সক্রিয়';

  @override
  String get viewAll => 'সব দেখুন';

  @override
  String get createCoin => 'কয়েন তৈরি করুন';

  @override
  String get mining => 'মাইনিং';

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get languageSubtitle => 'অ্যাপের ভাষা পরিবর্তন করুন';

  @override
  String get selectLanguage => 'ভাষা নির্বাচন করুন';

  @override
  String get balanceTitle => 'ব্যালেন্স';

  @override
  String get home => 'হোম';

  @override
  String get referral => 'রেফারেল';

  @override
  String get profile => 'প্রোফাইল';

  @override
  String get dayStreak => 'দিনের স্ট্রিক';

  @override
  String dayStreakValue(int count) {
    return '$count দিনের স্ট্রিক';
  }

  @override
  String get active => 'সক্রিয়';

  @override
  String get inactive => 'নিষ্ক্রিয়';

  @override
  String get sessionEndsIn => 'সেশন শেষ হবে';

  @override
  String get startEarning => 'উপার্জন শুরু করুন';

  @override
  String get loadingAd => 'বিজ্ঞাপন লোড হচ্ছে...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds সেকেন্ড অপেক্ষা করুন';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'পুরস্কার +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'পুরস্কৃত বিজ্ঞাপন উপলব্ধ নেই';

  @override
  String rateBoosted(String rate) {
    return 'রেট বুস্ট হয়েছে: +$rate ETA/ঘণ্টা';
  }

  @override
  String adBonusFailed(String message) {
    return 'বিজ্ঞাপন বোনাস ব্যর্থ: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'রেট ব্রেকডাউন: বেস $base, স্ট্রিক +$streak, র‍্যাঙ্ক +$rank, রেফারেল +$referrals = $total ETA/ঘণ্টা';
  }

  @override
  String get unableToStartMining =>
      'মাইনিং শুরু করতে অক্ষম। অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ পরীক্ষা করুন এবং আবার চেষ্টা করুন।';

  @override
  String get createCommunityCoin => 'কমিউনিটি কয়েন তৈরি করুন';

  @override
  String get launchCoinDescription =>
      'অবিলম্বে ETA নেটওয়ার্কে আপনার নিজস্ব কয়েন চালু করুন।';

  @override
  String get createYourOwnCoin => 'আপনার নিজস্ব কয়েন তৈরি করুন';

  @override
  String get launchCommunityCoinDescription =>
      'আপনার নিজস্ব কমিউনিটি কয়েন চালু করুন যা অন্যান্য ETA ব্যবহারকারীরা মাইন করতে পারে।';

  @override
  String get editCoin => 'কয়েন সম্পাদনা করুন';

  @override
  String baseRate(String rate) {
    return 'বেস রেট: $rate কয়েন/ঘণ্টা';
  }

  @override
  String createdBy(String username) {
    return '@$username দ্বারা তৈরি';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ঘণ্টা';
  }

  @override
  String get noCoinsYet => 'এখনও কোনো কয়েন নেই। লাইভ কয়েন থেকে যোগ করুন।';

  @override
  String get mine => 'মাইন';

  @override
  String get remaining => 'অবশিষ্ট';

  @override
  String get holders => 'হোল্ডাররা';

  @override
  String get close => 'বন্ধ করুন';

  @override
  String get readMore => 'আরও পড়ুন';

  @override
  String get readLess => 'কম পড়ুন';

  @override
  String get projectLinks => 'প্রজেক্ট লিঙ্ক';

  @override
  String get verifyEmailTitle => 'আপনার ইমেল যাচাই করুন';

  @override
  String get verifyEmailMessage =>
      'আমরা আপনার ইমেল ঠিকানায় একটি যাচাইকরণ লিঙ্ক পাঠিয়েছি। সমস্ত বৈশিষ্ট্য আনলক করতে অনুগ্রহ করে আপনার অ্যাকাউন্ট যাচাই করুন।';

  @override
  String get resendEmail => 'ইমেল পুনরায় পাঠান';

  @override
  String get iHaveVerified => 'আমি যাচাই করেছি';

  @override
  String get logout => 'লগআউট';

  @override
  String get emailVerifiedSuccess => 'ইমেল সফলভাবে যাচাই করা হয়েছে!';

  @override
  String get emailNotVerified =>
      'ইমেল এখনও যাচাই করা হয়নি। অনুগ্রহ করে আপনার ইনবক্স চেক করুন।';

  @override
  String get verificationEmailSent => 'যাচাইকরণ ইমেল পাঠানো হয়েছে';

  @override
  String get startMining => 'মাইনিং শুরু করুন';

  @override
  String get minedCoins => 'মাইন করা কয়েন';

  @override
  String get liveCoins => 'লাইভ কয়েন';

  @override
  String get asset => 'সম্পদ';

  @override
  String get filterStatus => 'স্ট্যাটাস';

  @override
  String get filterPopular => 'জনপ্রিয়';

  @override
  String get filterNames => 'নাম';

  @override
  String get filterOldNew => 'পুরানো - নতুন';

  @override
  String get filterNewOld => 'নতুন - পুরানো';

  @override
  String startMiningWithCount(int count) {
    return 'মাইনিং শুরু করুন ($count)';
  }

  @override
  String get clearSelection => 'নির্বাচন মুছুন';

  @override
  String get cancel => 'বাতিল';

  @override
  String get refreshStatus => 'স্ট্যাটাস রিফ্রেশ করুন';

  @override
  String get purchaseFailed => 'ক্রয় ব্যর্থ হয়েছে';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play এর মাধ্যমে নিরাপদ পেমেন্ট';

  @override
  String get addedToMinedCoins => 'মাইন করা কয়েনে যোগ করা হয়েছে';

  @override
  String failedToAdd(String message) {
    return 'যোগ করতে ব্যর্থ: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'সাবস্ক্রিপশন শুধুমাত্র Android/iOS এ উপলব্ধ।';

  @override
  String get miningRate => 'মাইনিং রেট';

  @override
  String get about => 'সম্পর্কে';

  @override
  String get yourMined => 'আপনার মাইন করা';

  @override
  String get totalMined => 'মোট মাইন করা';

  @override
  String get noReferrals => 'এখনও কোনো রেফারেল নেই';

  @override
  String get linkCopied => 'লিঙ্ক কপি করা হয়েছে';

  @override
  String get copy => 'কপি';

  @override
  String get howItWorks => 'এটি কিভাবে কাজ করে';

  @override
  String get referralDescription =>
      'বন্ধুদের সাথে আপনার কোড শেয়ার করুন। যখন তারা যোগ দেয় এবং সক্রিয় হয়, আপনার টিম বৃদ্ধি পায় এবং আপনার উপার্জনের সম্ভাবনা উন্নত হয়।';

  @override
  String get yourTeam => 'আপনার টিম';

  @override
  String get referralsTitle => 'রেফারেল';

  @override
  String get shareLinkTitle => 'লিঙ্ক শেয়ার করুন';

  @override
  String get copyLinkInstruction => 'শেয়ার করতে এই লিঙ্কটি কপি করুন:';

  @override
  String get referralCodeCopied => 'রেফারেল কোড কপি করা হয়েছে';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network-এ আমার সাথে যোগ দিন! আমার কোড ব্যবহার করুন: $code $link';
  }

  @override
  String get etaNetwork => 'ETA নেটওয়ার্ক';

  @override
  String get noLiveCommunityCoins => 'কোনো লাইভ কমিউনিটি কয়েন নেই';

  @override
  String get rate => 'রেট';

  @override
  String get filterRandom => 'এলোমেলো';

  @override
  String get baseRateLabel => 'বেস রেট';

  @override
  String startFailed(String error) {
    return 'শুরু করতে ব্যর্থ: $error';
  }

  @override
  String get sessionProgress => 'সেশন অগ্রগতি';

  @override
  String get remainingLabel => 'অবশিষ্ট';

  @override
  String get boostRate => 'বুস্ট রেট';

  @override
  String get minedLabel => 'মাইন করা হয়েছে';

  @override
  String get noSubscriptionPlansAvailable =>
      'কোনো সাবস্ক্রিপশন প্ল্যান উপলব্ধ নেই';

  @override
  String get subscriptionPlans => 'সাবস্ক্রিপশন প্ল্যান';

  @override
  String get recommended => 'সুপারিশকৃত';

  @override
  String get editCommunityCoin => 'কমিউনিটি কয়েন সম্পাদনা করুন';

  @override
  String get launchCoinEcosystemDescription =>
      'আপনার কমিউনিটির জন্য ETA ইকোসিস্টেমের মধ্যে আপনার নিজস্ব কয়েন চালু করুন।';

  @override
  String get upload => 'আপলোড';

  @override
  String get recommendedImageSize => 'সুপারিশকৃত 200x200px';

  @override
  String get coinNameLabel => 'কয়েন নাম';

  @override
  String get symbolLabel => 'প্রতীক';

  @override
  String get descriptionLabel => 'বিবরণ';

  @override
  String get baseMiningRateLabel => 'বেস মাইনিং রেট (কয়েন/ঘণ্টা)';

  @override
  String maxAllowed(String max) {
    return 'সর্বোচ্চ অনুমোদিত : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'সোশ্যাল এবং প্রজেক্ট লিঙ্ক (ঐচ্ছিক)';

  @override
  String get linkTypeWebsite => 'ওয়েবসাইট';

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
  String get linkTypeOther => 'অন্যান্য';

  @override
  String get pasteUrl => 'URL পেস্ট করুন';

  @override
  String get importantNoticeTitle => 'গুরুত্বপূর্ণ বিজ্ঞপ্তি';

  @override
  String get importantNoticeBody =>
      'এই কয়েনটি ETA নেটওয়ার্ক ইকোসিস্টেমের একটি অংশ এবং একটি ক্রমবর্ধমান ডিজিটাল কমিউনিটিতে অংশগ্রহণের প্রতিনিধিত্ব করে। কমিউনিটি কয়েন ব্যবহারকারীরা নেটওয়ার্কের মধ্যে তৈরি, পরীক্ষা এবং নিযুক্ত করার জন্য তৈরি করে। ETA নেটওয়ার্ক উন্নয়নের প্রাথমিক পর্যায়ে রয়েছে। ইকোসিস্টেম বাড়ার সাথে সাথে, কমিউনিটি কার্যকলাপ, প্ল্যাটফর্ম বিবর্তন এবং প্রযোজ্য নির্দেশিকাগুলির উপর ভিত্তি করে নতুন ইউটিলিটি, বৈশিষ্ট্য এবং ইন্টিগ্রেশন চালু করা হতে পারে।';

  @override
  String get pleaseWait => 'অনুগ্রহ করে অপেক্ষা করুন...';

  @override
  String get save => 'সংরক্ষণ করুন';

  @override
  String createCoinFailed(String error) {
    return 'কয়েন তৈরি করতে ব্যর্থ: $error';
  }

  @override
  String get coinNameLengthError => 'কয়েন নাম 3-30 অক্ষরের হতে হবে।';

  @override
  String get symbolRequiredError => 'প্রতীক প্রয়োজন।';

  @override
  String get symbolLengthError => 'প্রতীক 2-6 অক্ষর/সংখ্যা হতে হবে।';

  @override
  String get descriptionTooLongError => 'বিবরণ খুব দীর্ঘ।';

  @override
  String baseRateRangeError(String max) {
    return 'বেস মাইনিং রেট 0.000000001 এবং $max এর মধ্যে হতে হবে।';
  }

  @override
  String get coinNameExistsError =>
      'কয়েন নাম ইতিমধ্যেই বিদ্যমান। অনুগ্রহ করে অন্য একটি চয়ন করুন।';

  @override
  String get symbolExistsError =>
      'প্রতীক ইতিমধ্যেই বিদ্যমান। অনুগ্রহ করে অন্য একটি চয়ন করুন।';

  @override
  String get urlInvalidError => 'URL গুলির মধ্যে একটি অবৈধ।';

  @override
  String get subscribeAndBoost => 'সাবস্ক্রাইব করুন এবং মাইনিং বুস্ট করুন';

  @override
  String get autoCollect => 'অটো কালেক্ট';

  @override
  String autoMineCoins(int count) {
    return '$count টি কয়েন অটো মাইন করুন';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% গতি';
  }

  @override
  String get perHourSuffix => '/ঘণ্টা';

  @override
  String get etaPerHourSuffix => 'ETA/ঘণ্টা';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'কোনো বিবরণ উপলব্ধ নেই।';

  @override
  String get unknownUser => 'অজানা';

  @override
  String get streakLabel => 'স্ট্রিক';

  @override
  String get referralsLabel => 'রেফারেল';

  @override
  String get sessionsLabel => 'সেশন';

  @override
  String get accountInfoSection => 'অ্যাকাউন্ট তথ্য';

  @override
  String get accountInfoTile => 'অ্যাকাউন্ট তথ্য';

  @override
  String get invitedByPrompt => 'কারও দ্বারা আমন্ত্রিত?';

  @override
  String get enterReferralCode => 'রেফারেল কোড লিখুন';

  @override
  String get invitedStatus => 'আমন্ত্রিত';

  @override
  String get lockedStatus => 'লক করা হয়েছে';

  @override
  String get applyButton => 'প্রয়োগ করুন';

  @override
  String get aboutPageTitle => 'সম্পর্কে';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'হোয়াইট পেপার';

  @override
  String get contactUsTile => 'আমাদের সাথে যোগাযোগ করুন';

  @override
  String get securitySettingsTile => 'নিরাপত্তা সেটিংস';

  @override
  String get securitySettingsPageTitle => 'নিরাপত্তা সেটিংস';

  @override
  String get deleteAccountTile => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountSubtitle =>
      'আপনার অ্যাকাউন্ট এবং ডেটা স্থায়ীভাবে মুছুন';

  @override
  String get deleteAccountDialogTitle => 'অ্যাকাউন্ট মুছবেন?';

  @override
  String get deleteAccountDialogContent =>
      'এটি আপনার অ্যাকাউন্ট, ডেটা এবং সেশনগুলি স্থায়ীভাবে মুছে ফেলবে। এই ক্রিয়াটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get deleteButton => 'মুছুন';

  @override
  String get kycVerificationTile => 'KYC যাচাইকরণ';

  @override
  String get kycVerificationDialogTitle => 'KYC যাচাইকরণ';

  @override
  String get kycComingSoonMessage => 'আসন্ন পর্যায়গুলিতে সক্রিয় করা হবে।';

  @override
  String get okButton => 'ঠিক আছে';

  @override
  String get logOutLabel => 'লগআউট';

  @override
  String get confirmDeletionTitle => 'মুছে ফেলা নিশ্চিত করুন';

  @override
  String get enterAccountPassword => 'অ্যাকাউন্ট পাসওয়ার্ড লিখুন';

  @override
  String get confirmButton => 'নিশ্চিত করুন';

  @override
  String get usernameLabel => 'ব্যবহারকারীর নাম';

  @override
  String get emailLabel => 'ইমেল';

  @override
  String get nameLabel => 'নাম';

  @override
  String get ageLabel => 'বয়স';

  @override
  String get countryLabel => 'দেশ';

  @override
  String get addressLabel => 'ঠিকানা';

  @override
  String get genderLabel => 'লিঙ্গ';

  @override
  String get enterUsernameHint => 'ব্যবহারকারীর নাম লিখুন';

  @override
  String get enterNameHint => 'নাম লিখুন';

  @override
  String get enterAgeHint => 'বয়স লিখুন';

  @override
  String get enterCountryHint => 'দেশ লিখুন';

  @override
  String get enterAddressHint => 'ঠিকানা লিখুন';

  @override
  String get enterGenderHint => 'লিঙ্গ লিখুন';

  @override
  String get savingLabel => 'সংরক্ষণ করা হচ্ছে...';

  @override
  String get usernameEmptyError => 'ব্যবহারকারীর নাম খালি হতে পারে না';

  @override
  String get invalidAgeError => 'অবৈধ বয়স মান';

  @override
  String get saveError => 'পরিবর্তন সংরক্ষণ করতে ব্যর্থ';

  @override
  String get cancelButton => 'বাতিল';
}
