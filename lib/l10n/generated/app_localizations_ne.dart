// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get totalBalance => 'कुल मौज्दात';

  @override
  String joinedDate(String link, Object date) {
    return '$date मा सामेल हुनुभयो';
  }

  @override
  String get inviteEarn => 'आमन्त्रण गर्नुहोस् र कमाउनुहोस्';

  @override
  String get shareCodeDescription =>
      'तपाईंको खनन दर बढाउन साथीहरूसँग तपाईंको अद्वितीय कोड साझा गर्नुहोस्।';

  @override
  String get shareLink => 'लिङ्क साझा गर्नुहोस्';

  @override
  String get totalInvited => 'कुल आमन्त्रित';

  @override
  String get activeNow => 'अहिले सक्रिय';

  @override
  String get viewAll => 'सबै हेर्नुहोस्';

  @override
  String get createCoin => 'सिक्का सिर्जना गर्नुहोस्';

  @override
  String get mining => 'खनन';

  @override
  String get settings => 'सेटिङहरू';

  @override
  String get language => 'भाषा';

  @override
  String get languageSubtitle => 'अनुप्रयोग भाषा परिवर्तन गर्नुहोस्';

  @override
  String get selectLanguage => 'भाषा छान्नुहोस्';

  @override
  String get balanceTitle => 'मौज्दात';

  @override
  String get home => 'गृह';

  @override
  String get referral => 'रेफरल';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get dayStreak => 'दिनको स्ट्रीक';

  @override
  String dayStreakValue(int count) {
    return '$count दिनको स्ट्रीक';
  }

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get sessionEndsIn => 'सत्र समाप्त हुन्छ';

  @override
  String get startEarning => 'कमाउन सुरु गर्नुहोस्';

  @override
  String get loadingAd => 'विज्ञापन लोड हुँदैछ...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds सेकेन्ड पर्खनुहोस्';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'पुरस्कार +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'पुरस्कृत विज्ञापन उपलब्ध छैन';

  @override
  String rateBoosted(String rate) {
    return 'दर बढ्यो: +$rate ETA/घन्टा';
  }

  @override
  String adBonusFailed(String message) {
    return 'विज्ञापन बोनस असफल: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'दर विवरण: आधार $base, स्ट्रीक +$streak, रैंक +$rank, रेफरलहरू +$referrals = $total ETA/घन्टा';
  }

  @override
  String get unableToStartMining =>
      'खनन सुरु गर्न असमर्थ। कृपया आफ्नो इन्टरनेट जडान जाँच गर्नुहोस् र पुन: प्रयास गर्नुहोस्।';

  @override
  String get createCommunityCoin => 'सामुदायिक सिक्का सिर्जना गर्नुहोस्';

  @override
  String get launchCoinDescription =>
      'ETA नेटवर्कमा तुरुन्तै तपाईंको आफ्नै सिक्का लन्च गर्नुहोस्।';

  @override
  String get createYourOwnCoin => 'तपाईंको आफ्नै सिक्का सिर्जना गर्नुहोस्';

  @override
  String get launchCommunityCoinDescription =>
      'अन्य ETA प्रयोगकर्ताहरूले खन्न सक्ने तपाईंको आफ्नै सामुदायिक सिक्का लन्च गर्नुहोस्।';

  @override
  String get editCoin => 'सिक्का सम्पादन गर्नुहोस्';

  @override
  String baseRate(String rate) {
    return 'आधार दर: $rate सिक्का/घन्टा';
  }

  @override
  String createdBy(String username) {
    return '@$username द्वारा सिर्जना गरिएको';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/घन्टा';
  }

  @override
  String get noCoinsYet =>
      'अहिलेसम्म कुनै सिक्का छैन। लाइभ सिक्काहरूबाट थप्नुहोस्।';

  @override
  String get mine => 'खनन';

  @override
  String get remaining => 'बाँकी';

  @override
  String get holders => 'धारकहरू';

  @override
  String get close => 'बन्द गर्नुहोस्';

  @override
  String get readMore => 'थप पढ्नुहोस्';

  @override
  String get readLess => 'कम पढ्नुहोस्';

  @override
  String get projectLinks => 'परियोजना लिङ्कहरू';

  @override
  String get verifyEmailTitle => 'तपाईंको इमेल प्रमाणित गर्नुहोस्';

  @override
  String get verifyEmailMessage =>
      'हामीले तपाईंको इमेल ठेगानामा प्रमाणीकरण लिङ्क पठाएका छौं। सबै सुविधाहरू अनलक गर्न कृपया आफ्नो खाता प्रमाणित गर्नुहोस्।';

  @override
  String get resendEmail => 'इमेल पुन: पठाउनुहोस्';

  @override
  String get iHaveVerified => 'मैले प्रमाणित गरें';

  @override
  String get logout => 'लगआउट';

  @override
  String get emailVerifiedSuccess => 'इमेल सफलतापूर्वक प्रमाणित भयो!';

  @override
  String get emailNotVerified =>
      'इमेल अहिलेसम्म प्रमाणित भएको छैन। कृपया आफ्नो इनबक्स जाँच गर्नुहोस्।';

  @override
  String get verificationEmailSent => 'प्रमाणीकरण इमेल पठाइयो';

  @override
  String get startMining => 'खनन सुरु गर्नुहोस्';

  @override
  String get minedCoins => 'खनन गरिएका सिक्काहरू';

  @override
  String get liveCoins => 'लाइभ सिक्काहरू';

  @override
  String get asset => 'सम्पत्ति';

  @override
  String get filterStatus => 'स्थिति';

  @override
  String get filterPopular => 'लोकप्रिय';

  @override
  String get filterNames => 'नामहरू';

  @override
  String get filterOldNew => 'पुरानो - नयाँ';

  @override
  String get filterNewOld => 'नयाँ - पुरानो';

  @override
  String startMiningWithCount(int count) {
    return 'खनन सुरु गर्नुहोस् ($count)';
  }

  @override
  String get clearSelection => 'चयन हटाउनुहोस्';

  @override
  String get cancel => 'रद्द गर्नुहोस्';

  @override
  String get refreshStatus => 'स्थिति रिफ्रेस गर्नुहोस्';

  @override
  String get purchaseFailed => 'खरिद असफल भयो';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play मार्फत सुरक्षित भुक्तानी';

  @override
  String get addedToMinedCoins => 'खनन गरिएका सिक्काहरूमा थपियो';

  @override
  String failedToAdd(String message) {
    return 'थप्न असफल: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'सदस्यताहरू एन्ड्रोइड/iOS मा मात्र उपलब्ध छन्।';

  @override
  String get miningRate => 'खनन दर';

  @override
  String get about => 'बारेमा';

  @override
  String get yourMined => 'तपाईंको खनन';

  @override
  String get totalMined => 'कुल खनन';

  @override
  String get noReferrals => 'अहिलेसम्म कुनै रेफरल छैन';

  @override
  String get linkCopied => 'लिङ्क प्रतिलिपि गरियो';

  @override
  String get copy => 'प्रतिलिपि गर्नुहोस्';

  @override
  String get howItWorks => 'यो कसरी काम गर्दछ';

  @override
  String get referralDescription =>
      'साथीहरूसँग तपाईंको कोड साझा गर्नुहोस्। जब तिनीहरू सामेल हुन्छन् र सक्रिय हुन्छन्, तपाईंको टोली बढ्छ र तपाईंको कमाइ क्षमता सुधार हुन्छ।';

  @override
  String get yourTeam => 'तपाईंको टोली';

  @override
  String get referralsTitle => 'रेफरलहरू';

  @override
  String get shareLinkTitle => 'लिङ्क साझा गर्नुहोस्';

  @override
  String get copyLinkInstruction => 'साझा गर्न यो लिङ्क प्रतिलिपि गर्नुहोस्:';

  @override
  String get referralCodeCopied => 'रेफरल कोड प्रतिलिपि गरियो';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network मा मलाई सामेल हुनुहोस्! मेरो कोड प्रयोग गर्नुहोस्: $code $link';
  }

  @override
  String get etaNetwork => 'ETA नेटवर्क';

  @override
  String get noLiveCommunityCoins => 'कुनै लाइभ सामुदायिक सिक्का छैन';

  @override
  String get rate => 'दर';

  @override
  String get filterRandom => 'अनियमित';

  @override
  String get baseRateLabel => 'आधार दर';

  @override
  String startFailed(String error) {
    return 'सुरु गर्न असफल: $error';
  }

  @override
  String get sessionProgress => 'सत्र प्रगति';

  @override
  String get remainingLabel => 'बाँकी';

  @override
  String get boostRate => 'बुस्ट दर';

  @override
  String get minedLabel => 'खनन गरिएको';

  @override
  String get noSubscriptionPlansAvailable =>
      'कुनै सदस्यता योजनाहरू उपलब्ध छैनन्';

  @override
  String get subscriptionPlans => 'सदस्यता योजनाहरू';

  @override
  String get recommended => 'सिफारिस गरिएको';

  @override
  String get editCommunityCoin => 'सामुदायिक सिक्का सम्पादन गर्नुहोस्';

  @override
  String get launchCoinEcosystemDescription =>
      'तपाईंको समुदायको लागि ETA इकोसिस्टम भित्र तपाईंको आफ्नै सिक्का लन्च गर्नुहोस्।';

  @override
  String get upload => 'अपलोड गर्नुहोस्';

  @override
  String get recommendedImageSize => 'सिफारिस गरिएको 200x200px';

  @override
  String get coinNameLabel => 'सिक्का नाम';

  @override
  String get symbolLabel => 'प्रतीक';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get baseMiningRateLabel => 'आधार खनन दर (सिक्का/घन्टा)';

  @override
  String maxAllowed(String max) {
    return 'अधिकतम अनुमति : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'सामाजिक र परियोजना लिङ्कहरू (वैकल्पिक)';

  @override
  String get linkTypeWebsite => 'वेबसाइट';

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
  String get linkTypeOther => 'अन्य';

  @override
  String get pasteUrl => 'URL टाँस्नुहोस्';

  @override
  String get importantNoticeTitle => 'महत्त्वपूर्ण सूचना';

  @override
  String get importantNoticeBody =>
      'यो सिक्का ETA नेटवर्क इकोसिस्टमको हिस्सा हो र बढ्दो डिजिटल समुदायमा सहभागिताको प्रतिनिधित्व गर्दछ। सामुदायिक सिक्काहरू प्रयोगकर्ताहरूद्वारा नेटवर्क भित्र निर्माण, प्रयोग र संलग्न हुन सिर्जना गरिन्छ। ETA नेटवर्क विकासको प्रारम्भिक चरणमा छ। इकोसिस्टम बढ्दै जाँदा, सामुदायिक गतिविधि, प्लेटफर्म विकास र लागू दिशानिर्देशहरूको आधारमा नयाँ उपयोगिताहरू, सुविधाहरू र एकीकरणहरू प्रस्तुत गर्न सकिन्छ।';

  @override
  String get pleaseWait => 'कृपया पर्खनुहोस्...';

  @override
  String get save => 'बचत गर्नुहोस्';

  @override
  String createCoinFailed(String error) {
    return 'सिक्का सिर्जना गर्न असफल: $error';
  }

  @override
  String get coinNameLengthError => 'सिक्का नाम 3-30 क्यारेक्टर हुनुपर्छ।';

  @override
  String get symbolRequiredError => 'प्रतीक आवश्यक छ।';

  @override
  String get symbolLengthError => 'प्रतीक 2-6 अक्षर/संख्या हुनुपर्छ।';

  @override
  String get descriptionTooLongError => 'विवरण धेरै लामो छ।';

  @override
  String baseRateRangeError(String max) {
    return 'आधार खनन दर 0.000000001 र $max को बीचमा हुनुपर्छ।';
  }

  @override
  String get coinNameExistsError =>
      'सिक्का नाम पहिले नै अवस्थित छ। कृपया अर्को छान्नुहोस्।';

  @override
  String get symbolExistsError =>
      'प्रतीक पहिले नै अवस्थित छ। कृपया अर्को छान्नुहोस्।';

  @override
  String get urlInvalidError => 'URL हरू मध्ये एक अमान्य छ।';

  @override
  String get subscribeAndBoost => 'सदस्यता लिनुहोस् र खनन बुस्ट गर्नुहोस्';

  @override
  String get autoCollect => 'स्वत: सङ्कलन';

  @override
  String autoMineCoins(int count) {
    return '$count सिक्काहरू स्वत: खनन गर्नुहोस्';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% गति';
  }

  @override
  String get perHourSuffix => '/घन्टा';

  @override
  String get etaPerHourSuffix => 'ETA/घन्टा';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'कुनै विवरण उपलब्ध छैन।';

  @override
  String get unknownUser => 'अज्ञात';

  @override
  String get streakLabel => 'स्ट्रीक';

  @override
  String get referralsLabel => 'रेफरलहरू';

  @override
  String get sessionsLabel => 'सत्रहरू';

  @override
  String get accountInfoSection => 'खाता जानकारी';

  @override
  String get accountInfoTile => 'खाता जानकारी';

  @override
  String get invitedByPrompt => 'कसैले आमन्त्रित गर्नुभयो?';

  @override
  String get enterReferralCode => 'रेफरल कोड प्रविष्ट गर्नुहोस्';

  @override
  String get invitedStatus => 'आमन्त्रित';

  @override
  String get lockedStatus => 'लक गरिएको';

  @override
  String get applyButton => 'लागू गर्नुहोस्';

  @override
  String get aboutPageTitle => 'बारेमा';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'श्वेत पत्र';

  @override
  String get contactUsTile => 'हामीलाई सम्पर्क गर्नुहोस्';

  @override
  String get securitySettingsTile => 'सुरक्षा सेटिङहरू';

  @override
  String get securitySettingsPageTitle => 'सुरक्षा सेटिङहरू';

  @override
  String get deleteAccountTile => 'खाता मेटाउनुहोस्';

  @override
  String get deleteAccountSubtitle =>
      'तपाईंको खाता र डाटा स्थायी रूपमा मेटाउनुहोस्';

  @override
  String get deleteAccountDialogTitle => 'खाता मेटाउने?';

  @override
  String get deleteAccountDialogContent =>
      'यसले तपाईंको खाता, डाटा र सत्रहरू स्थायी रूपमा मेटाउनेछ। यो कार्य पूर्ववत गर्न सकिँदैन।';

  @override
  String get deleteButton => 'मेटाउनुहोस्';

  @override
  String get kycVerificationTile => 'KYC प्रमाणीकरण';

  @override
  String get kycVerificationDialogTitle => 'KYC प्रमाणीकरण';

  @override
  String get kycComingSoonMessage => 'आगामी चरणहरूमा सक्रिय गरिनेछ।';

  @override
  String get okButton => 'ठिक छ';

  @override
  String get logOutLabel => 'लगआउट';

  @override
  String get confirmDeletionTitle => 'मेटाउने पुष्टि गर्नुहोस्';

  @override
  String get enterAccountPassword => 'खाता पासवर्ड प्रविष्ट गर्नुहोस्';

  @override
  String get confirmButton => 'पुष्टि गर्नुहोस्';

  @override
  String get usernameLabel => 'प्रयोगकर्ता नाम';

  @override
  String get emailLabel => 'इमेल';

  @override
  String get nameLabel => 'नाम';

  @override
  String get ageLabel => 'उमेर';

  @override
  String get countryLabel => 'देश';

  @override
  String get addressLabel => 'ठेगाना';

  @override
  String get genderLabel => 'लिङ्ग';

  @override
  String get enterUsernameHint => 'प्रयोगकर्ता नाम प्रविष्ट गर्नुहोस्';

  @override
  String get enterNameHint => 'नाम प्रविष्ट गर्नुहोस्';

  @override
  String get enterAgeHint => 'उमेर प्रविष्ट गर्नुहोस्';

  @override
  String get enterCountryHint => 'देश प्रविष्ट गर्नुहोस्';

  @override
  String get enterAddressHint => 'ठेगाना प्रविष्ट गर्नुहोस्';

  @override
  String get enterGenderHint => 'लिङ्ग प्रविष्ट गर्नुहोस्';

  @override
  String get savingLabel => 'बचत गरिँदै...';

  @override
  String get usernameEmptyError => 'प्रयोगकर्ता नाम खाली हुन सक्दैन';

  @override
  String get invalidAgeError => 'अमान्य उमेर मान';

  @override
  String get saveError => 'परिवर्तनहरू बचत गर्न असफल';

  @override
  String get cancelButton => 'रद्द गर्नुहोस्';
}
