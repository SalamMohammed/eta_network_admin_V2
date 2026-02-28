// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tagalog (`tl`).
class AppLocalizationsTl extends AppLocalizations {
  AppLocalizationsTl([String locale = 'tl']) : super(locale);

  @override
  String get totalBalance => 'Kabuuang Balanse';

  @override
  String joinedDate(String link, Object date) {
    return 'Sumali noong $date';
  }

  @override
  String get inviteEarn => 'Mag-imbita at Kumita';

  @override
  String get shareCodeDescription =>
      'Ibahagi ang iyong natatanging code sa mga kaibigan upang mapataas ang iyong mining rate.';

  @override
  String get shareLink => 'Ibahagi ang Link';

  @override
  String get totalInvited => 'KABUUANG NAIMBITA';

  @override
  String get activeNow => 'AKTIBO NGAYON';

  @override
  String get viewAll => 'Tingnan Lahat';

  @override
  String get createCoin => 'Lumikha ng Coin';

  @override
  String get mining => 'Pagmimina';

  @override
  String get settings => 'Mga Setting';

  @override
  String get language => 'Wika';

  @override
  String get languageSubtitle => 'Baguhin ang wika ng app';

  @override
  String get selectLanguage => 'Pumili ng Wika';

  @override
  String get balanceTitle => 'Balanse';

  @override
  String get home => 'Home';

  @override
  String get referral => 'Referral';

  @override
  String get profile => 'Profile';

  @override
  String get dayStreak => 'Day Streak';

  @override
  String dayStreakValue(int count) {
    return '$count Araw na Streak';
  }

  @override
  String get active => 'Aktibo';

  @override
  String get inactive => 'Hindi Aktibo';

  @override
  String get sessionEndsIn => 'Matatapos ang sesyon sa';

  @override
  String get startEarning => 'Magsimulang Kumita';

  @override
  String get loadingAd => 'Naglo-load ng ad...';

  @override
  String waitSeconds(int seconds) {
    return 'Maghintay ng ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Gantimpala +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Hindi magagamit ang rewarded ad';

  @override
  String rateBoosted(String rate) {
    return 'Pinaas ang rate: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Nabigo ang ad bonus: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Rate breakdown: Base $base, Streak +$streak, Rank +$rank, Referrals +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Hindi masimulan ang pagmimina. Pakisuri ang iyong internet connection at subukang muli.';

  @override
  String get createCommunityCoin => 'Lumikha ng Community Coin';

  @override
  String get launchCoinDescription =>
      'Ilunsad ang iyong sariling coin sa ETA Network agad.';

  @override
  String get createYourOwnCoin => 'Lumikha ng iyong sariling coin';

  @override
  String get launchCommunityCoinDescription =>
      'Ilunsad ang iyong sariling community coin na maaaring minahin ng ibang mga user ng ETA.';

  @override
  String get editCoin => 'I-edit ang coin';

  @override
  String baseRate(String rate) {
    return 'Base rate: $rate coins/oras';
  }

  @override
  String createdBy(String username) {
    return 'Nilikha ni @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Wala pang coins. Magdagdag mula sa Live Coins.';

  @override
  String get mine => 'Minahin';

  @override
  String get remaining => 'natitira';

  @override
  String get holders => 'Mga May-hawak';

  @override
  String get close => 'Isara';

  @override
  String get readMore => 'Magbasa Pa';

  @override
  String get readLess => 'Magbasa ng Kaunti';

  @override
  String get projectLinks => 'Mga Link ng Proyekto';

  @override
  String get verifyEmailTitle => 'I-verify ang Iyong Email';

  @override
  String get verifyEmailMessage =>
      'Nagpadala kami ng verification link sa iyong email address. Paki-verify ang iyong account upang ma-unlock ang lahat ng feature.';

  @override
  String get resendEmail => 'Ipadala Muli ang Email';

  @override
  String get iHaveVerified => 'Na-verify ko na';

  @override
  String get logout => 'Mag-logout';

  @override
  String get emailVerifiedSuccess => 'Matagumpay na na-verify ang email!';

  @override
  String get emailNotVerified =>
      'Hindi pa na-verify ang email. Pakisuri ang iyong inbox.';

  @override
  String get verificationEmailSent => 'Naipadala na ang verification email';

  @override
  String get startMining => 'Magsimulang Magmina';

  @override
  String get minedCoins => 'Naminang Coins';

  @override
  String get liveCoins => 'Live Coins';

  @override
  String get asset => 'Asset';

  @override
  String get filterStatus => 'Katayuan';

  @override
  String get filterPopular => 'Sikat';

  @override
  String get filterNames => 'Mga Pangalan';

  @override
  String get filterOldNew => 'Luma - Bago';

  @override
  String get filterNewOld => 'Bago - Luma';

  @override
  String startMiningWithCount(int count) {
    return 'Magsimulang Magmina ($count)';
  }

  @override
  String get clearSelection => 'I-clear ang Pagpili';

  @override
  String get cancel => 'Kanselahin';

  @override
  String get refreshStatus => 'I-refresh ang Katayuan';

  @override
  String get purchaseFailed => 'Nabigo ang pagbili';

  @override
  String get securePaymentViaGooglePlay =>
      'Ligtas na pagbabayad sa pamamagitan ng Google Play';

  @override
  String get addedToMinedCoins => 'Idinagdag sa Naminang Coins';

  @override
  String failedToAdd(String message) {
    return 'Nabigong magdagdag: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Ang mga subscription ay magagamit lamang sa Android/iOS.';

  @override
  String get miningRate => 'Mining rate';

  @override
  String get about => 'Tungkol sa';

  @override
  String get yourMined => 'Ang Iyong Namina';

  @override
  String get totalMined => 'Kabuuang Namina';

  @override
  String get noReferrals => 'Wala pang referrals';

  @override
  String get linkCopied => 'Nakopya ang link';

  @override
  String get copy => 'Kopyahin';

  @override
  String get howItWorks => 'Paano ito gumagana';

  @override
  String get referralDescription =>
      'Ibahagi ang iyong code sa mga kaibigan. Kapag sumali sila at naging aktibo, lalago ang iyong team at mapapabuti ang iyong potensyal na kumita.';

  @override
  String get yourTeam => 'Ang Iyong Team';

  @override
  String get referralsTitle => 'Mga Referral';

  @override
  String get shareLinkTitle => 'Ibahagi ang Link';

  @override
  String get copyLinkInstruction => 'Kopyahin ang link na ito upang ibahagi:';

  @override
  String get referralCodeCopied => 'Nakopya ang referral code';

  @override
  String joinMeText(String code, String link) {
    return 'Sumali sa akin sa Eta Network! Gamitin ang aking code: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Walang live na community coins';

  @override
  String get rate => 'RATE';

  @override
  String get filterRandom => 'Random';

  @override
  String get baseRateLabel => 'Base Rate';

  @override
  String startFailed(String error) {
    return 'Nabigo ang pagsisimula: $error';
  }

  @override
  String get sessionProgress => 'Progreso ng Sesyon';

  @override
  String get remainingLabel => 'natitira';

  @override
  String get boostRate => 'Boost Rate';

  @override
  String get minedLabel => 'Namina';

  @override
  String get noSubscriptionPlansAvailable =>
      'Walang magagamit na mga plano ng subscription';

  @override
  String get subscriptionPlans => 'Mga Plano ng Subscription';

  @override
  String get recommended => 'Inirerekomenda';

  @override
  String get editCommunityCoin => 'I-edit ang Community Coin';

  @override
  String get launchCoinEcosystemDescription =>
      'Ilunsad ang iyong sariling coin sa loob ng ETA ecosystem para sa iyong komunidad.';

  @override
  String get upload => 'I-upload';

  @override
  String get recommendedImageSize => 'Inirerekomenda 200×200px';

  @override
  String get coinNameLabel => 'Pangalan ng coin';

  @override
  String get symbolLabel => 'Simbolo';

  @override
  String get descriptionLabel => 'Paglalarawan';

  @override
  String get baseMiningRateLabel => 'Base mining rate (coins/oras)';

  @override
  String maxAllowed(String max) {
    return 'Max na Pinapayagan : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Mga social at link ng proyekto (opsyonal)';

  @override
  String get linkTypeWebsite => 'Website';

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
  String get linkTypeOther => 'Iba pa';

  @override
  String get pasteUrl => 'I-paste ang URL';

  @override
  String get importantNoticeTitle => 'Mahalagang Paunawa';

  @override
  String get importantNoticeBody =>
      'Ang coin na ito ay bahagi ng ETA Network ecosystem at kumakatawan sa pakikilahok sa isang lumalagong digital na komunidad. Ang mga community coin ay nilikha ng mga user upang bumuo, mag-eksperimento, at makipag-ugnayan sa loob ng network. Ang ETA Network ay nasa maagang yugto ng pag-unlad. Habang lumalago ang ecosystem, maaaring ipakilala ang mga bagong utility, feature, at integrasyon batay sa aktibidad ng komunidad, ebolusyon ng platform, at naaangkop na mga alituntunin.';

  @override
  String get pleaseWait => 'Mangyaring maghintay...';

  @override
  String get save => 'I-save';

  @override
  String createCoinFailed(String error) {
    return 'Nabigong lumikha ng coin: $error';
  }

  @override
  String get coinNameLengthError =>
      'Ang pangalan ng coin ay dapat 3–30 character.';

  @override
  String get symbolRequiredError => 'Ang simbolo ay kinakailangan.';

  @override
  String get symbolLengthError => 'Ang simbolo ay dapat 2–6 titik/numero.';

  @override
  String get descriptionTooLongError => 'Masyadong mahaba ang paglalarawan.';

  @override
  String baseRateRangeError(String max) {
    return 'Ang base mining rate ay dapat nasa pagitan ng 0.000000001 at $max.';
  }

  @override
  String get coinNameExistsError =>
      'Umiiral na ang pangalan ng coin. Pumili ng iba.';

  @override
  String get symbolExistsError => 'Umiiral na ang simbolo. Pumili ng iba.';

  @override
  String get urlInvalidError => 'Isa sa mga URL ay hindi wasto.';

  @override
  String get subscribeAndBoost => 'Mag-subscribe at Palakasin ang Pagmimina';

  @override
  String get autoCollect => 'Auto-collect';

  @override
  String autoMineCoins(int count) {
    return 'Auto mine $count coins';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Bilis';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Walang magagamit na paglalarawan.';

  @override
  String get unknownUser => 'Hindi kilala';

  @override
  String get streakLabel => 'STREAK';

  @override
  String get referralsLabel => 'REFERRALS';

  @override
  String get sessionsLabel => 'SESSIONS';

  @override
  String get accountInfoSection => 'Impormasyon ng Account';

  @override
  String get accountInfoTile => 'Impormasyon ng Account';

  @override
  String get invitedByPrompt => 'Inimbitahan ng isang tao?';

  @override
  String get enterReferralCode => 'Ilagay ang referral code';

  @override
  String get invitedStatus => 'Inimbitahan';

  @override
  String get lockedStatus => 'Naka-lock';

  @override
  String get applyButton => 'Ilapat';

  @override
  String get aboutPageTitle => 'Tungkol sa';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Makipag-ugnayan sa Amin';

  @override
  String get securitySettingsTile => 'Mga Setting ng Seguridad';

  @override
  String get securitySettingsPageTitle => 'Mga Setting ng Seguridad';

  @override
  String get deleteAccountTile => 'Tanggalin ang Account';

  @override
  String get deleteAccountSubtitle =>
      'Permanenteng tanggalin ang iyong account at data';

  @override
  String get deleteAccountDialogTitle => 'Tanggalin ang account?';

  @override
  String get deleteAccountDialogContent =>
      'Ito ay permanenteng magtatanggal ng iyong account, data, at mga sesyon. Ang aksyong ito ay hindi maaaring bawiin.';

  @override
  String get deleteButton => 'Tanggalin';

  @override
  String get kycVerificationTile => 'KYC Verification';

  @override
  String get kycVerificationDialogTitle => 'KYC Verification';

  @override
  String get kycComingSoonMessage => 'Ay i-aactivate sa mga darating na yugto.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Mag-logout';

  @override
  String get confirmDeletionTitle => 'Kumpirmahin ang pagtanggal';

  @override
  String get enterAccountPassword => 'Ilagay ang password ng account';

  @override
  String get confirmButton => 'Kumpirmahin';

  @override
  String get usernameLabel => 'Username';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Pangalan';

  @override
  String get ageLabel => 'Edad';

  @override
  String get countryLabel => 'Bansa';

  @override
  String get addressLabel => 'Address';

  @override
  String get genderLabel => 'Kasarian';

  @override
  String get enterUsernameHint => 'Ilagay ang username';

  @override
  String get enterNameHint => 'Ilagay ang pangalan';

  @override
  String get enterAgeHint => 'Ilagay ang edad';

  @override
  String get enterCountryHint => 'Ilagay ang bansa';

  @override
  String get enterAddressHint => 'Ilagay ang address';

  @override
  String get enterGenderHint => 'Ilagay ang kasarian';

  @override
  String get savingLabel => 'Nagsa-save...';

  @override
  String get usernameEmptyError => 'Hindi maaaring walang laman ang username';

  @override
  String get invalidAgeError => 'Maling halaga ng edad';

  @override
  String get saveError => 'Nabigong i-save ang mga pagbabago';

  @override
  String get cancelButton => 'Kanselahin';
}
