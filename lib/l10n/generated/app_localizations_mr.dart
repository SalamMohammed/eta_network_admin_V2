// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get totalBalance => 'एकूण शिल्लक';

  @override
  String joinedDate(String link, Object date) {
    return '$date रोजी सामील झाले';
  }

  @override
  String get inviteEarn => 'आमंत्रित करा आणि कमवा';

  @override
  String get shareCodeDescription =>
      'तुमचा खाण दर वाढवण्यासाठी मित्रांसह तुमचा अद्वितीय कोड शेअर करा.';

  @override
  String get shareLink => 'लिंक शेअर करा';

  @override
  String get totalInvited => 'एकूण आमंत्रित';

  @override
  String get activeNow => 'आता सक्रिय';

  @override
  String get viewAll => 'सर्व पहा';

  @override
  String get createCoin => 'नाणे तयार करा';

  @override
  String get mining => 'खाणकाम';

  @override
  String get settings => 'सेटिंग्ज';

  @override
  String get language => 'भाषा';

  @override
  String get languageSubtitle => 'ॲप भाषा बदला';

  @override
  String get selectLanguage => 'भाषा निवडा';

  @override
  String get balanceTitle => 'शिल्लक';

  @override
  String get home => 'होम';

  @override
  String get referral => 'रेफरल';

  @override
  String get profile => 'प्रोफाइल';

  @override
  String get dayStreak => 'दिवसांची मालिका';

  @override
  String dayStreakValue(int count) {
    return '$count दिवसांची मालिका';
  }

  @override
  String get active => 'सक्रिय';

  @override
  String get inactive => 'निष्क्रिय';

  @override
  String get sessionEndsIn => 'सत्र समाप्त होईल';

  @override
  String get startEarning => 'कमवाण्यास सुरुवात करा';

  @override
  String get loadingAd => 'जाहिरात लोड होत आहे...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds सेकंद थांबा';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'बक्षीस +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'पुरस्कृत जाहिरात उपलब्ध नाही';

  @override
  String rateBoosted(String rate) {
    return 'दर वाढवला: +$rate ETA/तास';
  }

  @override
  String adBonusFailed(String message) {
    return 'जाहिरात बोनस अयशस्वी: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'दर तपशील: मूळ $base, मालिका +$streak, रँक +$rank, रेफरल्स +$referrals = $total ETA/तास';
  }

  @override
  String get unableToStartMining =>
      'खाणकाम सुरू करण्यात अक्षम. कृपया तुमचे इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.';

  @override
  String get createCommunityCoin => 'समुदाय नाणे तयार करा';

  @override
  String get launchCoinDescription =>
      'ETA नेटवर्कवर तुमचे स्वतःचे नाणे त्वरित लाँच करा.';

  @override
  String get createYourOwnCoin => 'तुमचे स्वतःचे नाणे तयार करा';

  @override
  String get launchCommunityCoinDescription =>
      'तुमचे स्वतःचे समुदाय नाणे लाँच करा जे इतर ETA वापरकर्ते खाण करू शकतात.';

  @override
  String get editCoin => 'नाणे संपादित करा';

  @override
  String baseRate(String rate) {
    return 'मूळ दर: $rate नाणी/तास';
  }

  @override
  String createdBy(String username) {
    return '@$username द्वारे तयार केले';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/तास';
  }

  @override
  String get noCoinsYet => 'अद्याप कोणतीही नाणी नाहीत. थेट नाण्यांमधून जोडा.';

  @override
  String get mine => 'खाण';

  @override
  String get remaining => 'उर्वरित';

  @override
  String get holders => 'धारक';

  @override
  String get close => 'बंद करा';

  @override
  String get readMore => 'अधिक वाचा';

  @override
  String get readLess => 'कमी वाचा';

  @override
  String get projectLinks => 'प्रकल्प लिंक्स';

  @override
  String get verifyEmailTitle => 'तुमचा ईमेल सत्यापित करा';

  @override
  String get verifyEmailMessage =>
      'आम्ही तुमच्या ईमेल पत्त्यावर सत्यापन लिंक पाठवली आहे. सर्व वैशिष्ट्ये अनलॉक करण्यासाठी कृपया तुमचे खाते सत्यापित करा.';

  @override
  String get resendEmail => 'ईमेल पुन्हा पाठवा';

  @override
  String get iHaveVerified => 'मी सत्यापित केले आहे';

  @override
  String get logout => 'लॉगआउट';

  @override
  String get emailVerifiedSuccess => 'ईमेल यशस्वीरित्या सत्यापित केला!';

  @override
  String get emailNotVerified =>
      'ईमेल अद्याप सत्यापित नाही. कृपया तुमचा इनबॉक्स तपासा.';

  @override
  String get verificationEmailSent => 'सत्यापन ईमेल पाठवला';

  @override
  String get startMining => 'खाणकाम सुरू करा';

  @override
  String get minedCoins => 'खाणलेली नाणी';

  @override
  String get liveCoins => 'थेट नाणी';

  @override
  String get asset => 'मालमत्ता';

  @override
  String get filterStatus => 'स्थिती';

  @override
  String get filterPopular => 'लोकप्रिय';

  @override
  String get filterNames => 'नावे';

  @override
  String get filterOldNew => 'जुने - नवीन';

  @override
  String get filterNewOld => 'नवीन - जुने';

  @override
  String startMiningWithCount(int count) {
    return 'खाणकाम सुरू करा ($count)';
  }

  @override
  String get clearSelection => 'निवड साफ करा';

  @override
  String get cancel => 'रद्द करा';

  @override
  String get refreshStatus => 'स्थिती रिफ्रेश करा';

  @override
  String get purchaseFailed => 'खरेदी अयशस्वी';

  @override
  String get securePaymentViaGooglePlay => 'Google Play द्वारे सुरक्षित पेमेंट';

  @override
  String get addedToMinedCoins => 'खाणलेल्या नाण्यांमध्ये जोडले';

  @override
  String failedToAdd(String message) {
    return 'जोडण्यात अयशस्वी: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'सदस्यता फक्त Android/iOS वर उपलब्ध आहेत.';

  @override
  String get miningRate => 'खाण दर';

  @override
  String get about => 'बद्दल';

  @override
  String get yourMined => 'तुमचे खाणलेले';

  @override
  String get totalMined => 'एकूण खाणलेले';

  @override
  String get noReferrals => 'अद्याप कोणतेही रेफरल नाहीत';

  @override
  String get linkCopied => 'लिंक कॉपी केली';

  @override
  String get copy => 'कॉपी';

  @override
  String get howItWorks => 'हे कसे कार्य करते';

  @override
  String get referralDescription =>
      'मित्रांसह तुमचा कोड शेअर करा. जेव्हा ते सामील होतात आणि सक्रिय होतात, तेव्हा तुमची टीम वाढते आणि तुमची कमाई क्षमता सुधारते.';

  @override
  String get yourTeam => 'तुमची टीम';

  @override
  String get referralsTitle => 'रेफरल्स';

  @override
  String get shareLinkTitle => 'लिंक शेअर करा';

  @override
  String get copyLinkInstruction => 'शेअर करण्यासाठी ही लिंक कॉपी करा:';

  @override
  String get referralCodeCopied => 'रेफरल कोड कॉपी केला';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network वर माझ्याशी सामील व्हा! माझा कोड वापरा: $code $link';
  }

  @override
  String get etaNetwork => 'ETA नेटवर्क';

  @override
  String get noLiveCommunityCoins => 'कोणतीही थेट समुदाय नाणी नाहीत';

  @override
  String get rate => 'दर';

  @override
  String get filterRandom => 'यादृच्छिक';

  @override
  String get baseRateLabel => 'मूळ दर';

  @override
  String startFailed(String error) {
    return 'सुरू करण्यात अयशस्वी: $error';
  }

  @override
  String get sessionProgress => 'सत्र प्रगती';

  @override
  String get remainingLabel => 'उर्वरित';

  @override
  String get boostRate => 'बूस्ट दर';

  @override
  String get minedLabel => 'खाणलेले';

  @override
  String get noSubscriptionPlansAvailable =>
      'कोणत्याही सदस्यता योजना उपलब्ध नाहीत';

  @override
  String get subscriptionPlans => 'सदस्यता योजना';

  @override
  String get recommended => 'शिफारस केलेले';

  @override
  String get editCommunityCoin => 'समुदाय नाणे संपादित करा';

  @override
  String get launchCoinEcosystemDescription =>
      'तुमच्या समुदायासाठी ETA इकोसिस्टममध्ये तुमचे स्वतःचे नाणे लाँच करा.';

  @override
  String get upload => 'अपलोड';

  @override
  String get recommendedImageSize => 'शिफारस केलेले 200x200px';

  @override
  String get coinNameLabel => 'नाण्याचे नाव';

  @override
  String get symbolLabel => 'प्रतीक';

  @override
  String get descriptionLabel => 'वर्णन';

  @override
  String get baseMiningRateLabel => 'मूळ खाण दर (नाणी/तास)';

  @override
  String maxAllowed(String max) {
    return 'कमाल अनुमत : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'सामाजिक आणि प्रकल्प लिंक्स (वैकल्पिक)';

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
  String get linkTypeOther => 'इतर';

  @override
  String get pasteUrl => 'URL पेस्ट करा';

  @override
  String get importantNoticeTitle => 'महत्वाची सूचना';

  @override
  String get importantNoticeBody =>
      'हे नाणे ETA नेटवर्क इकोसिस्टमचा भाग आहे आणि वाढत्या डिजिटल समुदायातील सहभागाचे प्रतिनिधित्व करते. समुदाय नाणी वापरकर्त्यांद्वारे नेटवर्कमध्ये तयार करण्यासाठी, प्रयोग करण्यासाठी आणि सहभागी होण्यासाठी तयार केली जातात. ETA नेटवर्क विकासाच्या सुरुवातीच्या टप्प्यात आहे. जसे इकोसिस्टम वाढते, समुदाय क्रियाकलाप, प्लॅटफॉर्म उत्क्रांती आणि लागू मार्गदर्शक तत्त्वांवर आधारित नवीन उपयुक्तता, वैशिष्ट्ये आणि एकत्रीकरण सादर केले जाऊ शकतात.';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करा...';

  @override
  String get save => 'जतन करा';

  @override
  String createCoinFailed(String error) {
    return 'नाणे तयार करण्यात अयशस्वी: $error';
  }

  @override
  String get coinNameLengthError => 'नाण्याचे नाव 3-30 अक्षरे असावे.';

  @override
  String get symbolRequiredError => 'प्रतीक आवश्यक आहे.';

  @override
  String get symbolLengthError => 'प्रतीक 2-6 अक्षरे/संख्या असावे.';

  @override
  String get descriptionTooLongError => 'वर्णन खूप मोठे आहे.';

  @override
  String baseRateRangeError(String max) {
    return 'मूळ खाण दर 0.000000001 आणि $max दरम्यान असावा.';
  }

  @override
  String get coinNameExistsError =>
      'नाण्याचे नाव आधीच अस्तित्वात आहे. कृपया दुसरे निवडा.';

  @override
  String get symbolExistsError =>
      'प्रतीक आधीच अस्तित्वात आहे. कृपया दुसरे निवडा.';

  @override
  String get urlInvalidError => 'URL पैकी एक अवैध आहे.';

  @override
  String get subscribeAndBoost => 'सदस्यता घ्या आणि खाण वाढवा';

  @override
  String get autoCollect => 'ऑटो कलेक्ट';

  @override
  String autoMineCoins(int count) {
    return '$count नाणी ऑटो माइन करा';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% गती';
  }

  @override
  String get perHourSuffix => '/तास';

  @override
  String get etaPerHourSuffix => 'ETA/तास';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'कोणतेही वर्णन उपलब्ध नाही.';

  @override
  String get unknownUser => 'अज्ञात';

  @override
  String get streakLabel => 'मालिका';

  @override
  String get referralsLabel => 'रेफरल्स';

  @override
  String get sessionsLabel => 'सत्रे';

  @override
  String get accountInfoSection => 'खाते माहिती';

  @override
  String get accountInfoTile => 'खाते माहिती';

  @override
  String get invitedByPrompt => 'कोणी आमंत्रित केले?';

  @override
  String get enterReferralCode => 'रेफरल कोड प्रविष्ट करा';

  @override
  String get invitedStatus => 'आमंत्रित';

  @override
  String get lockedStatus => 'लॉक केलेले';

  @override
  String get applyButton => 'लागू करा';

  @override
  String get aboutPageTitle => 'बद्दल';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'श्वेतपत्रिका';

  @override
  String get contactUsTile => 'आमच्याशी संपर्क साधा';

  @override
  String get securitySettingsTile => 'सुरक्षा सेटिंग्ज';

  @override
  String get securitySettingsPageTitle => 'सुरक्षा सेटिंग्ज';

  @override
  String get deleteAccountTile => 'खाते हटवा';

  @override
  String get deleteAccountSubtitle => 'तुमचे खाते आणि डेटा कायमचे हटवा';

  @override
  String get deleteAccountDialogTitle => 'खाते हटवायचे?';

  @override
  String get deleteAccountDialogContent =>
      'हे तुमचे खाते, डेटा आणि सत्रे कायमचे हटवेल. ही क्रिया पूर्ववत केली जाऊ शकत नाही.';

  @override
  String get deleteButton => 'हटवा';

  @override
  String get kycVerificationTile => 'KYC सत्यापन';

  @override
  String get kycVerificationDialogTitle => 'KYC सत्यापन';

  @override
  String get kycComingSoonMessage => 'येणाऱ्या टप्प्यांमध्ये सक्रिय केले जाईल.';

  @override
  String get okButton => 'ठीक आहे';

  @override
  String get logOutLabel => 'लॉगआउट';

  @override
  String get confirmDeletionTitle => 'हटवण्याची पुष्टी करा';

  @override
  String get enterAccountPassword => 'खाते पासवर्ड प्रविष्ट करा';

  @override
  String get confirmButton => 'पुष्टी करा';

  @override
  String get usernameLabel => 'वापरकर्तानाव';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get nameLabel => 'नाव';

  @override
  String get ageLabel => 'वय';

  @override
  String get countryLabel => 'देश';

  @override
  String get addressLabel => 'पत्ता';

  @override
  String get genderLabel => 'लिंग';

  @override
  String get enterUsernameHint => 'वापरकर्तानाव प्रविष्ट करा';

  @override
  String get enterNameHint => 'नाव प्रविष्ट करा';

  @override
  String get enterAgeHint => 'वय प्रविष्ट करा';

  @override
  String get enterCountryHint => 'देश प्रविष्ट करा';

  @override
  String get enterAddressHint => 'पत्ता प्रविष्ट करा';

  @override
  String get enterGenderHint => 'लिंग प्रविष्ट करा';

  @override
  String get savingLabel => 'जतन करत आहे...';

  @override
  String get usernameEmptyError => 'वापरकर्तानाव रिकामे असू शकत नाही';

  @override
  String get invalidAgeError => 'अवैध वय मूल्य';

  @override
  String get saveError => 'बदल जतन करण्यात अयशस्वी';

  @override
  String get cancelButton => 'रद्द करा';
}
