// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hausa (`ha`).
class AppLocalizationsHa extends AppLocalizations {
  AppLocalizationsHa([String locale = 'ha']) : super(locale);

  @override
  String get totalBalance => 'Jimlar Ma\'auni';

  @override
  String joinedDate(String link, Object date) {
    return 'Ya shiga $date';
  }

  @override
  String get inviteEarn => 'Gayyata da Samu';

  @override
  String get shareCodeDescription =>
      'Raba keɓaɓɓen lambar ku tare da abokai don haɓaka ƙimar hakar ma\'adinai.';

  @override
  String get shareLink => 'Raba Hanyar';

  @override
  String get totalInvited => 'Jimlar Gayyata';

  @override
  String get activeNow => 'Mai Aiki Yanzu';

  @override
  String get viewAll => 'Duba Duka';

  @override
  String get createCoin => 'Ƙirƙiri Tsabar Kuɗi';

  @override
  String get mining => 'Hakar ma\'adinai';

  @override
  String get settings => 'Saituna';

  @override
  String get language => 'Harshe';

  @override
  String get languageSubtitle => 'Canza yaren app';

  @override
  String get selectLanguage => 'Zaɓi Harshe';

  @override
  String get balanceTitle => 'Ma\'auni';

  @override
  String get home => 'Gida';

  @override
  String get referral => 'Nuni';

  @override
  String get profile => 'Bayanin martaba';

  @override
  String get dayStreak => 'Kwanakin jere';

  @override
  String dayStreakValue(int count) {
    return '$count Kwanakin jere';
  }

  @override
  String get active => 'Mai aiki';

  @override
  String get inactive => 'Mara aiki';

  @override
  String get sessionEndsIn => 'Zaman yana ƙarewa a ciki';

  @override
  String get startEarning => 'Fara Samun Kuɗi';

  @override
  String get loadingAd => 'Ana loda talla...';

  @override
  String waitSeconds(int seconds) {
    return 'Jira ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Lada +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Tallan lada babu shi';

  @override
  String rateBoosted(String rate) {
    return 'Ƙimar ta ƙaru: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Bonus ɗin talla ya gaza: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Bayanin ƙima: Tushe $base, Jere +$streak, Matsayi +$rank, Nuni +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Ba a iya fara hakar ma\'adinai ba. Da fatan za a bincika haɗin intanet ɗin ku kuma gwada sake.';

  @override
  String get createCommunityCoin => 'Ƙirƙiri Tsabar Al\'umma';

  @override
  String get launchCoinDescription =>
      'Kaddamar da tsabar kuɗin ku akan hanyar sadarwar ETA nan take.';

  @override
  String get createYourOwnCoin => 'Ƙirƙiri tsabar kuɗin ku';

  @override
  String get launchCommunityCoinDescription =>
      'Kaddamar da tsabar al\'ummar ku wanda sauran masu amfani da ETA zasu iya hakowa.';

  @override
  String get editCoin => 'Gyara tsabar kudi';

  @override
  String baseRate(String rate) {
    return 'Tushen ƙima: $rate tsabar kudi/awa';
  }

  @override
  String createdBy(String username) {
    return 'An ƙirƙira ta @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Babu tsabar kudi tukuna. Ƙara daga Live Coins.';

  @override
  String get mine => 'Haka';

  @override
  String get remaining => 'saura';

  @override
  String get holders => 'Masu riƙewa';

  @override
  String get close => 'Rufe';

  @override
  String get readMore => 'Kara karantawa';

  @override
  String get readLess => 'Karanta Kadan';

  @override
  String get projectLinks => 'Hanyoyin Ayyuka';

  @override
  String get verifyEmailTitle => 'Tabbatar da Imel ɗin ku';

  @override
  String get verifyEmailMessage =>
      'Mun aiko da hanyar tabbatarwa zuwa adireshin imel ɗin ku. Da fatan za a tabbatar da asusun ku don buɗe duk fasalulluka.';

  @override
  String get resendEmail => 'Sake Aika Imel';

  @override
  String get iHaveVerified => 'Na tabbatar';

  @override
  String get logout => 'Fita';

  @override
  String get emailVerifiedSuccess => 'An tabbatar da imel cikin nasara!';

  @override
  String get emailNotVerified =>
      'Ba a tabbatar da imel ba tukuna. Da fatan za a duba akwatin saƙon ku.';

  @override
  String get verificationEmailSent => 'An aika imel ɗin tabbatarwa';

  @override
  String get startMining => 'Fara Hakar Ma\'adinai';

  @override
  String get minedCoins => 'Tsabar da aka Haka';

  @override
  String get liveCoins => 'Tsabar Rayuwa';

  @override
  String get asset => 'Kadara';

  @override
  String get filterStatus => 'Matsayi';

  @override
  String get filterPopular => 'Shahararre';

  @override
  String get filterNames => 'Sunaye';

  @override
  String get filterOldNew => 'Tsoho - Sabo';

  @override
  String get filterNewOld => 'Sabo - Tsoho';

  @override
  String startMiningWithCount(int count) {
    return 'Fara Haƙa ($count)';
  }

  @override
  String get clearSelection => 'Share Zaɓi';

  @override
  String get cancel => 'Soke';

  @override
  String get refreshStatus => 'Sabunta Matsayi';

  @override
  String get purchaseFailed => 'Siyan Ya Kasa';

  @override
  String get securePaymentViaGooglePlay => 'Amintaccen Biya ta Google Play';

  @override
  String get addedToMinedCoins => 'An Ƙara zuwa Tsabar da aka Haƙa';

  @override
  String failedToAdd(String message) {
    return 'An Kasa Ƙarawa: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Biyan kuɗi yana samuwa ne kawai akan Android/iOS.';

  @override
  String get miningRate => 'Ƙimar Haƙa';

  @override
  String get about => 'Game da';

  @override
  String get yourMined => 'Naku da kuka Haƙa';

  @override
  String get totalMined => 'Jimlar da aka Haƙa';

  @override
  String get noReferrals => 'Babu gayyata tukuna';

  @override
  String get linkCopied => 'An Kwafi Link';

  @override
  String get copy => 'Kwafi';

  @override
  String get howItWorks => 'Yadda Yake Aiki';

  @override
  String get referralDescription =>
      'Raba lambar ku tare da abokai. Lokacin da suka shiga kuma suka yi aiki, kuna haɓaka ƙungiyar ku kuma inganta damar samun kuɗi.';

  @override
  String get yourTeam => 'Ƙungiyar Ku';

  @override
  String get referralsTitle => 'Gayyata';

  @override
  String get shareLinkTitle => 'Raba Link';

  @override
  String get copyLinkInstruction => 'Kwafi wannan link don rabawa:';

  @override
  String get referralCodeCopied => 'An Kwafi Lambar Gayyata';

  @override
  String joinMeText(String code, String link) {
    return 'Kasance tare da ni a Eta Network! Yi amfani da lambar tawa: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Babu Tsabar Al\'umma Masu Gudana';

  @override
  String get rate => 'Ƙima';

  @override
  String get filterRandom => 'Bazuwar';

  @override
  String get baseRateLabel => 'Ƙimar Tushe';

  @override
  String startFailed(String error) {
    return 'Fara Ya Kasa: $error';
  }

  @override
  String get sessionProgress => 'Ci gaban Zama';

  @override
  String get remainingLabel => 'Sauran';

  @override
  String get boostRate => 'Ƙimar Haɓakawa';

  @override
  String get minedLabel => 'An Haƙa';

  @override
  String get noSubscriptionPlansAvailable => 'Babu Tsarin Biyan Kuɗi';

  @override
  String get subscriptionPlans => 'Tsare-tsaren Biyan Kuɗi';

  @override
  String get recommended => 'Shawara';

  @override
  String get editCommunityCoin => 'Gyara Tsabar Al\'umma';

  @override
  String get launchCoinEcosystemDescription =>
      'Fara tsabar ku a cikin tsarin ETA don al\'ummar ku.';

  @override
  String get upload => 'Loda';

  @override
  String get recommendedImageSize => 'Shawara 200×200px';

  @override
  String get coinNameLabel => 'Sunan Tsaba';

  @override
  String get symbolLabel => 'Alama';

  @override
  String get descriptionLabel => 'Bayani';

  @override
  String get baseMiningRateLabel => 'Ƙimar Haƙa ta Tushe (tsaba/awa)';

  @override
  String maxAllowed(String max) {
    return 'Matsakaicin izini: $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Hanyoyin Sadarwar Jama\'a & Aikin (Na Zabi)';

  @override
  String get linkTypeWebsite => 'Yanar Gizo';

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
  String get linkTypeOther => 'Wani';

  @override
  String get pasteUrl => 'Manna URL';

  @override
  String get importantNoticeTitle => 'Sanarwa Muhimmiya';

  @override
  String get importantNoticeBody =>
      'Wannan tsabar wani bangare ne na tsarin ETA Network kuma yana wakiltar shiga cikin al\'ummar dijital mai girma. Tsabar Al\'umma ana ƙirƙirar su ne ta masu amfani don ginawa, gwadawa, da shiga cikin hanyar sadarwar. ETA Network yana cikin matakan farko na ci gaba. Yayin da tsarin ke girma, ana iya gabatar da sabbin abubuwa, fasaloli, da haɗe-haɗe dangane da ayyukan al\'umma, ci gaban dandamali, da ƙa\'idodi masu dacewa.';

  @override
  String get pleaseWait => 'Da fatan za a jira...';

  @override
  String get save => 'Ajiye';

  @override
  String createCoinFailed(String error) {
    return 'Ƙirƙirar Tsaba Ya Kasa: $error';
  }

  @override
  String get coinNameLengthError =>
      'Sunan tsaba dole ne ya kasance tsakanin haruffa 3-30.';

  @override
  String get symbolRequiredError => 'Ana buƙatar Alama.';

  @override
  String get symbolLengthError =>
      'Alama dole ne ta kasance haruffa/lambobi 2-6.';

  @override
  String get descriptionTooLongError => 'Bayani yayi tsayi da yawa.';

  @override
  String baseRateRangeError(String max) {
    return 'Ƙimar Haƙa ta Tushe dole ne ta kasance tsakanin 0.000000001 da $max.';
  }

  @override
  String get coinNameExistsError =>
      'Sunan tsaba yana nan. Da fatan za a zaɓi wani.';

  @override
  String get symbolExistsError => 'Alama tana nan. Da fatan za a zaɓi wata.';

  @override
  String get urlInvalidError => 'Daya daga cikin URL ba daidai bane.';

  @override
  String get subscribeAndBoost => 'Yi Biyan Kuɗi & Haɓaka Haƙa';

  @override
  String get autoCollect => 'Tarin Kai tsaye';

  @override
  String autoMineCoins(int count) {
    return 'Haƙa Tsaba $count Kai tsaye';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Gudun';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Babu bayani.';

  @override
  String get unknownUser => 'Ba a sani ba';

  @override
  String get streakLabel => 'Jere';

  @override
  String get referralsLabel => 'Gayyata';

  @override
  String get sessionsLabel => 'Zama';

  @override
  String get accountInfoSection => 'Bayanin Asusun';

  @override
  String get accountInfoTile => 'Bayanin Asusun';

  @override
  String get invitedByPrompt => 'Wane ne ya gayyace ku?';

  @override
  String get enterReferralCode => 'Shigar da Lambar Gayyata';

  @override
  String get invitedStatus => 'An Gayyata';

  @override
  String get lockedStatus => 'A Rufe';

  @override
  String get applyButton => 'Aiwatar';

  @override
  String get aboutPageTitle => 'Game da';

  @override
  String get faqTile => 'Tambayoyin da aka saba yi';

  @override
  String get whitePaperTile => 'Farar Takarda';

  @override
  String get contactUsTile => 'Tuntube Mu';

  @override
  String get securitySettingsTile => 'Saitunan Tsaro';

  @override
  String get securitySettingsPageTitle => 'Saitunan Tsaro';

  @override
  String get deleteAccountTile => 'Share Asusun';

  @override
  String get deleteAccountSubtitle =>
      'Share asusun ku da bayanan ku na dindindin';

  @override
  String get deleteAccountDialogTitle => 'Share Asusun?';

  @override
  String get deleteAccountDialogContent =>
      'Wannan zai share asusun ku, bayanan ku, da zaman ku na dindindin. Ba za a iya dawo da wannan aikin ba.';

  @override
  String get deleteButton => 'Share';

  @override
  String get kycVerificationTile => 'Tabbatar da KYC';

  @override
  String get kycVerificationDialogTitle => 'Tabbatar da KYC';

  @override
  String get kycComingSoonMessage => 'Za a kunna a matakai masu zuwa.';

  @override
  String get okButton => 'TO';

  @override
  String get logOutLabel => 'Fita';

  @override
  String get confirmDeletionTitle => 'Tabbatar da Sharewa';

  @override
  String get enterAccountPassword => 'Shigar da kalmar wucewa ta asusu';

  @override
  String get confirmButton => 'Tabbatar';

  @override
  String get usernameLabel => 'Sunan mai amfani';

  @override
  String get emailLabel => 'Imel';

  @override
  String get nameLabel => 'Suna';

  @override
  String get ageLabel => 'Shekaru';

  @override
  String get countryLabel => 'Ƙasa';

  @override
  String get addressLabel => 'Adireshi';

  @override
  String get genderLabel => 'Jinsi';

  @override
  String get enterUsernameHint => 'Shigar da sunan mai amfani';

  @override
  String get enterNameHint => 'Shigar da suna';

  @override
  String get enterAgeHint => 'Shigar da shekaru';

  @override
  String get enterCountryHint => 'Shigar da ƙasa';

  @override
  String get enterAddressHint => 'Shigar da adireshi';

  @override
  String get enterGenderHint => 'Shigar da jinsi';

  @override
  String get savingLabel => 'Yana Ajiyewa...';

  @override
  String get usernameEmptyError => 'Sunan mai amfani ba zai iya zama fanko ba';

  @override
  String get invalidAgeError => 'Shekaru ba daidai ba';

  @override
  String get saveError => 'An kasa ajiye canje-canje';

  @override
  String get cancelButton => 'Soke';
}
