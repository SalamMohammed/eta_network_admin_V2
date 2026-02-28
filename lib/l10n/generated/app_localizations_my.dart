// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class AppLocalizationsMy extends AppLocalizations {
  AppLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get totalBalance => 'လက်ကျန်ငွေစုစုပေါင်း';

  @override
  String joinedDate(String link, Object date) {
    return '$date တွင်ဝင်ရောက်ခဲ့သည်';
  }

  @override
  String get inviteEarn => 'ဖိတ်ခေါ်ပြီး ဝင်ငွေရှာပါ';

  @override
  String get shareCodeDescription =>
      'သင်၏ သတ္တုတူးဖော်မှုနှုန်းကို မြှင့်တင်ရန် သူငယ်ချင်းများနှင့် သင့်သီးသန့်ကုဒ်ကို မျှဝေပါ။';

  @override
  String get shareLink => 'လင့်ခ်ကို မျှဝေပါ';

  @override
  String get totalInvited => 'စုစုပေါင်း ဖိတ်ခေါ်ထားသူ';

  @override
  String get activeNow => 'ယခု အသက်ဝင်နေသည်';

  @override
  String get viewAll => 'အားလုံးကြည့်ရှုပါ';

  @override
  String get createCoin => 'Coin ဖန်တီးပါ';

  @override
  String get mining => 'သတ္တုတူးဖော်ခြင်း';

  @override
  String get settings => 'ဆက်တင်များ';

  @override
  String get language => 'ဘာသာစကား';

  @override
  String get languageSubtitle => 'အက်ပ်ဘာသာစကား ပြောင်းလဲပါ';

  @override
  String get selectLanguage => 'ဘာသာစကား ရွေးချယ်ပါ';

  @override
  String get balanceTitle => 'လက်ကျန်ငွေ';

  @override
  String get home => 'ပင်မ';

  @override
  String get referral => 'ရည်ညွှန်းချက်';

  @override
  String get profile => 'ပရိုဖိုင်';

  @override
  String get dayStreak => 'ရက်ဆက်တိုက်';

  @override
  String dayStreakValue(int count) {
    return '$count ရက်ဆက်တိုက်';
  }

  @override
  String get active => 'အသက်ဝင်သည်';

  @override
  String get inactive => 'အသက်မဝင်ပါ';

  @override
  String get sessionEndsIn => 'စက်ရှင် ပြီးဆုံးချိန်';

  @override
  String get startEarning => 'ဝင်ငွေ စတင်ရှာပါ';

  @override
  String get loadingAd => 'ကြော်ငြာ ဖွင့်နေသည်...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds စက္ကန့် စောင့်ပါ';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'ဆုလာဘ် +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'ဆုလာဘ်ရ ကြော်ငြာ မရရှိနိုင်ပါ';

  @override
  String rateBoosted(String rate) {
    return 'နှုန်း မြှင့်တင်ထားသည်: +$rate ETA/နာရီ';
  }

  @override
  String adBonusFailed(String message) {
    return 'ကြော်ငြာ ဘောနပ်စ် မအောင်မြင်ပါ: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'နှုန်း အသေးစိတ်: အခြေခံ $base, ဆက်တိုက် +$streak, အဆင့် +$rank, ရည်ညွှန်းချက်များ +$referrals = $total ETA/နာရီ';
  }

  @override
  String get unableToStartMining =>
      'သတ္တုတူးဖော်ခြင်း စတင်မရပါ။ ကျေးဇူးပြု၍ သင်၏ အင်တာနက် ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်ကြိုးစားပါ။';

  @override
  String get createCommunityCoin => 'အသိုင်းအဝိုင်း Coin ဖန်တီးပါ';

  @override
  String get launchCoinDescription =>
      'သင်၏ ကိုယ်ပိုင် coin ကို ETA ကွန်ရက်တွင် ချက်ချင်း လွှင့်တင်ပါ။';

  @override
  String get createYourOwnCoin => 'သင်၏ ကိုယ်ပိုင် coin ကို ဖန်တီးပါ';

  @override
  String get launchCommunityCoinDescription =>
      'အခြား ETA အသုံးပြုသူများ တူးဖော်နိုင်မည့် သင်၏ ကိုယ်ပိုင် အသိုင်းအဝိုင်း coin ကို လွှင့်တင်ပါ။';

  @override
  String get editCoin => 'Coin ကို ပြင်ဆင်ပါ';

  @override
  String baseRate(String rate) {
    return 'အခြေခံနှုန်း: $rate coin/နာရီ';
  }

  @override
  String createdBy(String username) {
    return '@$username မှ ဖန်တီးသည်';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/နာရီ';
  }

  @override
  String get noCoinsYet =>
      'Coin များ မရှိသေးပါ။ တိုက်ရိုက် Coin များမှ ထည့်ပါ။';

  @override
  String get mine => 'တူးဖော်ပါ';

  @override
  String get remaining => 'ကျန်ရှိနေသည်';

  @override
  String get holders => 'ပိုင်ဆိုင်သူများ';

  @override
  String get close => 'ပိတ်ပါ';

  @override
  String get readMore => 'ပိုမိုဖတ်ရှုရန်';

  @override
  String get readLess => 'လျော့ဖတ်ရန်';

  @override
  String get projectLinks => 'စီမံကိန်း လင့်ခ်များ';

  @override
  String get verifyEmailTitle => 'သင်၏ အီးမေးလ်ကို အတည်ပြုပါ';

  @override
  String get verifyEmailMessage =>
      'သင်၏ အီးမေးလ်လိပ်စာသို့ အတည်ပြုလင့်ခ်တစ်ခု ပေးပို့လိုက်ပါပြီ။ အင်္ဂါရပ်အားလုံးကို ဖွင့်ရန် ကျေးဇူးပြု၍ သင်၏ အကောင့်ကို အတည်ပြုပါ။';

  @override
  String get resendEmail => 'အီးမေးလ် ပြန်ပို့ပါ';

  @override
  String get iHaveVerified => 'ကျွန်ုပ် အတည်ပြုပြီးပါပြီ';

  @override
  String get logout => 'ထွက်ရန်';

  @override
  String get emailVerifiedSuccess => 'အီးမေးလ် အောင်မြင်စွာ အတည်ပြုပြီးပြီ!';

  @override
  String get emailNotVerified =>
      'အီးမေးလ် အတည်မပြုရသေးပါ။ ကျေးဇူးပြု၍ သင်၏ စာတိုက်ပုံးကို စစ်ဆေးပါ။';

  @override
  String get verificationEmailSent => 'အတည်ပြု အီးမေးလ် ပေးပို့ပြီး';

  @override
  String get startMining => 'သတ္တုတူးဖော်ခြင်း စတင်ပါ';

  @override
  String get minedCoins => 'တူးဖော်ရရှိသော Coin များ';

  @override
  String get liveCoins => 'တိုက်ရိုက် Coin များ';

  @override
  String get asset => 'ပိုင်ဆိုင်မှု';

  @override
  String get filterStatus => 'အခြေအနေ';

  @override
  String get filterPopular => 'လူကြိုက်များသော';

  @override
  String get filterNames => 'အမည်များ';

  @override
  String get filterOldNew => 'အဟောင်း - အသစ်';

  @override
  String get filterNewOld => 'အသစ် - အဟောင်း';

  @override
  String startMiningWithCount(int count) {
    return 'သတ္တုတူးဖော်ခြင်း စတင်ပါ ($count)';
  }

  @override
  String get clearSelection => 'ရွေးချယ်မှု ရှင်းပါ';

  @override
  String get cancel => 'မလုပ်တော့ပါ';

  @override
  String get refreshStatus => 'အခြေအနေ ပြန်လည်ဆန်းသစ်ပါ';

  @override
  String get purchaseFailed => 'ဝယ်ယူမှု မအောင်မြင်ပါ';

  @override
  String get securePaymentViaGooglePlay =>
      'Google Play မှတစ်ဆင့် လုံခြုံသော ငွေပေးချေမှု';

  @override
  String get addedToMinedCoins => 'တူးဖော်ရရှိသော Coin များသို့ ထည့်ပြီး';

  @override
  String failedToAdd(String message) {
    return 'ထည့်ရန် မအောင်မြင်ပါ: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'စာရင်းသွင်းမှုများသည် Android/iOS တွင်သာ ရရှိနိုင်ပါသည်။';

  @override
  String get miningRate => 'သတ္တုတူးဖော်မှုနှုန်း';

  @override
  String get about => 'အကြောင်း';

  @override
  String get yourMined => 'သင် တူးဖော်ရရှိသော';

  @override
  String get totalMined => 'စုစုပေါင်း တူးဖော်ရရှိသော';

  @override
  String get noReferrals => 'ရည်ညွှန်းချက်များ မရှိသေးပါ';

  @override
  String get linkCopied => 'လင့်ခ် ကူးယူပြီး';

  @override
  String get copy => 'ကူးယူပါ';

  @override
  String get howItWorks => 'လုပ်ဆောင်ပုံ';

  @override
  String get referralDescription =>
      'သူငယ်ချင်းများနှင့် သင်၏ ကုဒ်ကို မျှဝေပါ။ သူတို့ ဝင်ရောက်ပြီး အသက်ဝင်လာသောအခါ၊ သင်၏ အဖွဲ့ ကြီးထွားလာပြီး သင်၏ ဝင်ငွေ အလားအလာ တိုးတက်လာသည်။';

  @override
  String get yourTeam => 'သင်၏ အဖွဲ့';

  @override
  String get referralsTitle => 'ရည်ညွှန်းချက်များ';

  @override
  String get shareLinkTitle => 'လင့်ခ်ကို မျှဝေပါ';

  @override
  String get copyLinkInstruction => 'မျှဝေရန် ဤလင့်ခ်ကို ကူးယူပါ:';

  @override
  String get referralCodeCopied => 'ရည်ညွှန်းကုဒ် ကူးယူပြီး';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network တွင် ကျွန်ုပ်နှင့် ပူးပေါင်းပါ! ကျွန်ုပ်၏ ကုဒ်ကို သုံးပါ: $code $link';
  }

  @override
  String get etaNetwork => 'ETA ကွန်ရက်';

  @override
  String get noLiveCommunityCoins =>
      'တိုက်ရိုက် အသိုင်းအဝိုင်း Coin များ မရှိပါ';

  @override
  String get rate => 'နှုန်း';

  @override
  String get filterRandom => 'ကျပန်း';

  @override
  String get baseRateLabel => 'အခြေခံနှုန်း';

  @override
  String startFailed(String error) {
    return 'စတင်ရန် မအောင်မြင်ပါ: $error';
  }

  @override
  String get sessionProgress => 'စက်ရှင် တိုးတက်မှု';

  @override
  String get remainingLabel => 'ကျန်ရှိနေသည်';

  @override
  String get boostRate => 'မြှင့်တင်နှုန်း';

  @override
  String get minedLabel => 'တူးဖော်ရရှိပြီး';

  @override
  String get noSubscriptionPlansAvailable =>
      'စာရင်းသွင်းမှု အစီအစဉ်များ မရရှိနိုင်ပါ';

  @override
  String get subscriptionPlans => 'စာရင်းသွင်းမှု အစီအစဉ်များ';

  @override
  String get recommended => 'အကြံပြုထားသော';

  @override
  String get editCommunityCoin => 'အသိုင်းအဝိုင်း Coin ကို ပြင်ဆင်ပါ';

  @override
  String get launchCoinEcosystemDescription =>
      'သင်၏ အသိုင်းအဝိုင်းအတွက် ETA ဂေဟစနစ်အတွင်း သင်၏ ကိုယ်ပိုင် coin ကို လွှင့်တင်ပါ။';

  @override
  String get upload => 'တင်ပါ';

  @override
  String get recommendedImageSize => 'အကြံပြုထားသော 200x200px';

  @override
  String get coinNameLabel => 'Coin အမည်';

  @override
  String get symbolLabel => 'သင်္ကေတ';

  @override
  String get descriptionLabel => 'ဖော်ပြချက်';

  @override
  String get baseMiningRateLabel => 'အခြေခံ သတ္တုတူးဖော်မှုနှုန်း (coin/နာရီ)';

  @override
  String maxAllowed(String max) {
    return 'အများဆုံး ခွင့်ပြုထားသည် : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'လူမှုရေး & စီမံကိန်း လင့်ခ်များ (ရွေးချယ်နိုင်သည်)';

  @override
  String get linkTypeWebsite => 'ဝဘ်ဆိုဒ်';

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
  String get linkTypeOther => 'အခြား';

  @override
  String get pasteUrl => 'URL ကို ကူးထည့်ပါ';

  @override
  String get importantNoticeTitle => 'အရေးကြီး အသိပေးချက်';

  @override
  String get importantNoticeBody =>
      'ဤ coin သည် ETA Network ဂေဟစနစ်၏ အစိတ်အပိုင်းဖြစ်ပြီး ကြီးထွားနေသော ဒစ်ဂျစ်တယ် အသိုင်းအဝိုင်းတွင် ပါဝင်မှုကို ကိုယ်စားပြုသည်။ အသိုင်းအဝိုင်း coin များကို အသုံးပြုသူများက ကွန်ရက်အတွင်း တည်ဆောက်ရန်၊ စမ်းသပ်ရန်နှင့် ပါဝင်ရန် ဖန်တီးထားသည်။ ETA Network သည် ဖွံ့ဖြိုးတိုးတက်မှု အစောပိုင်းအဆင့်တွင် ရှိနေသည်။ ဂေဟစနစ် ကြီးထွားလာသည်နှင့်အမျှ၊ အသိုင်းအဝိုင်း လှုပ်ရှားမှု၊ ပလက်ဖောင်း ပြောင်းလဲတိုးတက်မှုနှင့် သက်ဆိုင်ရာ လမ်းညွှန်ချက်များအပေါ် အခြေခံ၍ အသုံးချမှုများ၊ အင်္ဂါရပ်များနှင့် ပေါင်းစပ်မှု အသစ်များကို မိတ်ဆက်ပေးနိုင်ပါသည်။';

  @override
  String get pleaseWait => 'ကျေးဇူးပြု၍ စောင့်ပါ...';

  @override
  String get save => 'သိမ်းဆည်းပါ';

  @override
  String createCoinFailed(String error) {
    return 'Coin ဖန်တီးရန် မအောင်မြင်ပါ: $error';
  }

  @override
  String get coinNameLengthError => 'Coin အမည်သည် ၃-၃၀ စာလုံး ရှိရမည်။';

  @override
  String get symbolRequiredError => 'သင်္ကေတ လိုအပ်သည်။';

  @override
  String get symbolLengthError => 'သင်္ကေတသည် ၂-၆ စာလုံး/ဂဏန်း ရှိရမည်။';

  @override
  String get descriptionTooLongError => 'ဖော်ပြချက် သိပ်ရှည်သည်။';

  @override
  String baseRateRangeError(String max) {
    return 'အခြေခံ သတ္တုတူးဖော်မှုနှုန်းသည် 0.000000001 နှင့် $max ကြား ရှိရမည်။';
  }

  @override
  String get coinNameExistsError =>
      'Coin အမည် ရှိပြီးသားပါ။ ကျေးဇူးပြု၍ အခြားတစ်ခု ရွေးပါ။';

  @override
  String get symbolExistsError =>
      'သင်္ကေတ ရှိပြီးသားပါ။ ကျေးဇူးပြု၍ အခြားတစ်ခု ရွေးပါ။';

  @override
  String get urlInvalidError => 'URL တစ်ခု မမှန်ကန်ပါ။';

  @override
  String get subscribeAndBoost =>
      'စာရင်းသွင်းပြီး သတ္တုတူးဖော်မှုကို မြှင့်တင်ပါ';

  @override
  String get autoCollect => 'အလိုအလျောက် စုဆောင်းပါ';

  @override
  String autoMineCoins(int count) {
    return '$count coin များကို အလိုအလျောက် တူးဖော်ပါ';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% အမြန်နှုန်း';
  }

  @override
  String get perHourSuffix => '/နာရီ';

  @override
  String get etaPerHourSuffix => 'ETA/နာရီ';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'ဖော်ပြချက် မရရှိနိုင်ပါ။';

  @override
  String get unknownUser => 'မသိသော';

  @override
  String get streakLabel => 'ဆက်တိုက်';

  @override
  String get referralsLabel => 'ရည်ညွှန်းချက်များ';

  @override
  String get sessionsLabel => 'စက်ရှင်များ';

  @override
  String get accountInfoSection => 'အကောင့် အချက်အလက်';

  @override
  String get accountInfoTile => 'အကောင့် အချက်အလက်';

  @override
  String get invitedByPrompt => 'တစ်စုံတစ်ဦးမှ ဖိတ်ခေါ်ထားပါသလား။';

  @override
  String get enterReferralCode => 'ရည်ညွှန်းကုဒ် ထည့်ပါ';

  @override
  String get invitedStatus => 'ဖိတ်ခေါ်ထားသည်';

  @override
  String get lockedStatus => 'သော့ခတ်ထားသည်';

  @override
  String get applyButton => 'အသုံးပြုပါ';

  @override
  String get aboutPageTitle => 'အကြောင်း';

  @override
  String get faqTile => 'မေးလေ့ရှိသော မေးခွန်းများ';

  @override
  String get whitePaperTile => 'စာတမ်းဖြူ';

  @override
  String get contactUsTile => 'ကျွန်ုပ်တို့ကို ဆက်သွယ်ပါ';

  @override
  String get securitySettingsTile => 'လုံခြုံရေး ဆက်တင်များ';

  @override
  String get securitySettingsPageTitle => 'လုံခြုံရေး ဆက်တင်များ';

  @override
  String get deleteAccountTile => 'အကောင့် ဖျက်ပါ';

  @override
  String get deleteAccountSubtitle =>
      'သင့်အကောင့်နှင့် ဒေတာကို အပြီးအပိုင် ဖျက်ပါ';

  @override
  String get deleteAccountDialogTitle => 'အကောင့် ဖျက်မလား။';

  @override
  String get deleteAccountDialogContent =>
      'ဒါက သင့်အကောင့်၊ ဒေတာနှင့် စက်ရှင်များကို အပြီးအပိုင် ဖျက်ပါလိမ့်မည်။ ဤလုပ်ဆောင်ချက်ကို ပြန်ပြင်မရပါ။';

  @override
  String get deleteButton => 'ဖျက်ပါ';

  @override
  String get kycVerificationTile => 'KYC အတည်ပြုခြင်း';

  @override
  String get kycVerificationDialogTitle => 'KYC အတည်ပြုခြင်း';

  @override
  String get kycComingSoonMessage => 'လာမည့် အဆင့်များတွင် အသက်သွင်းပါမည်။';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'ထွက်ရန်';

  @override
  String get confirmDeletionTitle => 'ဖျက်ခြင်းကို အတည်ပြုပါ';

  @override
  String get enterAccountPassword => 'အကောင့် စကားဝှက် ထည့်ပါ';

  @override
  String get confirmButton => 'အတည်ပြုပါ';

  @override
  String get usernameLabel => 'အသုံးပြုသူအမည်';

  @override
  String get emailLabel => 'အီးမေးလ်';

  @override
  String get nameLabel => 'အမည်';

  @override
  String get ageLabel => 'အသက်';

  @override
  String get countryLabel => 'နိုင်ငံ';

  @override
  String get addressLabel => 'လိပ်စာ';

  @override
  String get genderLabel => 'ကျား/မ';

  @override
  String get enterUsernameHint => 'အသုံးပြုသူအမည် ထည့်ပါ';

  @override
  String get enterNameHint => 'အမည် ထည့်ပါ';

  @override
  String get enterAgeHint => 'အသက် ထည့်ပါ';

  @override
  String get enterCountryHint => 'နိုင်ငံ ထည့်ပါ';

  @override
  String get enterAddressHint => 'လိပ်စာ ထည့်ပါ';

  @override
  String get enterGenderHint => 'ကျား/မ ထည့်ပါ';

  @override
  String get savingLabel => 'သိမ်းဆည်းနေသည်...';

  @override
  String get usernameEmptyError => 'အသုံးပြုသူအမည် ဗလာမဖြစ်ရပါ';

  @override
  String get invalidAgeError => 'မမှန်ကန်သော အသက် တန်ဖိုး';

  @override
  String get saveError => 'ပြောင်းလဲမှုများ သိမ်းဆည်းရန် မအောင်မြင်ပါ';

  @override
  String get cancelButton => 'မလုပ်တော့ပါ';
}
