// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Yoruba (`yo`).
class AppLocalizationsYo extends AppLocalizations {
  AppLocalizationsYo([String locale = 'yo']) : super(locale);

  @override
  String get totalBalance => 'Apapọ Iwontunwonsi';

  @override
  String joinedDate(String link, Object date) {
    return 'Darapọ mọ $date';
  }

  @override
  String get inviteEarn => 'Pe & Gba';

  @override
  String get shareCodeDescription =>
      'Pin koodu alailẹgbẹ rẹ pẹlu awọn ọrẹ lati ṣe alekun oṣuwọn iwakusa rẹ.';

  @override
  String get shareLink => 'Pin Ọna asopọ';

  @override
  String get totalInvited => 'Lapapọ Awọn ti a pe';

  @override
  String get activeNow => 'Ti nṣiṣe lọwọ Bayi';

  @override
  String get viewAll => 'Wo Gbogbo';

  @override
  String get createCoin => 'Ṣẹda Owo';

  @override
  String get mining => 'Iwakusa';

  @override
  String get settings => 'Eto';

  @override
  String get language => 'Ede';

  @override
  String get languageSubtitle => 'Yi ede app pada';

  @override
  String get selectLanguage => 'Yan Ede';

  @override
  String get balanceTitle => 'Iwontunwonsi';

  @override
  String get home => 'Ile';

  @override
  String get referral => 'Itọkasi';

  @override
  String get profile => 'Profaili';

  @override
  String get dayStreak => 'Ọjọ Ọjọ';

  @override
  String dayStreakValue(int count) {
    return '$count Ọjọ Ọjọ';
  }

  @override
  String get active => 'Ti nṣiṣe lọwọ';

  @override
  String get inactive => 'Aiṣiṣẹ';

  @override
  String get sessionEndsIn => 'Igba dopin ni';

  @override
  String get startEarning => 'Bẹrẹ Gbigba';

  @override
  String get loadingAd => 'Ikojọpọ ipolowo...';

  @override
  String waitSeconds(int seconds) {
    return 'Duro ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Ere +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Ipolowo ere ko si';

  @override
  String rateBoosted(String rate) {
    return 'Oṣuwọn pọ si: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ajeseku ipolowo kuna: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Didenukole oṣuwọn: Ipilẹ $base, Ọjọ +$streak, Ipo +$rank, Itọkasi +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Ko le bẹrẹ iwakusa. Jọwọ ṣayẹwo asopọ intanẹẹti rẹ ki o tun gbiyanju lẹẹkansi.';

  @override
  String get createCommunityCoin => 'Ṣẹda Owo Agbegbe';

  @override
  String get launchCoinDescription =>
      'Lọlẹ owo tirẹ lori Nẹtiwọọki ETA lẹsẹkẹsẹ.';

  @override
  String get createYourOwnCoin => 'Ṣẹda owo tirẹ';

  @override
  String get launchCommunityCoinDescription =>
      'Lọlẹ owo agbegbe rẹ ti awọn olumulo ETA miiran le wa.';

  @override
  String get editCoin => 'Ṣatunkọ owo';

  @override
  String baseRate(String rate) {
    return 'Oṣuwọn ipilẹ: $rate awọn owó/wakati';
  }

  @override
  String createdBy(String username) {
    return 'Ti ṣẹda nipasẹ @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet =>
      'Ko si awọn owó sibẹsibẹ. Ṣafikun lati Awọn owó Live.';

  @override
  String get mine => 'Wa';

  @override
  String get remaining => 'ti o ku';

  @override
  String get holders => 'Awọn onimu';

  @override
  String get close => 'Paade';

  @override
  String get readMore => 'Ka Siwaju';

  @override
  String get readLess => 'Ka Kere';

  @override
  String get projectLinks => 'Awọn ọna asopọ Iṣẹ';

  @override
  String get verifyEmailTitle => 'Daju Imeeli rẹ';

  @override
  String get verifyEmailMessage =>
      'A ti fi ọna asopọ ijẹrisi ranṣẹ si adirẹsi imeeli rẹ. Jọwọ jẹrisi akọọlẹ rẹ lati ṣii gbogbo awọn ẹya.';

  @override
  String get resendEmail => 'Tun Imeeli ranṣẹ';

  @override
  String get iHaveVerified => 'Mo ti daju';

  @override
  String get logout => 'Jade';

  @override
  String get emailVerifiedSuccess => 'Imeeli jẹrisi ni aṣeyọri!';

  @override
  String get emailNotVerified =>
      'Imeeli ko tii jẹrisi. Jọwọ ṣayẹwo apo-iwọle rẹ.';

  @override
  String get verificationEmailSent => 'Ti fi imeeli ijẹrisi ranṣẹ';

  @override
  String get startMining => 'Bẹrẹ Iwakusa';

  @override
  String get minedCoins => 'Awọn owó ti a wa';

  @override
  String get liveCoins => 'Awọn owó Live';

  @override
  String get asset => 'Dukia';

  @override
  String get filterStatus => 'Ipo';

  @override
  String get filterPopular => 'Gbajumo';

  @override
  String get filterNames => 'Awọn orukọ';

  @override
  String get filterOldNew => 'Atijọ - Tuntun';

  @override
  String get filterNewOld => 'Tuntun - Atijọ';

  @override
  String startMiningWithCount(int count) {
    return 'Bẹrẹ Iwakusa ($count)';
  }

  @override
  String get clearSelection => 'Ko Aṣayan kuro';

  @override
  String get cancel => 'Fagilee';

  @override
  String get refreshStatus => 'Soji Ipo';

  @override
  String get purchaseFailed => 'Rira kuna';

  @override
  String get securePaymentViaGooglePlay =>
      'Isanwo to ni aabo nipasẹ Google Play';

  @override
  String get addedToMinedCoins => 'Ti a ṣafikun si Awọn owó ti a wa';

  @override
  String failedToAdd(String message) {
    return 'Kuna lati ṣafikun: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Awọn ṣiṣe alabapin wa lori Android/iOS nikan.';

  @override
  String get miningRate => 'Oṣuwọn iwakusa';

  @override
  String get about => 'Nipa';

  @override
  String get yourMined => 'Ti a wa';

  @override
  String get totalMined => 'Lapapọ Ti a wa';

  @override
  String get noReferrals => 'Ko si awọn itọkasi sibẹsibẹ';

  @override
  String get linkCopied => 'Ọna asopọ daakọ';

  @override
  String get copy => 'Daakọ';

  @override
  String get howItWorks => 'Bawo ni o ṣe n ṣiṣẹ';

  @override
  String get referralDescription =>
      'Pin koodu rẹ pẹlu awọn ọrẹ. Nigbati wọn ba darapọ mọ ti wọn si ṣiṣẹ, o dagba ẹgbẹ rẹ ati ilọsiwaju agbara gbigba rẹ.';

  @override
  String get yourTeam => 'Ẹgbẹ rẹ';

  @override
  String get referralsTitle => 'Awọn itọkasi';

  @override
  String get shareLinkTitle => 'Pin Ọna asopọ';

  @override
  String get copyLinkInstruction => 'Daakọ ọna asopọ yii lati pin:';

  @override
  String get referralCodeCopied => 'Koodu itọkasi daakọ';

  @override
  String joinMeText(String code, String link) {
    return 'Darapọ mọ mi lori Nẹtiwọọki Eta! Lo koodu mi: $code $link';
  }

  @override
  String get etaNetwork => 'Nẹtiwọọki ETA';

  @override
  String get noLiveCommunityCoins => 'Ko si awọn owó agbegbe laaye';

  @override
  String get rate => 'Oṣuwọn';

  @override
  String get filterRandom => 'ID';

  @override
  String get baseRateLabel => 'Oṣuwọn Ipilẹ';

  @override
  String startFailed(String error) {
    return 'Bẹrẹ kuna: $error';
  }

  @override
  String get sessionProgress => 'Ilọsiwaju Igba';

  @override
  String get remainingLabel => 'ti o ku';

  @override
  String get boostRate => 'Oṣuwọn Igbega';

  @override
  String get minedLabel => 'Ti a wa';

  @override
  String get noSubscriptionPlansAvailable =>
      'Ko si awọn ero ṣiṣe alabapin ti o wa';

  @override
  String get subscriptionPlans => 'Awọn Eto Ṣiṣe alabapin';

  @override
  String get recommended => 'Ti a ṣe iṣeduro';

  @override
  String get editCommunityCoin => 'Ṣatunkọ Owo Agbegbe';

  @override
  String get launchCoinEcosystemDescription =>
      'Lọlẹ owo tirẹ inu ilolupo ETA fun agbegbe rẹ.';

  @override
  String get upload => 'Po si';

  @override
  String get recommendedImageSize => 'Ti a ṣe iṣeduro 200×200px';

  @override
  String get coinNameLabel => 'Orukọ owo';

  @override
  String get symbolLabel => 'Aami';

  @override
  String get descriptionLabel => 'Apejuwe';

  @override
  String get baseMiningRateLabel => 'Oṣuwọn iwakusa ipilẹ (awọn owó/wakati)';

  @override
  String maxAllowed(String max) {
    return 'O pọju Gba laaye: $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Awọn ọna asopọ awujọ & iṣẹ (aṣayan)';

  @override
  String get linkTypeWebsite => 'Oju opo wẹẹbu';

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
  String get linkTypeOther => 'Miran';

  @override
  String get pasteUrl => 'Lẹamọ URL';

  @override
  String get importantNoticeTitle => 'Akiyesi pataki';

  @override
  String get importantNoticeBody =>
      'Owo yii jẹ apakan ti ilolupo Nẹtiwọọki ETA ati ṣe aṣoju ikopa ninu agbegbe oni-nọmba ti ndagba. Awọn owó agbegbe jẹ ipilẹṣẹ nipasẹ awọn olumulo lati kọ, ṣe idanwo, ati ṣe ajọṣepọ laarin nẹtiwọọki naa. Nẹtiwọọki ETA wa ni ipele ibẹrẹ ti idagbasoke. Bi ilolupo eda abemi ti n dagba, awọn ohun elo tuntun, awọn ẹya, ati awọn iṣọpọ le ṣe agbekalẹ da lori iṣẹ ṣiṣe agbegbe, itankalẹ pẹpẹ, ati awọn itọnisọna to wulo.';

  @override
  String get pleaseWait => 'Jọwọ duro...';

  @override
  String get save => 'Fipamọ';

  @override
  String createCoinFailed(String error) {
    return 'Kuna lati ṣẹda owo: $error';
  }

  @override
  String get coinNameLengthError => 'Orukọ owo gbọdọ jẹ awọn ohun kikọ 3-30.';

  @override
  String get symbolRequiredError => 'Aami ti wa ni ti beere.';

  @override
  String get symbolLengthError => 'Aami gbọdọ jẹ awọn lẹta/nọmba 2-6.';

  @override
  String get descriptionTooLongError => 'Apejuwe gun ju.';

  @override
  String baseRateRangeError(String max) {
    return 'Oṣuwọn iwakusa ipilẹ gbọdọ wa laarin 0.000000001 ati $max.';
  }

  @override
  String get coinNameExistsError => 'Orukọ owo wa tẹlẹ. Jọwọ yan miiran.';

  @override
  String get symbolExistsError => 'Aami wa tẹlẹ. Jọwọ yan miiran.';

  @override
  String get urlInvalidError => 'Ọkan ninu awọn URL ko wulo.';

  @override
  String get subscribeAndBoost => 'Alabapin & Igbelaruge Iwakusa';

  @override
  String get autoCollect => 'Gba-laifọwọyi';

  @override
  String autoMineCoins(int count) {
    return 'Iwakusa owo $count laifọwọyi';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Iyara';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Ko si apejuwe wa.';

  @override
  String get unknownUser => 'Aimọ';

  @override
  String get streakLabel => 'STREAK';

  @override
  String get referralsLabel => 'ITOJU';

  @override
  String get sessionsLabel => 'IGBA';

  @override
  String get accountInfoSection => 'Alaye Account';

  @override
  String get accountInfoTile => 'Alaye Account';

  @override
  String get invitedByPrompt => 'Ti a pe nipasẹ ẹnikan?';

  @override
  String get enterReferralCode => 'Tẹ koodu itọkasi';

  @override
  String get invitedStatus => 'Ti a pe';

  @override
  String get lockedStatus => 'Titiipa';

  @override
  String get applyButton => 'Waye';

  @override
  String get aboutPageTitle => 'Nipa';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'Iwe funfun';

  @override
  String get contactUsTile => 'Pe wa';

  @override
  String get securitySettingsTile => 'Awọn Eto Aabo';

  @override
  String get securitySettingsPageTitle => 'Awọn Eto Aabo';

  @override
  String get deleteAccountTile => 'Pa Account rẹ';

  @override
  String get deleteAccountSubtitle => 'Pa akọọlẹ rẹ ati data rẹ rẹ patapata';

  @override
  String get deleteAccountDialogTitle => 'Pa akọọlẹ rẹ bi?';

  @override
  String get deleteAccountDialogContent =>
      'Eyi yoo pa akọọlẹ rẹ, data, ati awọn akoko rẹ rẹ patapata. Iṣe yii ko le ṣe atunṣe.';

  @override
  String get deleteButton => 'Paarẹ';

  @override
  String get kycVerificationTile => 'Imudaniloju KYC';

  @override
  String get kycVerificationDialogTitle => 'Imudaniloju KYC';

  @override
  String get kycComingSoonMessage => 'Yoo muu ṣiṣẹ ni awọn ipele to nbọ.';

  @override
  String get okButton => 'DARA';

  @override
  String get logOutLabel => 'Jade';

  @override
  String get confirmDeletionTitle => 'Jẹrisi piparẹ';

  @override
  String get enterAccountPassword => 'Tẹ ọrọ igbaniwọle akọọlẹ sii';

  @override
  String get confirmButton => 'Jẹrisi';

  @override
  String get usernameLabel => 'Orukọ olumulo';

  @override
  String get emailLabel => 'Imeeli';

  @override
  String get nameLabel => 'Orukọ';

  @override
  String get ageLabel => 'Ọjọ ori';

  @override
  String get countryLabel => 'Orilẹ-ede';

  @override
  String get addressLabel => 'Adirẹsi';

  @override
  String get genderLabel => 'abo';

  @override
  String get enterUsernameHint => 'Tẹ orukọ olumulo sii';

  @override
  String get enterNameHint => 'Tẹ orukọ sii';

  @override
  String get enterAgeHint => 'Tẹ ọjọ ori sii';

  @override
  String get enterCountryHint => 'Tẹ orilẹ-ede sii';

  @override
  String get enterAddressHint => 'Tẹ adirẹsi sii';

  @override
  String get enterGenderHint => 'Tẹ abo sii';

  @override
  String get savingLabel => 'Nfipamọ...';

  @override
  String get usernameEmptyError => 'Orukọ olumulo ko le jẹ ofo';

  @override
  String get invalidAgeError => 'Iye ọjọ ori ko wulo';

  @override
  String get saveError => 'Kuna lati fi awọn ayipada pamọ';

  @override
  String get cancelButton => 'Fagilee';
}
