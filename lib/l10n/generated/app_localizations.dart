import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// The total balance shown on the wallet summary card
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get totalBalance;

  /// Date when user joined
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedDate(String link, Object date);

  /// Title for invite section
  ///
  /// In en, this message translates to:
  /// **'Invite & Earn'**
  String get inviteEarn;

  /// Description for sharing code
  ///
  /// In en, this message translates to:
  /// **'Share your unique code with friends to boost your mining rate.'**
  String get shareCodeDescription;

  /// Button text to share link
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLink;

  /// Label for total invited count
  ///
  /// In en, this message translates to:
  /// **'TOTAL INVITED'**
  String get totalInvited;

  /// Label for active invited count
  ///
  /// In en, this message translates to:
  /// **'ACTIVE NOW'**
  String get activeNow;

  /// Button text to view all items
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// Button to create a new coin
  ///
  /// In en, this message translates to:
  /// **'Create Coin'**
  String get createCoin;

  /// Mining status or label
  ///
  /// In en, this message translates to:
  /// **'Mining'**
  String get mining;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting title
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Subtitle for language setting
  ///
  /// In en, this message translates to:
  /// **'Change app language'**
  String get languageSubtitle;

  /// Title for language selection page
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Title for the balance page
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceTitle;

  /// Bottom navigation label for Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Bottom navigation label for Referral
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral;

  /// Bottom navigation label for Profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Label for Day Streak
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get dayStreak;

  /// Day Streak value with count
  ///
  /// In en, this message translates to:
  /// **'{count} Day Streak'**
  String dayStreakValue(int count);

  /// Status label for Active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Status label for Inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Label for session countdown
  ///
  /// In en, this message translates to:
  /// **'Session ends in'**
  String get sessionEndsIn;

  /// Button text to start mining/earning
  ///
  /// In en, this message translates to:
  /// **'Start Earning'**
  String get startEarning;

  /// Text shown when ad is loading
  ///
  /// In en, this message translates to:
  /// **'Loading ad…'**
  String get loadingAd;

  /// Text shown during ad cooldown
  ///
  /// In en, this message translates to:
  /// **'Wait {seconds}s'**
  String waitSeconds(int seconds);

  /// Text showing reward percentage
  ///
  /// In en, this message translates to:
  /// **'Reward +{percent}%'**
  String rewardPlusPercent(String percent);

  /// Snackbar text when rewarded ad is unavailable
  ///
  /// In en, this message translates to:
  /// **'Rewarded ad not available'**
  String get rewardedAdNotAvailable;

  /// Snackbar text when mining rate is boosted
  ///
  /// In en, this message translates to:
  /// **'Rate boosted: +{rate} ETA/hr'**
  String rateBoosted(String rate);

  /// Snackbar text when applying ad bonus fails
  ///
  /// In en, this message translates to:
  /// **'Ad bonus failed: {message}'**
  String adBonusFailed(String message);

  /// Debug snackbar showing rate breakdown
  ///
  /// In en, this message translates to:
  /// **'Rate breakdown: Base {base}, Streak +{streak}, Rank +{rank}, Referrals +{referrals} = {total} ETA/hr'**
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  );

  /// Snackbar text when mining start fails
  ///
  /// In en, this message translates to:
  /// **'Unable to start mining. Please check your internet connection and try again.'**
  String get unableToStartMining;

  /// Title for creating a community coin
  ///
  /// In en, this message translates to:
  /// **'Create Community Coin'**
  String get createCommunityCoin;

  /// Description for launching a coin
  ///
  /// In en, this message translates to:
  /// **'Launch your own coin on ETA Network instantly.'**
  String get launchCoinDescription;

  /// Alternative title for creating a coin
  ///
  /// In en, this message translates to:
  /// **'Create your own coin'**
  String get createYourOwnCoin;

  /// Alternative description for launching a coin
  ///
  /// In en, this message translates to:
  /// **'Launch your own community coin that other ETA users can mine.'**
  String get launchCommunityCoinDescription;

  /// Button to edit a coin
  ///
  /// In en, this message translates to:
  /// **'Edit coin'**
  String get editCoin;

  /// Base mining rate
  ///
  /// In en, this message translates to:
  /// **'Base rate: {rate} coins/hour'**
  String baseRate(String rate);

  /// Creator attribution
  ///
  /// In en, this message translates to:
  /// **'Created by @{username}'**
  String createdBy(String username);

  /// Mining rate in ETA/hr
  ///
  /// In en, this message translates to:
  /// **'+{rate} ETA/hr'**
  String etaPerHr(String rate);

  /// Message when no coins are mined
  ///
  /// In en, this message translates to:
  /// **'No coins yet. Add from Live Coins.'**
  String get noCoinsYet;

  /// Verb to mine
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// Text indicating time remaining
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remaining;

  /// Label for number of holders
  ///
  /// In en, this message translates to:
  /// **'Holders'**
  String get holders;

  /// Button text to close a dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Link text to expand description
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// Link text to collapse description
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get readLess;

  /// Header for project links
  ///
  /// In en, this message translates to:
  /// **'Project Links'**
  String get projectLinks;

  /// Title for email verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyEmailTitle;

  /// Message for email verification
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification link to your email address. Please verify your account to unlock all features.'**
  String get verifyEmailMessage;

  /// Button text to resend verification email
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// Button text to confirm verification
  ///
  /// In en, this message translates to:
  /// **'I have verified'**
  String get iHaveVerified;

  /// Button text to logout
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Success message for email verification
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccess;

  /// Error message when email is not verified
  ///
  /// In en, this message translates to:
  /// **'Email not verified yet. Please check your inbox.'**
  String get emailNotVerified;

  /// Message confirming verification email sent
  ///
  /// In en, this message translates to:
  /// **'Verification email sent'**
  String get verificationEmailSent;

  /// Button text to start mining
  ///
  /// In en, this message translates to:
  /// **'Start Mining'**
  String get startMining;

  /// Tab label for Mined coins
  ///
  /// In en, this message translates to:
  /// **'Mined Coins'**
  String get minedCoins;

  /// Tab label for Live coins
  ///
  /// In en, this message translates to:
  /// **'Live Coins'**
  String get liveCoins;

  /// Label for Asset
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get asset;

  /// Filter label for Status
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// Filter option for Popular
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterPopular;

  /// Filter option for Names
  ///
  /// In en, this message translates to:
  /// **'Names'**
  String get filterNames;

  /// Filter option for Old to New
  ///
  /// In en, this message translates to:
  /// **'Old - New'**
  String get filterOldNew;

  /// Filter option for New to Old
  ///
  /// In en, this message translates to:
  /// **'New - Old'**
  String get filterNewOld;

  /// Button text to start mining with selection count
  ///
  /// In en, this message translates to:
  /// **'Start Mining ({count})'**
  String startMiningWithCount(int count);

  /// Button text to clear current selection
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// Button text to cancel and close dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button text to refresh verification status
  ///
  /// In en, this message translates to:
  /// **'Refresh Status'**
  String get refreshStatus;

  /// Snackbar text when purchase fails
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get purchaseFailed;

  /// Text indicating secure Google Play payment
  ///
  /// In en, this message translates to:
  /// **'Secure payment via Google Play'**
  String get securePaymentViaGooglePlay;

  /// Snackbar text when a coin is added to mined coins
  ///
  /// In en, this message translates to:
  /// **'Added to Mined Coins'**
  String get addedToMinedCoins;

  /// Snackbar text when adding a coin fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add: {message}'**
  String failedToAdd(String message);

  /// Snackbar text when subscriptions are not available on this platform
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are only available on Android/iOS.'**
  String get subscriptionsUnavailable;

  /// Label for Mining rate
  ///
  /// In en, this message translates to:
  /// **'Mining rate'**
  String get miningRate;

  /// Label for About section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Label for user's mined amount
  ///
  /// In en, this message translates to:
  /// **'Your Mined'**
  String get yourMined;

  /// Label for Total Mined amount
  ///
  /// In en, this message translates to:
  /// **'Total Mined'**
  String get totalMined;

  /// Message when user has no referrals
  ///
  /// In en, this message translates to:
  /// **'No referrals yet'**
  String get noReferrals;

  /// Snackbar text when link is copied
  ///
  /// In en, this message translates to:
  /// **'Link copied'**
  String get linkCopied;

  /// Button text to copy link
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Title for How it works section
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// Description of the referral program
  ///
  /// In en, this message translates to:
  /// **'Share your code with friends. When they join and become active, you grow your team and improve your earning potential.'**
  String get referralDescription;

  /// Title for the team section
  ///
  /// In en, this message translates to:
  /// **'Your Team'**
  String get yourTeam;

  /// Title for the Referrals page
  ///
  /// In en, this message translates to:
  /// **'Referrals'**
  String get referralsTitle;

  /// Title for share link dialog
  ///
  /// In en, this message translates to:
  /// **'Share Link'**
  String get shareLinkTitle;

  /// Instruction to copy link
  ///
  /// In en, this message translates to:
  /// **'Copy this link to share:'**
  String get copyLinkInstruction;

  /// Snackbar text when referral code is copied
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referralCodeCopied;

  /// Text to share with others
  ///
  /// In en, this message translates to:
  /// **'Join me on Eta Network! Use my code: {code} {link}'**
  String joinMeText(String code, String link);

  /// App title
  ///
  /// In en, this message translates to:
  /// **'ETA Network'**
  String get etaNetwork;

  /// Message when no live community coins are found
  ///
  /// In en, this message translates to:
  /// **'No live community coins'**
  String get noLiveCommunityCoins;

  /// Label for mining rate
  ///
  /// In en, this message translates to:
  /// **'RATE'**
  String get rate;

  /// Filter option for Random
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get filterRandom;

  /// Label for base rate
  ///
  /// In en, this message translates to:
  /// **'Base Rate'**
  String get baseRateLabel;

  /// Error message when mining start fails
  ///
  /// In en, this message translates to:
  /// **'Start failed: {error}'**
  String startFailed(String error);

  /// Label for session progress
  ///
  /// In en, this message translates to:
  /// **'Session Progress'**
  String get sessionProgress;

  /// Label for remaining time
  ///
  /// In en, this message translates to:
  /// **'remaining'**
  String get remainingLabel;

  /// Label for boost rate
  ///
  /// In en, this message translates to:
  /// **'Boost Rate'**
  String get boostRate;

  /// Label for mined amount
  ///
  /// In en, this message translates to:
  /// **'Mined'**
  String get minedLabel;

  /// Message when no subscription plans are available
  ///
  /// In en, this message translates to:
  /// **'No subscription plans available'**
  String get noSubscriptionPlansAvailable;

  /// Title for subscription plans dialog
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get subscriptionPlans;

  /// Label for recommended plan
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Title for editing a community coin
  ///
  /// In en, this message translates to:
  /// **'Edit Community Coin'**
  String get editCommunityCoin;

  /// Subtitle describing community coin creation
  ///
  /// In en, this message translates to:
  /// **'Launch your own coin inside ETA ecosystem for your community.'**
  String get launchCoinEcosystemDescription;

  /// Upload button label
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// Recommended image size hint
  ///
  /// In en, this message translates to:
  /// **'Recommended 200×200px'**
  String get recommendedImageSize;

  /// Label for coin name input
  ///
  /// In en, this message translates to:
  /// **'Coin name'**
  String get coinNameLabel;

  /// Label for coin symbol input
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get symbolLabel;

  /// Label for coin description input
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Label for base mining rate input
  ///
  /// In en, this message translates to:
  /// **'Base mining rate (coins/hour)'**
  String get baseMiningRateLabel;

  /// Helper text showing maximum allowed value
  ///
  /// In en, this message translates to:
  /// **'Max Allowed : {max}'**
  String maxAllowed(String max);

  /// Section title for social and project links
  ///
  /// In en, this message translates to:
  /// **'Social & project links (optional)'**
  String get socialProjectLinksOptional;

  /// Link type option: website
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get linkTypeWebsite;

  /// Link type option: YouTube
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get linkTypeYouTube;

  /// Link type option: Facebook
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get linkTypeFacebook;

  /// Link type option: Twitter
  ///
  /// In en, this message translates to:
  /// **'X / Twitter'**
  String get linkTypeTwitter;

  /// Link type option: Instagram
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get linkTypeInstagram;

  /// Link type option: Telegram
  ///
  /// In en, this message translates to:
  /// **'Telegram'**
  String get linkTypeTelegram;

  /// Link type option: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get linkTypeOther;

  /// Placeholder for link URL input
  ///
  /// In en, this message translates to:
  /// **'Paste URL'**
  String get pasteUrl;

  /// Title for important notice section
  ///
  /// In en, this message translates to:
  /// **'Important Notice'**
  String get importantNoticeTitle;

  /// Body text for important notice section
  ///
  /// In en, this message translates to:
  /// **'This coin is part of the ETA Network ecosystem and represents participation in a growing digital community. Community coins are created by users to build, experiment, and engage within the network. ETA Network is in an early stage of development. As the ecosystem grows, new utilities, features, and integrations may be introduced based on community activity, platform evolution, and applicable guidelines.'**
  String get importantNoticeBody;

  /// Label shown while submitting
  ///
  /// In en, this message translates to:
  /// **'Please wait…'**
  String get pleaseWait;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Error message when coin creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to create coin: {error}'**
  String createCoinFailed(String error);

  /// Validation error for coin name length
  ///
  /// In en, this message translates to:
  /// **'Coin name must be 3–30 characters.'**
  String get coinNameLengthError;

  /// Validation error when symbol is missing
  ///
  /// In en, this message translates to:
  /// **'Symbol is required.'**
  String get symbolRequiredError;

  /// Validation error for symbol length
  ///
  /// In en, this message translates to:
  /// **'Symbol must be 2–6 letters/numbers.'**
  String get symbolLengthError;

  /// Validation error when description exceeds max length
  ///
  /// In en, this message translates to:
  /// **'Description is too long.'**
  String get descriptionTooLongError;

  /// Validation error for base rate out of range
  ///
  /// In en, this message translates to:
  /// **'Base mining rate must be between 0.000000001 and {max}.'**
  String baseRateRangeError(String max);

  /// Validation error when coin name already exists
  ///
  /// In en, this message translates to:
  /// **'Coin name already exists. Please choose another.'**
  String get coinNameExistsError;

  /// Validation error when symbol already exists
  ///
  /// In en, this message translates to:
  /// **'Symbol already exists. Please choose another.'**
  String get symbolExistsError;

  /// Validation error when a URL is invalid
  ///
  /// In en, this message translates to:
  /// **'One of the URLs is invalid.'**
  String get urlInvalidError;

  /// Button text to subscribe and boost mining
  ///
  /// In en, this message translates to:
  /// **'Subscribe & Boost Mining'**
  String get subscribeAndBoost;

  /// Feature label for auto-collect
  ///
  /// In en, this message translates to:
  /// **'Auto-collect'**
  String get autoCollect;

  /// Feature label for auto-mining coins
  ///
  /// In en, this message translates to:
  /// **'Auto mine {count} coins'**
  String autoMineCoins(int count);

  /// Label for speed boost percentage
  ///
  /// In en, this message translates to:
  /// **'+{percent}% Speed'**
  String speedBoost(String percent);

  /// Suffix for per hour rate
  ///
  /// In en, this message translates to:
  /// **'/hr'**
  String get perHourSuffix;

  /// Suffix for ETA per hour rate
  ///
  /// In en, this message translates to:
  /// **'ETA/hr'**
  String get etaPerHourSuffix;

  /// Token name
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eta;

  /// Message when no description is available
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// Placeholder for unknown user
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownUser;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
