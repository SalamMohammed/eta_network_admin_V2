// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get totalBalance => 'Gesamtguthaben';

  @override
  String joinedDate(String link, Object date) {
    return 'Beigetreten am $date';
  }

  @override
  String get inviteEarn => 'Einladen & Verdienen';

  @override
  String get shareCodeDescription =>
      'Teilen Sie Ihren einzigartigen Code mit Freunden, um Ihre Mining-Rate zu erhöhen.';

  @override
  String get shareLink => 'Link teilen';

  @override
  String get totalInvited => 'GESAMT EINGELADEN';

  @override
  String get activeNow => 'JETZT AKTIV';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get createCoin => 'Coin erstellen';

  @override
  String get mining => 'Mining';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get languageSubtitle => 'App-Sprache ändern';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get balanceTitle => 'Guthaben';

  @override
  String get home => 'Startseite';

  @override
  String get referral => 'Empfehlung';

  @override
  String get profile => 'Profil';

  @override
  String get dayStreak => 'Tage in Folge';

  @override
  String dayStreakValue(int count) {
    return '$count Tage in Folge';
  }

  @override
  String get active => 'Aktiv';

  @override
  String get inactive => 'Inaktiv';

  @override
  String get sessionEndsIn => 'Sitzung endet in';

  @override
  String get startEarning => 'Verdienen starten';

  @override
  String get loadingAd => 'Werbung wird geladen...';

  @override
  String waitSeconds(int seconds) {
    return 'Warten Sie ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Belohnung +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Belohnte Werbung nicht verfügbar';

  @override
  String rateBoosted(String rate) {
    return 'Rate erhöht: +$rate ETA/Std';
  }

  @override
  String adBonusFailed(String message) {
    return 'Werbebonus fehlgeschlagen: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Ratenaufschlüsselung: Basis $base, Serie +$streak, Rang +$rank, Empfehlungen +$referrals = $total ETA/Std';
  }

  @override
  String get unableToStartMining =>
      'Mining kann nicht gestartet werden. Bitte überprüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get createCommunityCoin => 'Community-Coin erstellen';

  @override
  String get launchCoinDescription =>
      'Starten Sie Ihren eigenen Coin im ETA-Netzwerk sofort.';

  @override
  String get createYourOwnCoin => 'Erstellen Sie Ihren eigenen Coin';

  @override
  String get launchCommunityCoinDescription =>
      'Starten Sie Ihren eigenen Community-Coin, den andere ETA-Benutzer minen können.';

  @override
  String get editCoin => 'Coin bearbeiten';

  @override
  String baseRate(String rate) {
    return 'Basisrate: $rate Coins/Std';
  }

  @override
  String createdBy(String username) {
    return 'Erstellt von @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/Std';
  }

  @override
  String get noCoinsYet =>
      'Noch keine Coins. Fügen Sie welche von Live-Coins hinzu.';

  @override
  String get mine => 'Minen';

  @override
  String get remaining => 'verbleibend';

  @override
  String get holders => 'Inhaber';

  @override
  String get close => 'Schließen';

  @override
  String get readMore => 'Mehr lesen';

  @override
  String get readLess => 'Weniger lesen';

  @override
  String get projectLinks => 'Projektlinks';

  @override
  String get verifyEmailTitle => 'Bestätigen Sie Ihre E-Mail';

  @override
  String get verifyEmailMessage =>
      'Wir haben einen Bestätigungslink an Ihre E-Mail-Adresse gesendet. Bitte bestätigen Sie Ihr Konto, um alle Funktionen freizuschalten.';

  @override
  String get resendEmail => 'E-Mail erneut senden';

  @override
  String get iHaveVerified => 'Ich habe bestätigt';

  @override
  String get logout => 'Abmelden';

  @override
  String get emailVerifiedSuccess => 'E-Mail erfolgreich bestätigt!';

  @override
  String get emailNotVerified =>
      'E-Mail noch nicht bestätigt. Bitte überprüfen Sie Ihren Posteingang.';

  @override
  String get verificationEmailSent => 'Bestätigungs-E-Mail gesendet';

  @override
  String get startMining => 'Mining starten';

  @override
  String get minedCoins => 'Geminte Coins';

  @override
  String get liveCoins => 'Live-Coins';

  @override
  String get asset => 'Vermögenswert';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Beliebt';

  @override
  String get filterNames => 'Namen';

  @override
  String get filterOldNew => 'Alt - Neu';

  @override
  String get filterNewOld => 'Neu - Alt';

  @override
  String startMiningWithCount(int count) {
    return 'Mining starten ($count)';
  }

  @override
  String get clearSelection => 'Auswahl löschen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get refreshStatus => 'Status aktualisieren';

  @override
  String get purchaseFailed => 'Kauf fehlgeschlagen';

  @override
  String get securePaymentViaGooglePlay => 'Sichere Zahlung über Google Play';

  @override
  String get addedToMinedCoins => 'Zu geminten Coins hinzugefügt';

  @override
  String failedToAdd(String message) {
    return 'Hinzufügen fehlgeschlagen: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Abonnements nur auf Android/iOS verfügbar.';

  @override
  String get miningRate => 'Mining-Rate';

  @override
  String get about => 'Über';

  @override
  String get yourMined => 'Ihr Mining';

  @override
  String get totalMined => 'Gesamt gemint';

  @override
  String get noReferrals => 'Noch keine Empfehlungen';

  @override
  String get linkCopied => 'Link kopiert';

  @override
  String get copy => 'Kopieren';

  @override
  String get howItWorks => 'Wie es funktioniert';

  @override
  String get referralDescription =>
      'Teilen Sie Ihren Code mit Freunden. Wenn sie beitreten und aktiv werden, wächst Ihr Team und Ihr Verdienstpotenzial verbessert sich.';

  @override
  String get yourTeam => 'Ihr Team';

  @override
  String get referralsTitle => 'Empfehlungen';

  @override
  String get shareLinkTitle => 'Link teilen';

  @override
  String get copyLinkInstruction => 'Kopieren Sie diesen Link zum Teilen:';

  @override
  String get referralCodeCopied => 'Empfehlungscode kopiert';

  @override
  String joinMeText(String code, String link) {
    return 'Komm zu mir ins Eta Network! Benutze meinen Code: $code $link';
  }

  @override
  String get etaNetwork => 'ETA-Netzwerk';

  @override
  String get noLiveCommunityCoins => 'Keine Live-Community-Coins';

  @override
  String get rate => 'RATE';

  @override
  String get filterRandom => 'Zufällig';

  @override
  String get baseRateLabel => 'Basisrate';

  @override
  String startFailed(String error) {
    return 'Start fehlgeschlagen: $error';
  }

  @override
  String get sessionProgress => 'Sitzungsfortschritt';

  @override
  String get remainingLabel => 'verbleibend';

  @override
  String get boostRate => 'Boost-Rate';

  @override
  String get minedLabel => 'Gemint';

  @override
  String get noSubscriptionPlansAvailable => 'Keine Abonnementspläne verfügbar';

  @override
  String get subscriptionPlans => 'Abonnementpläne';

  @override
  String get recommended => 'Empfohlen';

  @override
  String get editCommunityCoin => 'Community-Coin bearbeiten';

  @override
  String get launchCoinEcosystemDescription =>
      'Starten Sie Ihren eigenen Coin im ETA-Ökosystem für Ihre Community.';

  @override
  String get upload => 'Hochladen';

  @override
  String get recommendedImageSize => 'Empfohlen 200x200px';

  @override
  String get coinNameLabel => 'Coin-Name';

  @override
  String get symbolLabel => 'Symbol';

  @override
  String get descriptionLabel => 'Beschreibung';

  @override
  String get baseMiningRateLabel => 'Basis-Mining-Rate (Coins/Std)';

  @override
  String maxAllowed(String max) {
    return 'Maximal erlaubt : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Soziale & Projektlinks (optional)';

  @override
  String get linkTypeWebsite => 'Webseite';

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
  String get linkTypeOther => 'Andere';

  @override
  String get pasteUrl => 'URL einfügen';

  @override
  String get importantNoticeTitle => 'Wichtiger Hinweis';

  @override
  String get importantNoticeBody =>
      'Dieser Coin ist Teil des ETA Network-Ökosystems und repräsentiert die Teilnahme an einer wachsenden digitalen Community. Community-Coins werden von Benutzern erstellt, um im Netzwerk aufzubauen, zu experimentieren und sich zu engagieren. Das ETA-Netzwerk befindet sich in einem frühen Entwicklungsstadium. Wenn das Ökosystem wächst, können neue Dienstprogramme, Funktionen und Integrationen basierend auf Community-Aktivitäten, Plattformentwicklung und geltenden Richtlinien eingeführt werden.';

  @override
  String get pleaseWait => 'Bitte warten...';

  @override
  String get save => 'Speichern';

  @override
  String createCoinFailed(String error) {
    return 'Coin-Erstellung fehlgeschlagen: $error';
  }

  @override
  String get coinNameLengthError => 'Coin-Name muss 3-30 Zeichen lang sein.';

  @override
  String get symbolRequiredError => 'Symbol ist erforderlich.';

  @override
  String get symbolLengthError => 'Symbol muss 2-6 Buchstaben/Zahlen sein.';

  @override
  String get descriptionTooLongError => 'Beschreibung ist zu lang.';

  @override
  String baseRateRangeError(String max) {
    return 'Basis-Mining-Rate muss zwischen 0,000000001 und $max liegen.';
  }

  @override
  String get coinNameExistsError =>
      'Coin-Name existiert bereits. Bitte wählen Sie einen anderen.';

  @override
  String get symbolExistsError =>
      'Symbol existiert bereits. Bitte wählen Sie ein anderes.';

  @override
  String get urlInvalidError => 'Eine der URLs ist ungültig.';

  @override
  String get subscribeAndBoost => 'Abonnieren & Mining boosten';

  @override
  String get autoCollect => 'Automatisch sammeln';

  @override
  String autoMineCoins(int count) {
    return '$count Coins automatisch minen';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Geschwindigkeit';
  }

  @override
  String get perHourSuffix => '/Std';

  @override
  String get etaPerHourSuffix => 'ETA/Std';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Keine Beschreibung verfügbar.';

  @override
  String get unknownUser => 'Unbekannt';

  @override
  String get streakLabel => 'SERIE';

  @override
  String get referralsLabel => 'EMPFEHLUNGEN';

  @override
  String get sessionsLabel => 'SITZUNGEN';

  @override
  String get accountInfoSection => 'Kontoinformationen';

  @override
  String get accountInfoTile => 'Kontoinformationen';

  @override
  String get invitedByPrompt => 'Von jemandem eingeladen?';

  @override
  String get enterReferralCode => 'Empfehlungscode eingeben';

  @override
  String get invitedStatus => 'Eingeladen';

  @override
  String get lockedStatus => 'Gesperrt';

  @override
  String get applyButton => 'Anwenden';

  @override
  String get aboutPageTitle => 'Über';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'Weißbuch';

  @override
  String get contactUsTile => 'Kontaktieren Sie uns';

  @override
  String get securitySettingsTile => 'Sicherheitseinstellungen';

  @override
  String get securitySettingsPageTitle => 'Sicherheitseinstellungen';

  @override
  String get deleteAccountTile => 'Konto löschen';

  @override
  String get deleteAccountSubtitle => 'Konto und Daten dauerhaft löschen';

  @override
  String get deleteAccountDialogTitle => 'Konto löschen?';

  @override
  String get deleteAccountDialogContent =>
      'Dies wird Ihr Konto, Ihre Daten und Sitzungen dauerhaft löschen. Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get kycVerificationTile => 'KYC-Verifizierung';

  @override
  String get kycVerificationDialogTitle => 'KYC-Verifizierung';

  @override
  String get kycComingSoonMessage => 'Wird in den kommenden Phasen aktiviert.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Abmelden';

  @override
  String get confirmDeletionTitle => 'Löschen bestätigen';

  @override
  String get enterAccountPassword => 'Kontopasswort eingeben';

  @override
  String get confirmButton => 'Bestätigen';

  @override
  String get usernameLabel => 'Benutzername';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get nameLabel => 'Name';

  @override
  String get ageLabel => 'Alter';

  @override
  String get countryLabel => 'Land';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get genderLabel => 'Geschlecht';

  @override
  String get enterUsernameHint => 'Benutzername eingeben';

  @override
  String get enterNameHint => 'Name eingeben';

  @override
  String get enterAgeHint => 'Alter eingeben';

  @override
  String get enterCountryHint => 'Land eingeben';

  @override
  String get enterAddressHint => 'Adresse eingeben';

  @override
  String get enterGenderHint => 'Geschlecht eingeben';

  @override
  String get savingLabel => 'Speichern...';

  @override
  String get usernameEmptyError => 'Benutzername darf nicht leer sein';

  @override
  String get invalidAgeError => 'Ungültiger Alterswert';

  @override
  String get saveError => 'Änderungen konnten nicht gespeichert werden';

  @override
  String get cancelButton => 'Abbrechen';
}
