// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Telugu (`te`).
class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe([String locale = 'te']) : super(locale);

  @override
  String get totalBalance => 'మొత్తం నిల్వ';

  @override
  String joinedDate(String link, Object date) {
    return '$dateన చేరారు';
  }

  @override
  String get inviteEarn => 'ఆహ్వానించండి & సంపాదించండి';

  @override
  String get shareCodeDescription =>
      'మీ మైనింగ్ రేటును పెంచడానికి మీ ప్రత్యేక కోడ్‌ను స్నేహితులతో పంచుకోండి.';

  @override
  String get shareLink => 'లింక్‌ని షేర్ చేయండి';

  @override
  String get totalInvited => 'మొత్తం ఆహ్వానించబడినవారు';

  @override
  String get activeNow => 'ఇప్పుడు యాక్టివ్‌గా ఉన్నారు';

  @override
  String get viewAll => 'అన్నీ చూడండి';

  @override
  String get createCoin => 'కాయిన్‌ని సృష్టించండి';

  @override
  String get mining => 'మైనింగ్';

  @override
  String get settings => 'సెట్టింగ్‌లు';

  @override
  String get language => 'భాష';

  @override
  String get languageSubtitle => 'యాప్ భాషను మార్చండి';

  @override
  String get selectLanguage => 'భాషను ఎంచుకోండి';

  @override
  String get balanceTitle => 'నిల్వ';

  @override
  String get home => 'హోమ్';

  @override
  String get referral => 'రెఫరల్';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get dayStreak => 'రోజుల స్ట్రీక్';

  @override
  String dayStreakValue(int count) {
    return '$count రోజుల స్ట్రీక్';
  }

  @override
  String get active => 'యాక్టివ్';

  @override
  String get inactive => 'ఇన్‌యాక్టివ్';

  @override
  String get sessionEndsIn => 'సెషన్ ముగుస్తుంది';

  @override
  String get startEarning => 'సంపాదన ప్రారంభించండి';

  @override
  String get loadingAd => 'ప్రకటన లోడ్ అవుతోంది...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds సెకన్లు వేచి ఉండండి';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'రివార్డ్ +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'రివార్డెడ్ ప్రకటన అందుబాటులో లేదు';

  @override
  String rateBoosted(String rate) {
    return 'రేటు పెరిగింది: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'ప్రకటన బోనస్ విఫలమైంది: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'రేటు వివరాలు: బేస్ $base, స్ట్రీక్ +$streak, ర్యాంక్ +$rank, రెఫరల్స్ +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'మైనింగ్ ప్రారంభించడం సాధ్యం కాలేదు. దయచేసి మీ ఇంటర్నెట్ కనెక్షన్‌ని తనిఖీ చేసి మళ్లీ ప్రయత్నించండి.';

  @override
  String get createCommunityCoin => 'కమ్యూనిటీ కాయిన్‌ని సృష్టించండి';

  @override
  String get launchCoinDescription =>
      'ETA నెట్‌వర్క్‌లో మీ స్వంత కాయిన్‌ని తక్షణమే ప్రారంభించండి.';

  @override
  String get createYourOwnCoin => 'మీ స్వంత కాయిన్‌ని సృష్టించండి';

  @override
  String get launchCommunityCoinDescription =>
      'ఇతర ETA వినియోగదారులు మైన్ చేయగల మీ స్వంత కమ్యూనిటీ కాయిన్‌ని ప్రారంభించండి.';

  @override
  String get editCoin => 'కాయిన్‌ని సవరించండి';

  @override
  String baseRate(String rate) {
    return 'బేస్ రేటు: $rate కాయిన్స్/గంట';
  }

  @override
  String createdBy(String username) {
    return '@$username ద్వారా సృష్టించబడింది';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'ఇంకా కాయిన్స్ లేవు. లైవ్ కాయిన్స్ నుండి జోడించండి.';

  @override
  String get mine => 'మైన్';

  @override
  String get remaining => 'మిగిలినవి';

  @override
  String get holders => 'హోల్డర్లు';

  @override
  String get close => 'మూసివేయండి';

  @override
  String get readMore => 'మరింత చదవండి';

  @override
  String get readLess => 'తక్కువ చదవండి';

  @override
  String get projectLinks => 'ప్రాజెక్ట్ లింకులు';

  @override
  String get verifyEmailTitle => 'మీ ఇమెయిల్‌ని ధృవీకరించండి';

  @override
  String get verifyEmailMessage =>
      'మేము మీ ఇమెయిల్ చిరునామాకు ధృవీకరణ లింక్‌ని పంపాము. అన్ని ఫీచర్లను అన్‌లాక్ చేయడానికి దయచేసి మీ ఖాతాను ధృవీకరించండి.';

  @override
  String get resendEmail => 'ఇమెయిల్‌ని మళ్లీ పంపండి';

  @override
  String get iHaveVerified => 'నేను ధృవీకరించాను';

  @override
  String get logout => 'లాగౌట్';

  @override
  String get emailVerifiedSuccess => 'ఇమెయిల్ విజయవంతంగా ధృవీకరించబడింది!';

  @override
  String get emailNotVerified =>
      'ఇమెయిల్ ఇంకా ధృవీకరించబడలేదు. దయచేసి మీ ఇన్‌బాక్స్‌ని తనిఖీ చేయండి.';

  @override
  String get verificationEmailSent => 'ధృవీకరణ ఇమెయిల్ పంపబడింది';

  @override
  String get startMining => 'మైనింగ్ ప్రారంభించండి';

  @override
  String get minedCoins => 'మైన్ చేసిన కాయిన్స్';

  @override
  String get liveCoins => 'లైవ్ కాయిన్స్';

  @override
  String get asset => 'ఆస్తి';

  @override
  String get filterStatus => 'స్థితి';

  @override
  String get filterPopular => 'ప్రసిద్ధ';

  @override
  String get filterNames => 'పేర్లు';

  @override
  String get filterOldNew => 'పాత - కొత్త';

  @override
  String get filterNewOld => 'కొత్త - పాత';

  @override
  String startMiningWithCount(int count) {
    return 'మైనింగ్ ప్రారంభించండి ($count)';
  }

  @override
  String get clearSelection => 'ఎంపికను క్లియర్ చేయండి';

  @override
  String get cancel => 'రద్దు';

  @override
  String get refreshStatus => 'స్థితిని రిఫ్రెష్ చేయండి';

  @override
  String get purchaseFailed => 'కొనుగోలు విఫలమైంది';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play ద్వారా సురక్షిత చెల్లింపు';

  @override
  String get addedToMinedCoins => 'మైన్ చేసిన కాయిన్స్‌కి జోడించబడింది';

  @override
  String failedToAdd(String message) {
    return 'జోడించడం విఫలమైంది: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'సబ్‌స్క్రిప్షన్‌లు Android/iOSలో మాత్రమే అందుబాటులో ఉన్నాయి.';

  @override
  String get miningRate => 'మైనింగ్ రేటు';

  @override
  String get about => 'గురించి';

  @override
  String get yourMined => 'మీరు మైన్ చేసినవి';

  @override
  String get totalMined => 'మొత్తం మైన్ చేసినవి';

  @override
  String get noReferrals => 'ఇంకా రెఫరల్స్ లేవు';

  @override
  String get linkCopied => 'లింక్ కాపీ చేయబడింది';

  @override
  String get copy => 'కాపీ';

  @override
  String get howItWorks => 'ఇది ఎలా పనిచేస్తుంది';

  @override
  String get referralDescription =>
      'మీ కోడ్‌ని స్నేహితులతో పంచుకోండి. వారు చేరి యాక్టివ్‌గా ఉన్నప్పుడు, మీ టీమ్ పెరుగుతుంది మరియు మీ సంపాదన సామర్థ్యం మెరుగుపడుతుంది.';

  @override
  String get yourTeam => 'మీ టీమ్';

  @override
  String get referralsTitle => 'రెఫరల్స్';

  @override
  String get shareLinkTitle => 'లింక్‌ని షేర్ చేయండి';

  @override
  String get copyLinkInstruction => 'షేర్ చేయడానికి ఈ లింక్‌ని కాపీ చేయండి:';

  @override
  String get referralCodeCopied => 'రెఫరల్ కోడ్ కాపీ చేయబడింది';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Networkలో నాతో చేరండి! నా కోడ్‌ని ఉపయోగించండి: $code $link';
  }

  @override
  String get etaNetwork => 'ETA నెట్‌వర్క్';

  @override
  String get noLiveCommunityCoins => 'లైవ్ కమ్యూనిటీ కాయిన్స్ లేవు';

  @override
  String get rate => 'రేటు';

  @override
  String get filterRandom => 'యాదృచ్ఛిక';

  @override
  String get baseRateLabel => 'బేస్ రేటు';

  @override
  String startFailed(String error) {
    return 'ప్రారంభించడం విఫలమైంది: $error';
  }

  @override
  String get sessionProgress => 'సెషన్ పురోగతి';

  @override
  String get remainingLabel => 'మిగిలినవి';

  @override
  String get boostRate => 'బూస్ట్ రేటు';

  @override
  String get minedLabel => 'మైన్ చేయబడింది';

  @override
  String get noSubscriptionPlansAvailable =>
      'సబ్‌స్క్రిప్షన్ ప్లాన్‌లు అందుబాటులో లేవు';

  @override
  String get subscriptionPlans => 'సబ్‌స్క్రిప్షన్ ప్లాన్‌లు';

  @override
  String get recommended => 'సిఫార్సు చేయబడింది';

  @override
  String get editCommunityCoin => 'కమ్యూనిటీ కాయిన్‌ని సవరించండి';

  @override
  String get launchCoinEcosystemDescription =>
      'మీ కమ్యూనిటీ కోసం ETA ఎకోసిస్టమ్‌లో మీ స్వంత కాయిన్‌ని ప్రారంభించండి.';

  @override
  String get upload => 'అప్‌లోడ్';

  @override
  String get recommendedImageSize => 'సిఫార్సు చేయబడింది 200x200px';

  @override
  String get coinNameLabel => 'కాయిన్ పేరు';

  @override
  String get symbolLabel => 'సింబల్';

  @override
  String get descriptionLabel => 'వివరణ';

  @override
  String get baseMiningRateLabel => 'బేస్ మైనింగ్ రేటు (కాయిన్స్/గంట)';

  @override
  String maxAllowed(String max) {
    return 'గరిష్టంగా అనుమతించబడినది : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'సోషల్ & ప్రాజెక్ట్ లింకులు (ఐచ్ఛికం)';

  @override
  String get linkTypeWebsite => 'వెబ్‌సైట్';

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
  String get linkTypeOther => 'ఇతర';

  @override
  String get pasteUrl => 'URLని పేస్ట్ చేయండి';

  @override
  String get importantNoticeTitle => 'ముఖ్యమైన గమనిక';

  @override
  String get importantNoticeBody =>
      'ఈ కాయిన్ ETA నెట్‌వర్క్ ఎకోసిస్టమ్‌లో భాగం మరియు పెరుగుతున్న డిజిటల్ కమ్యూనిటీలో పాల్గొనడాన్ని సూచిస్తుంది. నెట్‌వర్క్‌లో నిర్మించడానికి, ప్రయోగాలు చేయడానికి మరియు పాల్గొనడానికి వినియోగదారులు కమ్యూనిటీ కాయిన్స్‌ని సృష్టిస్తారు. ETA నెట్‌వర్క్ అభివృద్ధి ప్రారంభ దశలో ఉంది. ఎకోసిస్టమ్ పెరిగేకొద్దీ, కమ్యూనిటీ కార్యాచరణ, ప్లాట్‌ఫారమ్ పరిణామం మరియు వర్తించే మార్గదర్శకాల ఆధారంగా కొత్త యుటిలిటీలు, ఫీచర్లు మరియు ఇంటిగ్రేషన్‌లు పరిచయం చేయబడవచ్చు.';

  @override
  String get pleaseWait => 'దయచేసి వేచి ఉండండి...';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String createCoinFailed(String error) {
    return 'కాయిన్ సృష్టించడం విఫలమైంది: $error';
  }

  @override
  String get coinNameLengthError => 'కాయిన్ పేరు 3-30 అక్షరాలు ఉండాలి.';

  @override
  String get symbolRequiredError => 'సింబల్ అవసరం.';

  @override
  String get symbolLengthError => 'సింబల్ 2-6 అక్షరాలు/సంఖ్యలు ఉండాలి.';

  @override
  String get descriptionTooLongError => 'వివరణ చాలా పొడవుగా ఉంది.';

  @override
  String baseRateRangeError(String max) {
    return 'బేస్ మైనింగ్ రేటు 0.000000001 మరియు $max మధ్య ఉండాలి.';
  }

  @override
  String get coinNameExistsError =>
      'కాయిన్ పేరు ఇప్పటికే ఉంది. దయచేసి మరొకటి ఎంచుకోండి.';

  @override
  String get symbolExistsError =>
      'సింబల్ ఇప్పటికే ఉంది. దయచేసి మరొకటి ఎంచుకోండి.';

  @override
  String get urlInvalidError => 'URLలలో ఒకటి చెల్లదు.';

  @override
  String get subscribeAndBoost => 'సబ్‌స్క్రైబ్ చేయండి & మైనింగ్‌ని పెంచండి';

  @override
  String get autoCollect => 'ఆటో కలెక్ట్';

  @override
  String autoMineCoins(int count) {
    return '$count కాయిన్స్‌ని ఆటో మైన్ చేయండి';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% వేగం';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'వివరణ అందుబాటులో లేదు.';

  @override
  String get unknownUser => 'తెలియదు';

  @override
  String get streakLabel => 'స్ట్రీక్';

  @override
  String get referralsLabel => 'రెఫరల్స్';

  @override
  String get sessionsLabel => 'సెషన్లు';

  @override
  String get accountInfoSection => 'ఖాతా సమాచారం';

  @override
  String get accountInfoTile => 'ఖాతా సమాచారం';

  @override
  String get invitedByPrompt => 'ఎవరైనా ఆహ్వానించారా?';

  @override
  String get enterReferralCode => 'రెఫరల్ కోడ్‌ని నమోదు చేయండి';

  @override
  String get invitedStatus => 'ఆహ్వానించబడ్డారు';

  @override
  String get lockedStatus => 'లాక్ చేయబడింది';

  @override
  String get applyButton => 'వర్తించు';

  @override
  String get aboutPageTitle => 'గురించి';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'వైట్ పేపర్';

  @override
  String get contactUsTile => 'మమ్మల్ని సంప్రదించండి';

  @override
  String get securitySettingsTile => 'భద్రతా సెట్టింగ్‌లు';

  @override
  String get securitySettingsPageTitle => 'భద్రతా సెట్టింగ్‌లు';

  @override
  String get deleteAccountTile => 'ఖాతాను తొలగించండి';

  @override
  String get deleteAccountSubtitle =>
      'మీ ఖాతా మరియు డేటాను శాశ్వతంగా తొలగించండి';

  @override
  String get deleteAccountDialogTitle => 'ఖాతాను తొలగించాలా?';

  @override
  String get deleteAccountDialogContent =>
      'ఇది మీ ఖాతా, డేటా మరియు సెషన్‌లను శాశ్వతంగా తొలగిస్తుంది. ఈ చర్యను రద్దు చేయడం సాధ్యం కాదు.';

  @override
  String get deleteButton => 'తొలగించు';

  @override
  String get kycVerificationTile => 'KYC ధృవీకరణ';

  @override
  String get kycVerificationDialogTitle => 'KYC ధృవీకరణ';

  @override
  String get kycComingSoonMessage => 'రాబోయే దశల్లో యాక్టివేట్ చేయబడుతుంది.';

  @override
  String get okButton => 'సరే';

  @override
  String get logOutLabel => 'లాగౌట్';

  @override
  String get confirmDeletionTitle => 'తొలగింపును నిర్ధారించండి';

  @override
  String get enterAccountPassword => 'ఖాతా పాస్‌వర్డ్‌ని నమోదు చేయండి';

  @override
  String get confirmButton => 'నిర్ధారించండి';

  @override
  String get usernameLabel => 'వినియోగదారు పేరు';

  @override
  String get emailLabel => 'ఇమెయిల్';

  @override
  String get nameLabel => 'పేరు';

  @override
  String get ageLabel => 'వయస్సు';

  @override
  String get countryLabel => 'దేశం';

  @override
  String get addressLabel => 'చిరునామా';

  @override
  String get genderLabel => 'లింగం';

  @override
  String get enterUsernameHint => 'వినియోగదారు పేరును నమోదు చేయండి';

  @override
  String get enterNameHint => 'పేరును నమోదు చేయండి';

  @override
  String get enterAgeHint => 'వయస్సును నమోదు చేయండి';

  @override
  String get enterCountryHint => 'దేశాన్ని నమోదు చేయండి';

  @override
  String get enterAddressHint => 'చిరునామాను నమోదు చేయండి';

  @override
  String get enterGenderHint => 'లింగాన్ని నమోదు చేయండి';

  @override
  String get savingLabel => 'సేవ్ చేస్తోంది...';

  @override
  String get usernameEmptyError => 'వినియోగదారు పేరు ఖాళీగా ఉండకూడదు';

  @override
  String get invalidAgeError => 'చెల్లని వయస్సు విలువ';

  @override
  String get saveError => 'మార్పులను సేవ్ చేయడం విఫలమైంది';

  @override
  String get cancelButton => 'రద్దు';
}
