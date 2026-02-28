// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Fulah (`ff`).
class AppLocalizationsFf extends AppLocalizations {
  AppLocalizationsFf([String locale = 'ff']) : super(locale);

  @override
  String get totalBalance => 'Limoore Fof';

  @override
  String joinedDate(String link, Object date) {
    return 'Naatii $date';
  }

  @override
  String get inviteEarn => 'Noddu & Heɓ';

  @override
  String get shareCodeDescription =>
      'Sanda koodu maa keeriɗo e sehilaaɓe ngam ɓeydude ŋarɗugol maa. ';

  @override
  String get shareLink => 'Sanda Jokkondiral';

  @override
  String get totalInvited => 'Limoore Nodditaaɓe';

  @override
  String get activeNow => 'Ena Gollira Jooni';

  @override
  String get viewAll => 'Yiy Fof';

  @override
  String get createCoin => 'Tagu Kaalis';

  @override
  String get mining => 'Ŋarɗugol';

  @override
  String get settings => 'Teelte';

  @override
  String get language => 'Ɗemngal';

  @override
  String get languageSubtitle => 'Waylu ɗemngal app';

  @override
  String get selectLanguage => 'Suɓo Ɗemngal';

  @override
  String get balanceTitle => 'Limoore';

  @override
  String get home => 'Suudu';

  @override
  String get referral => 'Nodditaaɗo';

  @override
  String get profile => 'Profail';

  @override
  String get dayStreak => 'Balɗe Jokkondirɗe';

  @override
  String dayStreakValue(int count) {
    return '$count Balɗe Jokkondirɗe';
  }

  @override
  String get active => 'Ena Gollira';

  @override
  String get inactive => 'Gollirtaa';

  @override
  String get sessionEndsIn => 'Dumunna ena timma e';

  @override
  String get startEarning => 'Fuɗɗo Heɓde';

  @override
  String get loadingAd => 'Ena loowa yeeyirde...';

  @override
  String waitSeconds(int seconds) {
    return 'Pad ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Njoɓdi +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Yeeyirde njoɓdi alaa';

  @override
  String rateBoosted(String rate) {
    return 'Ŋarɗugol ɓeydiima: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ɓeydaare yeeyirde ronkii: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Feccere ŋarɗugol: Tuggorde $base, Jokkondiral +$streak, Darnde +$rank, Nodditaaɓe +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Waawaa fuɗɗaade ŋarɗugol. Tiiɗno ƴeewtu jokkondiral enternet maa te ɗaɓɓitaa goɗɗum.';

  @override
  String get createCommunityCoin => 'Tagu Kaalis Renndo';

  @override
  String get launchCoinDescription =>
      'Fuɗɗo kaalis maa e ETA Network ɗoon e ɗoon.';

  @override
  String get createYourOwnCoin => 'Tagu kaalis maa';

  @override
  String get launchCommunityCoinDescription =>
      'Fuɗɗo kaalis renndo maa mo woɓɓe ETA mbaawi ŋarɗude.';

  @override
  String get editCoin => 'Waylu kaalis';

  @override
  String baseRate(String rate) {
    return 'Ŋarɗugol tuggorde: $rate kaalis/waktu';
  }

  @override
  String createdBy(String username) {
    return 'Tagaaɗo e @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Kaalis alaa tawo. Ɓeydu gila e Kaalis Buurɗo.';

  @override
  String get mine => 'Ŋarɗu';

  @override
  String get remaining => 'heddii';

  @override
  String get holders => 'Jogiiɓe';

  @override
  String get close => 'Uddu';

  @override
  String get readMore => 'Tar Goɗɗum';

  @override
  String get readLess => 'Tar Seed';

  @override
  String get projectLinks => 'Jokkondiral Eɓɓoore';

  @override
  String get verifyEmailTitle => 'Tabbintin Iimeel Maa';

  @override
  String get verifyEmailMessage =>
      'Min neldi jokkondiral tabbintingol e aderes iimeel maa. Tiiɗno tabbintin konte maa ngam udditde geɗe fof.';

  @override
  String get resendEmail => 'Nelditu Iimeel';

  @override
  String get iHaveVerified => 'Mi tabbintinii';

  @override
  String get logout => 'Yaltu';

  @override
  String get emailVerifiedSuccess => 'Iimeel tabbintinaama!';

  @override
  String get emailNotVerified =>
      'Iimeel tabbintinaaka tawo. Tiiɗno ƴeewtu boowat maa.';

  @override
  String get verificationEmailSent => 'Iimeel tabbintingol neldaama';

  @override
  String get startMining => 'Fuɗɗo Ŋarɗugol';

  @override
  String get minedCoins => 'Kaalis Ŋarɗaaɗo';

  @override
  String get liveCoins => 'Kaalis Buurɗo';

  @override
  String get asset => 'Jawdi';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Lolluɗo';

  @override
  String get filterNames => 'Inɗe';

  @override
  String get filterOldNew => 'Kiiɗɗum - Keso';

  @override
  String get filterNewOld => 'Keso - Kiiɗɗum';

  @override
  String startMiningWithCount(int count) {
    return 'Fuɗɗo Ŋarɗugol ($count)';
  }

  @override
  String get clearSelection => 'Ittu Suɓngo';

  @override
  String get cancel => 'Haaytu';

  @override
  String get refreshStatus => 'Hesɗitin Status';

  @override
  String get purchaseFailed => 'Soodde Ronkii';

  @override
  String get securePaymentViaGooglePlay => 'Njoɓdi Tabbintinaandi Google Play';

  @override
  String get addedToMinedCoins => 'Ɓeydaama e Kaalis Ŋarɗaaɗo';

  @override
  String failedToAdd(String message) {
    return 'Ronkii ɓeydude: $message';
  }

  @override
  String get subscriptionsUnavailable => 'Njoɓdi ena woodi tan e Android/iOS.';

  @override
  String get miningRate => 'Duggol Ŋarɗugol';

  @override
  String get about => 'Fii';

  @override
  String get yourMined => 'Ko Ŋarɗu-ɗaa';

  @override
  String get totalMined => 'Ko Ŋarɗaa Fof';

  @override
  String get noReferrals => 'Nodditaaɗo Alaa Tawo';

  @override
  String get linkCopied => 'Jokkondiral Nangaama';

  @override
  String get copy => 'Nangu';

  @override
  String get howItWorks => 'No Gollirta';

  @override
  String get referralDescription =>
      'Sanda koodu maa e sehilaaɓe. So ɓe naatii te ɓe ngollirii, a ɓeydat fedde maa te a ɓeydat baawɗe maa heɓde.';

  @override
  String get yourTeam => 'Fedde Maa';

  @override
  String get referralsTitle => 'Nodditaaɓe';

  @override
  String get shareLinkTitle => 'Sanda Jokkondiral';

  @override
  String get copyLinkInstruction => 'Nangu ngal jokkondiral ngam sandude:';

  @override
  String get referralCodeCopied => 'Koodu Nodditaaɗo Nangaama';

  @override
  String joinMeText(String code, String link) {
    return 'Ar jey e am e Eta Network! Huutoro koodu am: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Kaalis Renndo Buurɗo Alaa';

  @override
  String get rate => 'Duggol';

  @override
  String get filterRandom => 'Wano Weli';

  @override
  String get baseRateLabel => 'Duggol Tuggorde';

  @override
  String startFailed(String error) {
    return 'Fuɗɗaade Ronkii: $error';
  }

  @override
  String get sessionProgress => 'Yahrude Yeeso Dumunna';

  @override
  String get remainingLabel => 'Heddii';

  @override
  String get boostRate => 'Duggol Ɓeydaare';

  @override
  String get minedLabel => 'Ŋarɗaaɗo';

  @override
  String get noSubscriptionPlansAvailable => 'Feere Njoɓdi Alaa';

  @override
  String get subscriptionPlans => 'Peeje Njoɓdi';

  @override
  String get recommended => 'Wasiyaaɗo';

  @override
  String get editCommunityCoin => 'Waylu Kaalis Renndo';

  @override
  String get launchCoinEcosystemDescription =>
      'Fuɗɗo kaalis maa e nder ETA ecosystem ngam renndo maa.';

  @override
  String get upload => 'Loow';

  @override
  String get recommendedImageSize => 'Wasiyaaɗo 200×200px';

  @override
  String get coinNameLabel => 'Innde Kaalis';

  @override
  String get symbolLabel => 'Maande';

  @override
  String get descriptionLabel => 'Ciftinoore';

  @override
  String get baseMiningRateLabel => 'Duggol Ŋarɗugol Tuggorde (kaalis/waktu)';

  @override
  String maxAllowed(String max) {
    return 'Ko ɓuri heewde: $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Jokkondiral Renndo & Eɓɓoore (Suɓo)';

  @override
  String get linkTypeWebsite => 'Lowre';

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
  String get linkTypeOther => 'Goɗɗum';

  @override
  String get pasteUrl => 'Loow URL';

  @override
  String get importantNoticeTitle => 'Tintinol Mawnungol';

  @override
  String get importantNoticeBody =>
      'O kaalis ko jeyaaɗo e ETA Network ecosystem te ina hollira tawtoreede renndo dijital ɓeydotoongo. Kaalis renndo ko huutortooɓe tagata ɗum ngam mahde, humpitaade e tawtoreede e nder network he. ETA Network ina e puɗɗagol ɓamtaare. So ecosystem he ɓeydiima, nafoore hesere, sifaaji e kawrital ina waawi ɓeydeede e dow golle renndo, ɓamtaare platform e sariyaaji gonɗi.';

  @override
  String get pleaseWait => 'Tiiɗno pad...';

  @override
  String get save => 'Danndu';

  @override
  String createCoinFailed(String error) {
    return 'Tagu Kaalis Ronkii: $error';
  }

  @override
  String get coinNameLengthError =>
      'Innde kaalis ina foti wonde hakkunde 3-30 alkulal.';

  @override
  String get symbolRequiredError => 'Maande ina haani.';

  @override
  String get symbolLengthError => 'Maande ina foti wonde 2-6 alkulal/limoore.';

  @override
  String get descriptionTooLongError => 'Ciftinoore heewi haala.';

  @override
  String baseRateRangeError(String max) {
    return 'Duggol ŋarɗugol tuggorde ina foti wonde hakkunde 0.000000001 e $max.';
  }

  @override
  String get coinNameExistsError =>
      'Innde kaalis ena woodi. Tiiɗno suɓo wonnde.';

  @override
  String get symbolExistsError => 'Maande ena woodi. Tiiɗno suɓo wonnde.';

  @override
  String get urlInvalidError => 'Gooto e URL ɗee moƴƴaani.';

  @override
  String get subscribeAndBoost => 'Yob & Ɓeydu Ŋarɗugol';

  @override
  String get autoCollect => 'Mooftu E Hoore Mum';

  @override
  String autoMineCoins(int count) {
    return 'Ŋarɗu $count Kaalis E Hoore Mum';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Jaawgol';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Ciftinoore alaa.';

  @override
  String get unknownUser => 'Anndaaka';

  @override
  String get streakLabel => 'Jokkondiral';

  @override
  String get referralsLabel => 'Nodditaaɓe';

  @override
  String get sessionsLabel => 'Dumunnaaji';

  @override
  String get accountInfoSection => 'Humpito Konte';

  @override
  String get accountInfoTile => 'Humpito Konte';

  @override
  String get invitedByPrompt => 'Hol nodduɗo ma?';

  @override
  String get enterReferralCode => 'Naatnu Koodu Nodditaaɗo';

  @override
  String get invitedStatus => 'Noddaama';

  @override
  String get lockedStatus => 'Sokaama';

  @override
  String get applyButton => 'Huutoro';

  @override
  String get aboutPageTitle => 'Fii';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Jokkondir E Amen';

  @override
  String get securitySettingsTile => 'Teelte Kisal';

  @override
  String get securitySettingsPageTitle => 'Teelte Kisal';

  @override
  String get deleteAccountTile => 'Momtu Konte';

  @override
  String get deleteAccountSubtitle =>
      'Momtu konte maa e humpito maa haa poomaa';

  @override
  String get deleteAccountDialogTitle => 'Momtu Konte?';

  @override
  String get deleteAccountDialogContent =>
      'Ɗum momtat konte maa, humpito maa e dumunnaaji maa haa poomaa. Ɗum waawaa artireede.';

  @override
  String get deleteButton => 'Momtu';

  @override
  String get kycVerificationTile => 'Tabbintingol KYC';

  @override
  String get kycVerificationDialogTitle => 'Tabbintingol KYC';

  @override
  String get kycComingSoonMessage => 'Ma gollal e daawe garoije.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Yaltu';

  @override
  String get confirmDeletionTitle => 'Tabbintin Momtugol';

  @override
  String get enterAccountPassword => 'Naatnu koodu konte';

  @override
  String get confirmButton => 'Tabbintin';

  @override
  String get usernameLabel => 'Innde Huutortooɗo';

  @override
  String get emailLabel => 'Iimeel';

  @override
  String get nameLabel => 'Innde';

  @override
  String get ageLabel => 'Duuɓi';

  @override
  String get countryLabel => 'Leydi';

  @override
  String get addressLabel => 'Aderes';

  @override
  String get genderLabel => 'Gorko/Debbo';

  @override
  String get enterUsernameHint => 'Naatnu innde huutortooɗo';

  @override
  String get enterNameHint => 'Naatnu innde';

  @override
  String get enterAgeHint => 'Naatnu duuɓi';

  @override
  String get enterCountryHint => 'Naatnu leydi';

  @override
  String get enterAddressHint => 'Naatnu aderes';

  @override
  String get enterGenderHint => 'Naatnu gorko/debbo';

  @override
  String get savingLabel => 'Ena Dannda...';

  @override
  String get usernameEmptyError => 'Innde huutortooɗo fotaani wonde ɗolu';

  @override
  String get invalidAgeError => 'Limoore duuɓi moƴƴaani';

  @override
  String get saveError => 'Ronkii danndude waylo-waylo';

  @override
  String get cancelButton => 'Haaytu';
}
