// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get totalBalance => 'कुल शेष';

  @override
  String joinedDate(String link, Object date) {
    return 'शामिल हुए $date';
  }

  @override
  String get inviteEarn => 'आमंत्रित करें और कमाएं';

  @override
  String get shareCodeDescription =>
      'अपनी खनन दर बढ़ाने के लिए दोस्तों के साथ अपना अनूठा कोड साझा करें।';

  @override
  String get shareLink => 'लिंक साझा करें';

  @override
  String get totalInvited => 'कुल आमंत्रित';

  @override
  String get activeNow => 'अभी सक्रिय';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get createCoin => 'सिक्का बनाएं';

  @override
  String get mining => 'खनन';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get languageSubtitle => 'ऐप की भाषा बदलें';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get balanceTitle => 'शेष राशि';

  @override
  String get home => 'होम';

  @override
  String get referral => 'रेफरल';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get dayStreak => 'दिन की लकीर';

  @override
  String dayStreakValue(int count) {
    return '$count दिन की लकीर';
  }

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get sessionEndsIn => 'सत्र समाप्त होगा';

  @override
  String get startEarning => 'कमाना शुरू करें';

  @override
  String get loadingAd => 'विज्ञापन लोड हो रहा है...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds सेकंड प्रतीक्षा करें';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'इनाम +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'पुरस्कृत विज्ञापन उपलब्ध नहीं है';

  @override
  String rateBoosted(String rate) {
    return 'दर में वृद्धि: +$rate ETA/घंटा';
  }

  @override
  String adBonusFailed(String message) {
    return 'विज्ञापन बोनस विफल: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'दर विवरण: आधार $base, लकीर +$streak, रैंक +$rank, रेफरल +$referrals = $total ETA/घंटा';
  }

  @override
  String get unableToStartMining =>
      'खनन शुरू करने में असमर्थ। कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें।';

  @override
  String get createCommunityCoin => 'सामुदायिक सिक्का बनाएं';

  @override
  String get launchCoinDescription =>
      'तुरंत ETA नेटवर्क पर अपना खुद का सिक्का लॉन्च करें।';

  @override
  String get createYourOwnCoin => 'अपना खुद का सिक्का बनाएं';

  @override
  String get launchCommunityCoinDescription =>
      'अपना खुद का सामुदायिक सिक्का लॉन्च करें जिसे अन्य ETA उपयोगकर्ता माइन कर सकें।';

  @override
  String get editCoin => 'सिक्का संपादित करें';

  @override
  String baseRate(String rate) {
    return 'आधार दर: $rate सिक्के/घंटा';
  }

  @override
  String createdBy(String username) {
    return '@$username द्वारा बनाया गया';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/घंटा';
  }

  @override
  String get noCoinsYet => 'अभी तक कोई सिक्के नहीं। लाइव सिक्कों से जोड़ें।';

  @override
  String get mine => 'माइन';

  @override
  String get remaining => 'शेष';

  @override
  String get holders => 'धारक';

  @override
  String get close => 'बंद करें';

  @override
  String get readMore => 'और पढ़ें';

  @override
  String get readLess => 'कम पढ़ें';

  @override
  String get projectLinks => 'प्रोजेक्ट लिंक';

  @override
  String get verifyEmailTitle => 'अपना ईमेल सत्यापित करें';

  @override
  String get verifyEmailMessage =>
      'हमने आपके ईमेल पते पर एक सत्यापन लिंक भेजा है। सभी सुविधाओं को अनलॉक करने के लिए कृपया अपना खाता सत्यापित करें।';

  @override
  String get resendEmail => 'ईमेल पुनः भेजें';

  @override
  String get iHaveVerified => 'मैंने सत्यापित कर लिया है';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get emailVerifiedSuccess => 'ईमेल सफलतापूर्वक सत्यापित!';

  @override
  String get emailNotVerified =>
      'ईमेल अभी सत्यापित नहीं हुआ है। कृपया अपना इनबॉक्स जांचें।';

  @override
  String get verificationEmailSent => 'सत्यापन ईमेल भेजा गया';

  @override
  String get startMining => 'खनन शुरू करें';

  @override
  String get minedCoins => 'माइन किए गए सिक्के';

  @override
  String get liveCoins => 'लाइव सिक्के';

  @override
  String get asset => 'संपत्ति';

  @override
  String get filterStatus => 'स्थिति';

  @override
  String get filterPopular => 'लोकप्रिय';

  @override
  String get filterNames => 'नाम';

  @override
  String get filterOldNew => 'पुराना - नया';

  @override
  String get filterNewOld => 'नया - पुराना';

  @override
  String startMiningWithCount(int count) {
    return 'खनन शुरू करें ($count)';
  }

  @override
  String get clearSelection => 'चयन साफ़ करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get refreshStatus => 'स्थिति ताज़ा करें';

  @override
  String get purchaseFailed => 'खरीद विफल';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play के माध्यम से सुरक्षित भुगतान';

  @override
  String get addedToMinedCoins => 'माइन किए गए सिक्कों में जोड़ा गया';

  @override
  String failedToAdd(String message) {
    return 'जोड़ने में विफल: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'सदस्यता केवल Android/iOS पर उपलब्ध है।';

  @override
  String get miningRate => 'खनन दर';

  @override
  String get about => 'बारे में';

  @override
  String get yourMined => 'आपका माइन किया हुआ';

  @override
  String get totalMined => 'कुल माइन किया हुआ';

  @override
  String get noReferrals => 'अभी तक कोई रेफरल नहीं';

  @override
  String get linkCopied => 'लिंक कॉपी किया गया';

  @override
  String get copy => 'कॉपी करें';

  @override
  String get howItWorks => 'यह कैसे काम करता है';

  @override
  String get referralDescription =>
      'दोस्तों के साथ अपना कोड साझा करें। जब वे शामिल होते हैं और सक्रिय होते हैं, तो आपकी टीम बढ़ती है और आपकी कमाई की क्षमता में सुधार होता है।';

  @override
  String get yourTeam => 'आपकी टीम';

  @override
  String get referralsTitle => 'रेफरल';

  @override
  String get shareLinkTitle => 'लिंक साझा करें';

  @override
  String get copyLinkInstruction => 'साझा करने के लिए इस लिंक को कॉपी करें:';

  @override
  String get referralCodeCopied => 'रेफरल कोड कॉपी किया गया';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network पर मेरे साथ जुड़ें! मेरे कोड का उपयोग करें: $code $link';
  }

  @override
  String get etaNetwork => 'ETA नेटवर्क';

  @override
  String get noLiveCommunityCoins => 'कोई लाइव सामुदायिक सिक्के नहीं';

  @override
  String get rate => 'दर';

  @override
  String get filterRandom => 'यादृच्छिक';

  @override
  String get baseRateLabel => 'आधार दर';

  @override
  String startFailed(String error) {
    return 'प्रारंभ विफल: $error';
  }

  @override
  String get sessionProgress => 'सत्र प्रगति';

  @override
  String get remainingLabel => 'शेष';

  @override
  String get boostRate => 'बूस्ट दर';

  @override
  String get minedLabel => 'माइन किया गया';

  @override
  String get noSubscriptionPlansAvailable => 'कोई सदस्यता योजना उपलब्ध नहीं है';

  @override
  String get subscriptionPlans => 'सदस्यता योजनाएं';

  @override
  String get recommended => 'अनुशंसित';

  @override
  String get editCommunityCoin => 'सामुदायिक सिक्का संपादित करें';

  @override
  String get launchCoinEcosystemDescription =>
      'अपने समुदाय के लिए ETA पारिस्थितिकी तंत्र के अंदर अपना खुद का सिक्का लॉन्च करें।';

  @override
  String get upload => 'अपलोड करें';

  @override
  String get recommendedImageSize => 'अनुशंसित 200x200px';

  @override
  String get coinNameLabel => 'सिक्का नाम';

  @override
  String get symbolLabel => 'प्रतीक';

  @override
  String get descriptionLabel => 'विवरण';

  @override
  String get baseMiningRateLabel => 'आधार खनन दर (सिक्के/घंटा)';

  @override
  String maxAllowed(String max) {
    return 'अधिकतम अनुमत : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'सामाजिक और प्रोजेक्ट लिंक (वैकल्पिक)';

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
  String get pasteUrl => 'URL पेस्ट करें';

  @override
  String get importantNoticeTitle => 'महत्वपूर्ण सूचना';

  @override
  String get importantNoticeBody =>
      'यह सिक्का ETA नेटवर्क पारिस्थितिकी तंत्र का हिस्सा है और एक बढ़ते डिजिटल समुदाय में भागीदारी का प्रतिनिधित्व करता है। सामुदायिक सिक्के उपयोगकर्ताओं द्वारा नेटवर्क के भीतर निर्माण, प्रयोग और जुड़ने के लिए बनाए जाते हैं। ETA नेटवर्क विकास के प्रारंभिक चरण में है। जैसे-जैसे पारिस्थितिकी तंत्र बढ़ता है, सामुदायिक गतिविधि, मंच विकास और लागू दिशानिर्देशों के आधार पर नई उपयोगिताएँ, सुविधाएँ और एकीकरण पेश किए जा सकते हैं।';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get save => 'सहेजें';

  @override
  String createCoinFailed(String error) {
    return 'सिक्का बनाने में विफल: $error';
  }

  @override
  String get coinNameLengthError => 'सिक्का नाम 3-30 वर्णों का होना चाहिए।';

  @override
  String get symbolRequiredError => 'प्रतीक आवश्यक है।';

  @override
  String get symbolLengthError => 'प्रतीक 2-6 अक्षर/संख्या होना चाहिए।';

  @override
  String get descriptionTooLongError => 'विवरण बहुत लंबा है।';

  @override
  String baseRateRangeError(String max) {
    return 'आधार खनन दर 0.000000001 और $max के बीच होनी चाहिए।';
  }

  @override
  String get coinNameExistsError =>
      'सिक्का नाम पहले से मौजूद है। कृपया दूसरा चुनें।';

  @override
  String get symbolExistsError => 'प्रतीक पहले से मौजूद है। कृपया दूसरा चुनें।';

  @override
  String get urlInvalidError => 'URL में से एक अमान्य है।';

  @override
  String get subscribeAndBoost => 'सदस्यता लें और खनन को बढ़ावा दें';

  @override
  String get autoCollect => 'स्वतः संग्रह';

  @override
  String autoMineCoins(int count) {
    return '$count सिक्कों का स्वतः खनन करें';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% गति';
  }

  @override
  String get perHourSuffix => '/घंटा';

  @override
  String get etaPerHourSuffix => 'ETA/घंटा';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'कोई विवरण उपलब्ध नहीं है।';

  @override
  String get unknownUser => 'अज्ञात';

  @override
  String get streakLabel => 'लकीर';

  @override
  String get referralsLabel => 'रेफरल';

  @override
  String get sessionsLabel => 'सत्र';

  @override
  String get accountInfoSection => 'खाता जानकारी';

  @override
  String get accountInfoTile => 'खाता जानकारी';

  @override
  String get invitedByPrompt => 'क्या किसी ने आमंत्रित किया?';

  @override
  String get enterReferralCode => 'रेफरल कोड दर्ज करें';

  @override
  String get invitedStatus => 'आमंत्रित';

  @override
  String get lockedStatus => 'लॉक किया गया';

  @override
  String get applyButton => 'लागू करें';

  @override
  String get aboutPageTitle => 'बारे में';

  @override
  String get faqTile => 'सामान्य प्रश्न';

  @override
  String get whitePaperTile => 'श्वेत पत्र';

  @override
  String get contactUsTile => 'संपर्क करें';

  @override
  String get securitySettingsTile => 'सुरक्षा सेटिंग्स';

  @override
  String get securitySettingsPageTitle => 'सुरक्षा सेटिंग्स';

  @override
  String get deleteAccountTile => 'खाता हटाएं';

  @override
  String get deleteAccountSubtitle => 'अपना खाता और डेटा स्थायी रूप से हटाएं';

  @override
  String get deleteAccountDialogTitle => 'खाता हटाएं?';

  @override
  String get deleteAccountDialogContent =>
      'यह आपके खाते, डेटा और सत्रों को स्थायी रूप से हटा देगा। यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get deleteButton => 'हटाएं';

  @override
  String get kycVerificationTile => 'KYC सत्यापन';

  @override
  String get kycVerificationDialogTitle => 'KYC सत्यापन';

  @override
  String get kycComingSoonMessage => 'आने वाले चरणों में सक्रिय किया जाएगा।';

  @override
  String get okButton => 'ठीक है';

  @override
  String get logOutLabel => 'लॉग आउट';

  @override
  String get confirmDeletionTitle => 'हटाने की पुष्टि करें';

  @override
  String get enterAccountPassword => 'खाता पासवर्ड दर्ज करें';

  @override
  String get confirmButton => 'पुष्टि करें';

  @override
  String get usernameLabel => 'उपयोगकर्ता नाम';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get nameLabel => 'नाम';

  @override
  String get ageLabel => 'आयु';

  @override
  String get countryLabel => 'देश';

  @override
  String get addressLabel => 'पता';

  @override
  String get genderLabel => 'लिंग';

  @override
  String get enterUsernameHint => 'उपयोगकर्ता नाम दर्ज करें';

  @override
  String get enterNameHint => 'नाम दर्ज करें';

  @override
  String get enterAgeHint => 'आयु दर्ज करें';

  @override
  String get enterCountryHint => 'देश दर्ज करें';

  @override
  String get enterAddressHint => 'पता दर्ज करें';

  @override
  String get enterGenderHint => 'लिंग दर्ज करें';

  @override
  String get savingLabel => 'सहेजा जा रहा है...';

  @override
  String get usernameEmptyError => 'उपयोगकर्ता नाम खाली नहीं हो सकता';

  @override
  String get invalidAgeError => 'अमान्य आयु मान';

  @override
  String get saveError => 'परिवर्तनों को सहेजने में विफल';

  @override
  String get cancelButton => 'रद्द करें';
}
