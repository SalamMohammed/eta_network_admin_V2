// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Igbo (`ig`).
class AppLocalizationsIg extends AppLocalizations {
  AppLocalizationsIg([String locale = 'ig']) : super(locale);

  @override
  String get totalBalance => 'Ngụkọta Ego';

  @override
  String joinedDate(String link, Object date) {
    return 'Onye sonyere $date';
  }

  @override
  String get inviteEarn => 'Kpọọ ma Nweta';

  @override
  String get shareCodeDescription =>
      'Kekọrịta koodu pụrụ iche gị na ndị enyi iji bulie ọnụego igwu ala gị.';

  @override
  String get shareLink => 'Kekọrịta Njikọ';

  @override
  String get totalInvited => 'Ngụkọta Ndị Akpọrọ';

  @override
  String get activeNow => 'Na-arụ ọrụ Ugbu a';

  @override
  String get viewAll => 'Lelee Niile';

  @override
  String get createCoin => 'Mepụta Mkpụrụ Ego';

  @override
  String get mining => 'Igwu ala';

  @override
  String get settings => 'Ntọala';

  @override
  String get language => 'Asụsụ';

  @override
  String get languageSubtitle => 'Gbanwee asụsụ ngwa';

  @override
  String get selectLanguage => 'Họrọ Asụsụ';

  @override
  String get balanceTitle => 'Ego';

  @override
  String get home => 'Ụlọ';

  @override
  String get referral => 'Ntụaka';

  @override
  String get profile => 'Profaịlụ';

  @override
  String get dayStreak => 'Ụbọchị Streak';

  @override
  String dayStreakValue(int count) {
    return '$count Ụbọchị Streak';
  }

  @override
  String get active => 'Na-arụ ọrụ';

  @override
  String get inactive => 'Anaghị arụ ọrụ';

  @override
  String get sessionEndsIn => 'Oge na-agwụ na';

  @override
  String get startEarning => 'Malite Inweta Ego';

  @override
  String get loadingAd => 'Na-ebuba mgbasa ozi...';

  @override
  String waitSeconds(int seconds) {
    return 'Chere ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Nkwụghachi +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Mgbasa ozi akwụghachi adịghị';

  @override
  String rateBoosted(String rate) {
    return 'Ọnụego abawanyela: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ego mgbasa ozi dara: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Nkọwa ọnụego: Isi $base, Streak +$streak, Ọkwa +$rank, Ntụaka +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Enweghị ike ibido igwu ala. Biko lelee njikọ ịntanetị gị ma nwaa ọzọ.';

  @override
  String get createCommunityCoin => 'Mepụta Mkpụrụ Ego Obodo';

  @override
  String get launchCoinDescription =>
      'Bido mkpụrụ ego nke gị na netwọk ETA ozugbo.';

  @override
  String get createYourOwnCoin => 'Mepụta mkpụrụ ego nke gị';

  @override
  String get launchCommunityCoinDescription =>
      'Bido mkpụrụ ego obodo gị nke ndị ọrụ ETA ndị ọzọ nwere ike igwu.';

  @override
  String get editCoin => 'Dezie mkpụrụ ego';

  @override
  String baseRate(String rate) {
    return 'Ọnụego isi: $rate mkpụrụ ego/awa';
  }

  @override
  String createdBy(String username) {
    return 'Onye kere ya @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Enweghị mkpụrụ ego ka. Tinye site na Live Coins.';

  @override
  String get mine => 'Gwuo ala';

  @override
  String get remaining => 'fọdụrụ';

  @override
  String get holders => 'Ndị nwe';

  @override
  String get close => 'Mechie';

  @override
  String get readMore => 'Gụkwuo';

  @override
  String get readLess => 'Gụọ Obere';

  @override
  String get projectLinks => 'Njikọ Ihe Omume';

  @override
  String get verifyEmailTitle => 'Nyochaa Email Gị';

  @override
  String get verifyEmailMessage =>
      'Anyị ezigara njikọ nkwenye na adreesị email gị. Biko nyochaa akaụntụ gị iji kpọghee atụmatụ niile.';

  @override
  String get resendEmail => 'Ziga Email Ọzọ';

  @override
  String get iHaveVerified => 'Enyochala m';

  @override
  String get logout => 'Wepụ';

  @override
  String get emailVerifiedSuccess => 'Enyochara email nke ọma!';

  @override
  String get emailNotVerified =>
      'Enyochabeghị email. Biko lelee igbe mbata gị.';

  @override
  String get verificationEmailSent => 'Ezigara email nkwenye';

  @override
  String get startMining => 'Malite Igwu Ala';

  @override
  String get minedCoins => 'Mkpụrụ Ego Egwuru';

  @override
  String get liveCoins => 'Mkpụrụ Ego Dị Ndụ';

  @override
  String get asset => 'Akụ';

  @override
  String get filterStatus => 'Ọnọdụ';

  @override
  String get filterPopular => 'Na-ewu Ewu';

  @override
  String get filterNames => 'Aha';

  @override
  String get filterOldNew => 'Ochie - Ọhụrụ';

  @override
  String get filterNewOld => 'Ọhụrụ - Ochie';

  @override
  String startMiningWithCount(int count) {
    return 'Bido Igwu ($count)';
  }

  @override
  String get clearSelection => 'Kpochapụ Nhọrọ';

  @override
  String get cancel => 'Kagbuo';

  @override
  String get refreshStatus => 'Hazenye Ọnọdụ';

  @override
  String get purchaseFailed => 'Ịzụta Dara';

  @override
  String get securePaymentViaGooglePlay =>
      'Ịkwụ Ụgwọ Echekwara site na Google Play';

  @override
  String get addedToMinedCoins => 'Agbakwunyere na Mkpụrụ Ego Egwupụtara';

  @override
  String failedToAdd(String message) {
    return 'Agbakwunyeghị: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Ndebanye aha dị naanị na Android/iOS.';

  @override
  String get miningRate => 'Ọnụego Igwu';

  @override
  String get about => 'Banyere';

  @override
  String get yourMined => 'Nke I Gwupụtara';

  @override
  String get totalMined => 'Mkpokọta Egwupụtara';

  @override
  String get noReferrals => 'Enweghị ntụaka ka dị';

  @override
  String get linkCopied => 'E depụtaghachiri Njikọ';

  @override
  String get copy => 'Detuo';

  @override
  String get howItWorks => 'Otu O Si Arụ Ọrụ';

  @override
  String get referralDescription =>
      'Kekọrịta koodu gị na ndị enyi. Mgbe ha sonyeere ma na-arụ ọrụ, ị na-eto otu gị ma melite ikike ịkpata ego gị.';

  @override
  String get yourTeam => 'Otu Gị';

  @override
  String get referralsTitle => 'Ntụaka';

  @override
  String get shareLinkTitle => 'Kekọrịta Njikọ';

  @override
  String get copyLinkInstruction => 'Detuo njikọ a ka ị kekọrịta:';

  @override
  String get referralCodeCopied => 'E depụtaghachiri Koodu Ntụaka';

  @override
  String joinMeText(String code, String link) {
    return 'Sonyeere m na Eta Network! Jiri koodu m: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Enweghị Mkpụrụ Ego Obodo Dị Ndụ';

  @override
  String get rate => 'Ọnụego';

  @override
  String get filterRandom => 'Na-enweghị Usoro';

  @override
  String get baseRateLabel => 'Ọnụego Isi';

  @override
  String startFailed(String error) {
    return 'Mbido Dara: $error';
  }

  @override
  String get sessionProgress => 'Ọganihu Oge';

  @override
  String get remainingLabel => 'Fọdụrụ';

  @override
  String get boostRate => 'Ọnụego Nkwalite';

  @override
  String get minedLabel => 'Egwupụtara';

  @override
  String get noSubscriptionPlansAvailable => 'Enweghị Atụmatụ Ndebanye Aha Dị';

  @override
  String get subscriptionPlans => 'Atụmatụ Ndebanye Aha';

  @override
  String get recommended => 'Akwadoro';

  @override
  String get editCommunityCoin => 'Dezie Mkpụrụ Ego Obodo';

  @override
  String get launchCoinEcosystemDescription =>
      'Bido mkpụrụ ego gị n\'ime usoro ETA maka obodo gị.';

  @override
  String get upload => 'Bulite';

  @override
  String get recommendedImageSize => 'Akwadoro 200×200px';

  @override
  String get coinNameLabel => 'Aha Mkpụrụ Ego';

  @override
  String get symbolLabel => 'Akara';

  @override
  String get descriptionLabel => 'Nkọwa';

  @override
  String get baseMiningRateLabel => 'Ọnụego Igwu Isi (mkpụrụ ego/awa)';

  @override
  String maxAllowed(String max) {
    return 'Kachasị ekwe: $max';
  }

  @override
  String get socialProjectLinksOptional => 'Njikọ Ọha & Ọrụ (Nhọrọ)';

  @override
  String get linkTypeWebsite => 'Webụsaịtị';

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
  String get linkTypeOther => 'Ọzọ';

  @override
  String get pasteUrl => 'Mapado URL';

  @override
  String get importantNoticeTitle => 'Ọkwa Dị Mkpa';

  @override
  String get importantNoticeBody =>
      'Mkpụrụ ego a bụ akụkụ nke usoro ETA Network ma na-anọchite anya itinye aka na obodo dijitalụ na-eto eto. A na-emepụta Mkpụrụ Ego Obodo site n\'aka ndị ọrụ iji wuo, nweta ahụmahụ, na itinye aka n\'ime netwọk ahụ. ETA Network nọ na mmalite nke mmepe. Ka usoro ahụ na-eto, enwere ike iwebata uru, atụmatụ, na njikọta ọhụrụ dabere na ọrụ obodo, mgbanwe ikpo okwu, na ụkpụrụ ndị dịnụ.';

  @override
  String get pleaseWait => 'Biko chere...';

  @override
  String get save => 'Chekwaa';

  @override
  String createCoinFailed(String error) {
    return 'Mepụta Mkpụrụ Ego Dara: $error';
  }

  @override
  String get coinNameLengthError =>
      'Aha mkpụrụ ego ga-adị n\'etiti mkpụrụedemede 3-30.';

  @override
  String get symbolRequiredError => 'Achọrọ Akara.';

  @override
  String get symbolLengthError => 'Akara ga-abụ mkpụrụedemede/nọmba 2-6.';

  @override
  String get descriptionTooLongError => 'Nkọwa dị ogologo nke ukwuu.';

  @override
  String baseRateRangeError(String max) {
    return 'Ọnụego Igwu Isi ga-adị n\'etiti 0.000000001 na $max.';
  }

  @override
  String get coinNameExistsError => 'Aha mkpụrụ ego dịlarị. Biko họrọ ọzọ.';

  @override
  String get symbolExistsError => 'Akara dịlarị. Biko họrọ ọzọ.';

  @override
  String get urlInvalidError => 'Otu n\'ime URL adịghị mma.';

  @override
  String get subscribeAndBoost => 'Debanye aha & Kwalite Igwu';

  @override
  String get autoCollect => 'Nchịkọta Onwe';

  @override
  String autoMineCoins(int count) {
    return 'Gwuo $count Mkpụrụ Ego Onwe';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Ọsọ';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Enweghị nkọwa dị.';

  @override
  String get unknownUser => 'Amaghị';

  @override
  String get streakLabel => 'Usoro';

  @override
  String get referralsLabel => 'Ntụaka';

  @override
  String get sessionsLabel => 'Oge';

  @override
  String get accountInfoSection => 'Ozi Akaụntụ';

  @override
  String get accountInfoTile => 'Ozi Akaụntụ';

  @override
  String get invitedByPrompt => 'Onye kpọrọ gị?';

  @override
  String get enterReferralCode => 'Tinye Koodu Ntụaka';

  @override
  String get invitedStatus => 'Akpọrọ';

  @override
  String get lockedStatus => 'Akpọchiri';

  @override
  String get applyButton => 'Tinye';

  @override
  String get aboutPageTitle => 'Banyere';

  @override
  String get faqTile => 'Ajụjụ A Na-ajụkarị';

  @override
  String get whitePaperTile => 'Akwụkwọ Ọcha';

  @override
  String get contactUsTile => 'Kpọtụrụ Anyị';

  @override
  String get securitySettingsTile => 'Ntọala Nchekwa';

  @override
  String get securitySettingsPageTitle => 'Ntọala Nchekwa';

  @override
  String get deleteAccountTile => 'Hichapụ Akaụntụ';

  @override
  String get deleteAccountSubtitle => 'Hichapụ akaụntụ gị na data gị kpamkpam';

  @override
  String get deleteAccountDialogTitle => 'Hichapụ Akaụntụ?';

  @override
  String get deleteAccountDialogContent =>
      'Nke a ga-ehichapụ akaụntụ gị, data, na oge gị kpamkpam. Enweghị ike ịmegharị ihe a.';

  @override
  String get deleteButton => 'Hichapụ';

  @override
  String get kycVerificationTile => 'Nkwenye KYC';

  @override
  String get kycVerificationDialogTitle => 'Nkwenye KYC';

  @override
  String get kycComingSoonMessage => 'A ga-arụ ọrụ na usoro ndị na-abịa.';

  @override
  String get okButton => 'DỊ MMA';

  @override
  String get logOutLabel => 'Wepụ';

  @override
  String get confirmDeletionTitle => 'Kwenye Nhichapụ';

  @override
  String get enterAccountPassword => 'Tinye paswọọdụ akaụntụ';

  @override
  String get confirmButton => 'Kwenye';

  @override
  String get usernameLabel => 'Aha njirimara';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Aha';

  @override
  String get ageLabel => 'Afọ';

  @override
  String get countryLabel => 'Obodo';

  @override
  String get addressLabel => 'Adreesị';

  @override
  String get genderLabel => 'Okike';

  @override
  String get enterUsernameHint => 'Tinye aha njirimara';

  @override
  String get enterNameHint => 'Tinye aha';

  @override
  String get enterAgeHint => 'Tinye afọ';

  @override
  String get enterCountryHint => 'Tinye obodo';

  @override
  String get enterAddressHint => 'Tinye adreesị';

  @override
  String get enterGenderHint => 'Tinye okike';

  @override
  String get savingLabel => 'Na-echekwa...';

  @override
  String get usernameEmptyError => 'Aha njirimara enweghị ike ịbụ ihe efu';

  @override
  String get invalidAgeError => 'Uru afọ adịghị mma';

  @override
  String get saveError => 'Echekwaghị mgbanwe';

  @override
  String get cancelButton => 'Kagbuo';
}
