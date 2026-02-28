// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get totalBalance => 'மொத்த இருப்பு';

  @override
  String joinedDate(String link, Object date) {
    return '$date இல் இணைந்தார்';
  }

  @override
  String get inviteEarn => 'அழைத்து சம்பாதிக்கவும்';

  @override
  String get shareCodeDescription =>
      'உங்கள் சுரங்க விகிதத்தை அதிகரிக்க நண்பர்களுடன் உங்கள் தனித்துவமான குறியீட்டைப் பகிரவும்.';

  @override
  String get shareLink => 'இணைப்பைப் பகிரவும்';

  @override
  String get totalInvited => 'மொத்தம் அழைக்கப்பட்டவர்கள்';

  @override
  String get activeNow => 'இப்போது செயலில்';

  @override
  String get viewAll => 'அனைத்தையும் காண்க';

  @override
  String get createCoin => 'நாணயத்தை உருவாக்கவும்';

  @override
  String get mining => 'சுரங்கம்';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get languageSubtitle => 'பயன்பாட்டு மொழியை மாற்றவும்';

  @override
  String get selectLanguage => 'மொழியைத் தேர்ந்தெடுக்கவும்';

  @override
  String get balanceTitle => 'இருப்பு';

  @override
  String get home => 'முகப்பு';

  @override
  String get referral => 'பரிந்துரை';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get dayStreak => 'நாள் தொடர்';

  @override
  String dayStreakValue(int count) {
    return '$count நாள் தொடர்';
  }

  @override
  String get active => 'செயலில்';

  @override
  String get inactive => 'செயலற்ற';

  @override
  String get sessionEndsIn => 'அமர்வு முடிவடைகிறது';

  @override
  String get startEarning => 'சம்பாதிக்கத் தொடங்குங்கள்';

  @override
  String get loadingAd => 'விளம்பரம் ஏற்றப்படுகிறது...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds வினாடிகள் காத்திருங்கள்';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'வெகுமதி +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'வெகுமதி விளம்பரம் கிடைக்கவில்லை';

  @override
  String rateBoosted(String rate) {
    return 'விகிதம் அதிகரிக்கப்பட்டது: +$rate ETA/மணி';
  }

  @override
  String adBonusFailed(String message) {
    return 'விளம்பர போனஸ் தோல்வியடைந்தது: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'விகித விவரம்: அடிப்படை $base, தொடர் +$streak, தரவரிசை +$rank, பரிந்துரைகள் +$referrals = $total ETA/மணி';
  }

  @override
  String get unableToStartMining =>
      'சுரங்கத்தைத் தொடங்க முடியவில்லை. உங்கள் இணைய இணைப்பைச் சரிபார்த்து மீண்டும் முயற்சிக்கவும்.';

  @override
  String get createCommunityCoin => 'சமூக நாணயத்தை உருவாக்கவும்';

  @override
  String get launchCoinDescription =>
      'ETA நெட்வொர்க்கில் உங்கள் சொந்த நாணயத்தை உடனடியாகத் தொடங்கவும்.';

  @override
  String get createYourOwnCoin => 'உங்கள் சொந்த நாணயத்தை உருவாக்கவும்';

  @override
  String get launchCommunityCoinDescription =>
      'மற்ற ETA பயனர்கள் சுரங்கக்கூடிய உங்கள் சொந்த சமூக நாணயத்தைத் தொடங்கவும்.';

  @override
  String get editCoin => 'நாணயத்தைத் திருத்தவும்';

  @override
  String baseRate(String rate) {
    return 'அடிப்படை விகிதம்: $rate நாணயங்கள்/மணி';
  }

  @override
  String createdBy(String username) {
    return '@$username ஆல் உருவாக்கப்பட்டது';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/மணி';
  }

  @override
  String get noCoinsYet =>
      'இன்னும் நாணயங்கள் இல்லை. நேரடி நாணயங்களிலிருந்து சேர்க்கவும்.';

  @override
  String get mine => 'சுரங்கம்';

  @override
  String get remaining => 'மீதமுள்ள';

  @override
  String get holders => 'வைத்திருப்பவர்கள்';

  @override
  String get close => 'மூடு';

  @override
  String get readMore => 'மேலும் படிக்க';

  @override
  String get readLess => 'குறைவாக படிக்க';

  @override
  String get projectLinks => 'திட்ட இணைப்புகள்';

  @override
  String get verifyEmailTitle => 'உங்கள் மின்னஞ்சலைச் சரிபார்க்கவும்';

  @override
  String get verifyEmailMessage =>
      'உங்கள் மின்னஞ்சல் முகவரிக்கு சரிபார்ப்பு இணைப்பை அனுப்பியுள்ளோம். அனைத்து அம்சங்களையும் திறக்க உங்கள் கணக்கைச் சரிபார்க்கவும்.';

  @override
  String get resendEmail => 'மின்னஞ்சலை மீண்டும் அனுப்பவும்';

  @override
  String get iHaveVerified => 'நான் சரிபார்த்துவிட்டேன்';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get emailVerifiedSuccess =>
      'மின்னஞ்சல் வெற்றிகரமாக சரிபார்க்கப்பட்டது!';

  @override
  String get emailNotVerified =>
      'மின்னஞ்சல் இன்னும் சரிபார்க்கப்படவில்லை. உங்கள் இன்பாக்ஸைச் சரிபார்க்கவும்.';

  @override
  String get verificationEmailSent => 'சரிபார்ப்பு மின்னஞ்சல் அனுப்பப்பட்டது';

  @override
  String get startMining => 'சுரங்கத்தைத் தொடங்கவும்';

  @override
  String get minedCoins => 'சுரங்க நாணயங்கள்';

  @override
  String get liveCoins => 'நேரடி நாணயங்கள்';

  @override
  String get asset => 'சொத்து';

  @override
  String get filterStatus => 'நிலை';

  @override
  String get filterPopular => 'பிரபலமான';

  @override
  String get filterNames => 'பெயர்கள்';

  @override
  String get filterOldNew => 'பழையது - புதியது';

  @override
  String get filterNewOld => 'புதியது - பழையது';

  @override
  String startMiningWithCount(int count) {
    return 'சுரங்கத்தைத் தொடங்கவும் ($count)';
  }

  @override
  String get clearSelection => 'தேர்வை அழிக்கவும்';

  @override
  String get cancel => 'ரத்துசெய்';

  @override
  String get refreshStatus => 'நிலையைப் புதுப்பிக்கவும்';

  @override
  String get purchaseFailed => 'கொள்முதல் தோல்வியடைந்தது';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play வழியாக பாதுகாப்பான கட்டணம்';

  @override
  String get addedToMinedCoins => 'சுரங்க நாணயங்களில் சேர்க்கப்பட்டது';

  @override
  String failedToAdd(String message) {
    return 'சேர்க்க முடியவில்லை: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'சந்தாக்கள் Android/iOS இல் மட்டுமே கிடைக்கும்.';

  @override
  String get miningRate => 'சுரங்க விகிதம்';

  @override
  String get about => 'பற்றி';

  @override
  String get yourMined => 'நீங்கள் சுரங்கம் செய்தது';

  @override
  String get totalMined => 'மொத்தம் சுரங்கம் செய்யப்பட்டது';

  @override
  String get noReferrals => 'இன்னும் பரிந்துரைகள் இல்லை';

  @override
  String get linkCopied => 'இணைப்பு நகலெடுக்கப்பட்டது';

  @override
  String get copy => 'நகலெடு';

  @override
  String get howItWorks => 'இது எப்படி வேலை செய்கிறது';

  @override
  String get referralDescription =>
      'நண்பர்களுடன் உங்கள் குறியீட்டைப் பகிரவும். அவர்கள் இணைந்து செயலில் ஈடுபடும்போது, உங்கள் குழு வளரும் மற்றும் உங்கள் சம்பாதிக்கும் திறன் மேம்படும்.';

  @override
  String get yourTeam => 'உங்கள் குழு';

  @override
  String get referralsTitle => 'பரிந்துரைகள்';

  @override
  String get shareLinkTitle => 'இணைப்பைப் பகிரவும்';

  @override
  String get copyLinkInstruction => 'பகிர இந்த இணைப்பை நகலெடுக்கவும்:';

  @override
  String get referralCodeCopied => 'பரிந்துரை குறியீடு நகலெடுக்கப்பட்டது';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network இல் என்னுடன் இணையுங்கள்! எனது குறியீட்டைப் பயன்படுத்தவும்: $code $link';
  }

  @override
  String get etaNetwork => 'ETA நெட்வொர்க்';

  @override
  String get noLiveCommunityCoins => 'நேரடி சமூக நாணயங்கள் இல்லை';

  @override
  String get rate => 'விகிதம்';

  @override
  String get filterRandom => 'சீரற்ற';

  @override
  String get baseRateLabel => 'அடிப்படை விகிதம்';

  @override
  String startFailed(String error) {
    return 'தொடங்க முடியவில்லை: $error';
  }

  @override
  String get sessionProgress => 'அமர்வு முன்னேற்றம்';

  @override
  String get remainingLabel => 'மீதமுள்ள';

  @override
  String get boostRate => 'விகிதத்தை அதிகரிக்கவும்';

  @override
  String get minedLabel => 'சுரங்கம் செய்யப்பட்டது';

  @override
  String get noSubscriptionPlansAvailable =>
      'சந்தா திட்டங்கள் எதுவும் கிடைக்கவில்லை';

  @override
  String get subscriptionPlans => 'சந்தா திட்டங்கள்';

  @override
  String get recommended => 'பரிந்துரைக்கப்பட்டது';

  @override
  String get editCommunityCoin => 'சமூக நாணயத்தைத் திருத்தவும்';

  @override
  String get launchCoinEcosystemDescription =>
      'உங்கள் சமூகத்திற்காக ETA சுற்றுச்சூழல் அமைப்பில் உங்கள் சொந்த நாணயத்தைத் தொடங்கவும்.';

  @override
  String get upload => 'பதிவேற்றவும்';

  @override
  String get recommendedImageSize => 'பரிந்துரைக்கப்பட்டது 200x200px';

  @override
  String get coinNameLabel => 'நாணயத்தின் பெயர்';

  @override
  String get symbolLabel => 'குறியீடு';

  @override
  String get descriptionLabel => 'விளக்கம்';

  @override
  String get baseMiningRateLabel => 'அடிப்படை சுரங்க விகிதம் (நாணயங்கள்/மணி)';

  @override
  String maxAllowed(String max) {
    return 'அதிகபட்சம் அனுமதிக்கப்பட்டது : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'சமூக & திட்ட இணைப்புகள் (விருப்பத்தேர்வு)';

  @override
  String get linkTypeWebsite => 'இணையதளம்';

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
  String get linkTypeOther => 'மற்றவை';

  @override
  String get pasteUrl => 'URL ஐ ஒட்டவும்';

  @override
  String get importantNoticeTitle => 'முக்கிய அறிவிப்பு';

  @override
  String get importantNoticeBody =>
      'இந்த நாணயம் ETA நெட்வொர்க் சுற்றுச்சூழல் அமைப்பின் ஒரு பகுதியாகும் மற்றும் வளர்ந்து வரும் டிஜிட்டல் சமூகத்தில் பங்கேற்பதைக் குறிக்கிறது. சமூக நாணயங்கள் பயனர்களால் நெட்வொர்க்கிற்குள் உருவாக்க, பரிசோதனை செய்ய மற்றும் ஈடுபட உருவாக்கப்படுகின்றன. ETA நெட்வொர்க் வளர்ச்சியின் ஆரம்ப கட்டத்தில் உள்ளது. சுற்றுச்சூழல் அமைப்பு வளரும்போது, சமூக செயல்பாடு, தள பரிணாமம் மற்றும் பொருந்தக்கூடிய வழிகாட்டுதல்களின் அடிப்படையில் புதிய பயன்பாடுகள், அம்சங்கள் மற்றும் ஒருங்கிணைப்புகள் அறிமுகப்படுத்தப்படலாம்.';

  @override
  String get pleaseWait => 'காத்திருக்கவும்...';

  @override
  String get save => 'சேமி';

  @override
  String createCoinFailed(String error) {
    return 'நாணயத்தை உருவாக்க முடியவில்லை: $error';
  }

  @override
  String get coinNameLengthError =>
      'நாணயத்தின் பெயர் 3-30 எழுத்துகளாக இருக்க வேண்டும்.';

  @override
  String get symbolRequiredError => 'குறியீடு தேவை.';

  @override
  String get symbolLengthError =>
      'குறியீடு 2-6 எழுத்துகள்/எண்களாக இருக்க வேண்டும்.';

  @override
  String get descriptionTooLongError => 'விளக்கம் மிக நீளமாக உள்ளது.';

  @override
  String baseRateRangeError(String max) {
    return 'அடிப்படை சுரங்க விகிதம் 0.000000001 மற்றும் $max இடையே இருக்க வேண்டும்.';
  }

  @override
  String get coinNameExistsError =>
      'நாணயத்தின் பெயர் ஏற்கனவே உள்ளது. தயவுசெய்து இன்னொன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get symbolExistsError =>
      'குறியீடு ஏற்கனவே உள்ளது. தயவுசெய்து இன்னொன்றைத் தேர்ந்தெடுக்கவும்.';

  @override
  String get urlInvalidError => 'URL களில் ஒன்று செல்லுபடியாகாது.';

  @override
  String get subscribeAndBoost => 'சந்தா மற்றும் சுரங்கத்தை அதிகரிக்கவும்';

  @override
  String get autoCollect => 'தானியங்கி சேகரிப்பு';

  @override
  String autoMineCoins(int count) {
    return '$count நாணயங்களை தானாக சுரங்கம் செய்யவும்';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% வேகம்';
  }

  @override
  String get perHourSuffix => '/மணி';

  @override
  String get etaPerHourSuffix => 'ETA/மணி';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'விளக்கம் எதுவும் இல்லை.';

  @override
  String get unknownUser => 'தெரியாத';

  @override
  String get streakLabel => 'தொடர்';

  @override
  String get referralsLabel => 'பரிந்துரைகள்';

  @override
  String get sessionsLabel => 'அமர்வுகள்';

  @override
  String get accountInfoSection => 'கணக்கு தகவல்';

  @override
  String get accountInfoTile => 'கணக்கு தகவல்';

  @override
  String get invitedByPrompt => 'யாராவது அழைத்தார்களா?';

  @override
  String get enterReferralCode => 'பரிந்துரை குறியீட்டை உள்ளிடவும்';

  @override
  String get invitedStatus => 'அழைக்கப்பட்டது';

  @override
  String get lockedStatus => 'பூட்டப்பட்டது';

  @override
  String get applyButton => 'விண்ணப்பிக்கவும்';

  @override
  String get aboutPageTitle => 'பற்றி';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'வெள்ளை அறிக்கை';

  @override
  String get contactUsTile => 'எங்களை தொடர்பு கொள்ளவும்';

  @override
  String get securitySettingsTile => 'பாதுகாப்பு அமைப்புகள்';

  @override
  String get securitySettingsPageTitle => 'பாதுகாப்பு அமைப்புகள்';

  @override
  String get deleteAccountTile => 'கணக்கை நீக்கவும்';

  @override
  String get deleteAccountSubtitle =>
      'உங்கள் கணக்கு மற்றும் தரவை நிரந்தரமாக நீக்கவும்';

  @override
  String get deleteAccountDialogTitle => 'கணக்கை நீக்கவா?';

  @override
  String get deleteAccountDialogContent =>
      'இது உங்கள் கணக்கு, தரவு மற்றும் அமர்வுகளை நிரந்தரமாக நீக்கும். இந்த செயலை செயல்தவிர்க்க முடியாது.';

  @override
  String get deleteButton => 'நீக்கு';

  @override
  String get kycVerificationTile => 'KYC சரிபார்ப்பு';

  @override
  String get kycVerificationDialogTitle => 'KYC சரிபார்ப்பு';

  @override
  String get kycComingSoonMessage => 'வரும் கட்டங்களில் செயல்படுத்தப்படும்.';

  @override
  String get okButton => 'சரி';

  @override
  String get logOutLabel => 'வெளியேறு';

  @override
  String get confirmDeletionTitle => 'நீக்குதலை உறுதிப்படுத்தவும்';

  @override
  String get enterAccountPassword => 'கணக்கு கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get confirmButton => 'உறுதிப்படுத்தவும்';

  @override
  String get usernameLabel => 'பயனர் பெயர்';

  @override
  String get emailLabel => 'மின்னஞ்சல்';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get ageLabel => 'வயது';

  @override
  String get countryLabel => 'நாடு';

  @override
  String get addressLabel => 'முகவரி';

  @override
  String get genderLabel => 'பாலினம்';

  @override
  String get enterUsernameHint => 'பயனர் பெயரை உள்ளிடவும்';

  @override
  String get enterNameHint => 'பெயரை உள்ளிடவும்';

  @override
  String get enterAgeHint => 'வயதை உள்ளிடவும்';

  @override
  String get enterCountryHint => 'நாட்டை உள்ளிடவும்';

  @override
  String get enterAddressHint => 'முகவரியை உள்ளிடவும்';

  @override
  String get enterGenderHint => 'பாலினத்தை உள்ளிடவும்';

  @override
  String get savingLabel => 'சேமிக்கிறது...';

  @override
  String get usernameEmptyError => 'பயனர் பெயர் காலியாக இருக்கக்கூடாது';

  @override
  String get invalidAgeError => 'செல்லுபடியாகாத வயது மதிப்பு';

  @override
  String get saveError => 'மாற்றங்களைச் சேமிக்க முடியவில்லை';

  @override
  String get cancelButton => 'ரத்துசெய்';
}
