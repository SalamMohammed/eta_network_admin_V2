// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get totalBalance => 'Saldo Totale';

  @override
  String joinedDate(String link, Object date) {
    return 'Iscritto il $date';
  }

  @override
  String get inviteEarn => 'Invita e Guadagna';

  @override
  String get shareCodeDescription =>
      'Condividi il tuo codice unico con gli amici per aumentare la tua velocità di mining.';

  @override
  String get shareLink => 'Condividi Link';

  @override
  String get totalInvited => 'TOTALE INVITATI';

  @override
  String get activeNow => 'ATTIVI ORA';

  @override
  String get viewAll => 'Vedi Tutti';

  @override
  String get createCoin => 'Crea Moneta';

  @override
  String get mining => 'Mining';

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get languageSubtitle => 'Cambia lingua app';

  @override
  String get selectLanguage => 'Seleziona Lingua';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get home => 'Home';

  @override
  String get referral => 'Referral';

  @override
  String get profile => 'Profilo';

  @override
  String get dayStreak => 'Giorni consecutivi';

  @override
  String dayStreakValue(int count) {
    return '$count Giorni di fila';
  }

  @override
  String get active => 'Attivo';

  @override
  String get inactive => 'Inattivo';

  @override
  String get sessionEndsIn => 'La sessione termina tra';

  @override
  String get startEarning => 'Inizia a Guadagnare';

  @override
  String get loadingAd => 'Caricamento pubblicità...';

  @override
  String waitSeconds(int seconds) {
    return 'Attendi ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Ricompensa +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Pubblicità premiata non disponibile';

  @override
  String rateBoosted(String rate) {
    return 'Velocità aumentata: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Bonus pubblicità fallito: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Dettaglio velocità: Base $base, Serie +$streak, Grado +$rank, Referral +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Impossibile avviare il mining. Controlla la tua connessione internet e riprova.';

  @override
  String get createCommunityCoin => 'Crea Moneta Comunitaria';

  @override
  String get launchCoinDescription =>
      'Lancia istantaneamente la tua moneta sulla rete ETA.';

  @override
  String get createYourOwnCoin => 'Crea la tua moneta';

  @override
  String get launchCommunityCoinDescription =>
      'Lancia la tua moneta comunitaria che altri utenti ETA possono minare.';

  @override
  String get editCoin => 'Modifica moneta';

  @override
  String baseRate(String rate) {
    return 'Velocità base: $rate monete/ora';
  }

  @override
  String createdBy(String username) {
    return 'Creato da @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Nessuna moneta ancora. Aggiungi da Monete Live.';

  @override
  String get mine => 'Mina';

  @override
  String get remaining => 'rimanenti';

  @override
  String get holders => 'Detentori';

  @override
  String get close => 'Chiudi';

  @override
  String get readMore => 'Leggi di più';

  @override
  String get readLess => 'Leggi di meno';

  @override
  String get projectLinks => 'Link del Progetto';

  @override
  String get verifyEmailTitle => 'Verifica la tua Email';

  @override
  String get verifyEmailMessage =>
      'Abbiamo inviato un link di verifica al tuo indirizzo email. Verifica il tuo account per sbloccare tutte le funzionalità.';

  @override
  String get resendEmail => 'Reinvia Email';

  @override
  String get iHaveVerified => 'Ho verificato';

  @override
  String get logout => 'Disconnetti';

  @override
  String get emailVerifiedSuccess => 'Email verificata con successo!';

  @override
  String get emailNotVerified =>
      'Email non ancora verificata. Controlla la tua casella di posta.';

  @override
  String get verificationEmailSent => 'Email di verifica inviata';

  @override
  String get startMining => 'Avvia Mining';

  @override
  String get minedCoins => 'Monete Minate';

  @override
  String get liveCoins => 'Monete Live';

  @override
  String get asset => 'Asset';

  @override
  String get filterStatus => 'Stato';

  @override
  String get filterPopular => 'Popolare';

  @override
  String get filterNames => 'Nomi';

  @override
  String get filterOldNew => 'Vecchio - Nuovo';

  @override
  String get filterNewOld => 'Nuovo - Vecchio';

  @override
  String startMiningWithCount(int count) {
    return 'Avvia Mining ($count)';
  }

  @override
  String get clearSelection => 'Cancella Selezione';

  @override
  String get cancel => 'Annulla';

  @override
  String get refreshStatus => 'Aggiorna Stato';

  @override
  String get purchaseFailed => 'Acquisto fallito';

  @override
  String get securePaymentViaGooglePlay =>
      'Pagamento sicuro tramite Google Play';

  @override
  String get addedToMinedCoins => 'Aggiunto alle Monete Minate';

  @override
  String failedToAdd(String message) {
    return 'Impossibile aggiungere: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Gli abbonamenti sono disponibili solo su Android/iOS.';

  @override
  String get miningRate => 'Velocità di mining';

  @override
  String get about => 'Informazioni';

  @override
  String get yourMined => 'Tuoi Minati';

  @override
  String get totalMined => 'Totale Minati';

  @override
  String get noReferrals => 'Nessun referral ancora';

  @override
  String get linkCopied => 'Link copiato';

  @override
  String get copy => 'Copia';

  @override
  String get howItWorks => 'Come funziona';

  @override
  String get referralDescription =>
      'Condividi il tuo codice con gli amici. Quando si uniscono e diventano attivi, fai crescere il tuo team e migliori il tuo potenziale di guadagno.';

  @override
  String get yourTeam => 'Il tuo Team';

  @override
  String get referralsTitle => 'Referral';

  @override
  String get shareLinkTitle => 'Condividi Link';

  @override
  String get copyLinkInstruction => 'Copia questo link per condividere:';

  @override
  String get referralCodeCopied => 'Codice referral copiato';

  @override
  String joinMeText(String code, String link) {
    return 'Unisciti a me su Eta Network! Usa il mio codice: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Nessuna moneta comunitaria live';

  @override
  String get rate => 'VELOCITÀ';

  @override
  String get filterRandom => 'Casuale';

  @override
  String get baseRateLabel => 'Velocità Base';

  @override
  String startFailed(String error) {
    return 'Avvio fallito: $error';
  }

  @override
  String get sessionProgress => 'Progresso Sessione';

  @override
  String get remainingLabel => 'rimanenti';

  @override
  String get boostRate => 'Velocità Boost';

  @override
  String get minedLabel => 'Minato';

  @override
  String get noSubscriptionPlansAvailable =>
      'Nessun piano di abbonamento disponibile';

  @override
  String get subscriptionPlans => 'Piani di Abbonamento';

  @override
  String get recommended => 'Consigliato';

  @override
  String get editCommunityCoin => 'Modifica Moneta Comunitaria';

  @override
  String get launchCoinEcosystemDescription =>
      'Lancia la tua moneta all\'interno dell\'ecosistema ETA per la tua comunità.';

  @override
  String get upload => 'Carica';

  @override
  String get recommendedImageSize => 'Consigliato 200×200px';

  @override
  String get coinNameLabel => 'Nome moneta';

  @override
  String get symbolLabel => 'Simbolo';

  @override
  String get descriptionLabel => 'Descrizione';

  @override
  String get baseMiningRateLabel => 'Velocità di mining base (monete/ora)';

  @override
  String maxAllowed(String max) {
    return 'Massimo consentito : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Link social e progetto (opzionale)';

  @override
  String get linkTypeWebsite => 'Sito web';

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
  String get linkTypeOther => 'Altro';

  @override
  String get pasteUrl => 'Incolla URL';

  @override
  String get importantNoticeTitle => 'Avviso Importante';

  @override
  String get importantNoticeBody =>
      'Questa moneta fa parte dell\'ecosistema ETA Network e rappresenta la partecipazione a una comunità digitale in crescita. Le monete comunitarie sono create dagli utenti per costruire, sperimentare e impegnarsi all\'interno della rete. ETA Network è in una fase iniziale di sviluppo. Man mano che l\'ecosistema cresce, nuove utilità, funzionalità e integrazioni possono essere introdotte in base all\'attività della comunità, all\'evoluzione della piattaforma e alle linee guida applicabili.';

  @override
  String get pleaseWait => 'Attendi prego...';

  @override
  String get save => 'Salva';

  @override
  String createCoinFailed(String error) {
    return 'Impossibile creare la moneta: $error';
  }

  @override
  String get coinNameLengthError =>
      'Il nome della moneta deve essere di 3–30 caratteri.';

  @override
  String get symbolRequiredError => 'Il simbolo è obbligatorio.';

  @override
  String get symbolLengthError =>
      'Il simbolo deve essere di 2–6 lettere/numeri.';

  @override
  String get descriptionTooLongError => 'La descrizione è troppo lunga.';

  @override
  String baseRateRangeError(String max) {
    return 'La velocità di mining base deve essere tra 0.000000001 e $max.';
  }

  @override
  String get coinNameExistsError =>
      'Il nome della moneta esiste già. Scegline un altro.';

  @override
  String get symbolExistsError => 'Il simbolo esiste già. Scegline un altro.';

  @override
  String get urlInvalidError => 'Uno degli URL non è valido.';

  @override
  String get subscribeAndBoost => 'Abbonati e Aumenta Mining';

  @override
  String get autoCollect => 'Raccolta automatica';

  @override
  String autoMineCoins(int count) {
    return 'Mina automaticamente $count monete';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Velocità';
  }

  @override
  String get perHourSuffix => '/ora';

  @override
  String get etaPerHourSuffix => 'ETA/ora';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Nessuna descrizione disponibile.';

  @override
  String get unknownUser => 'Sconosciuto';

  @override
  String get streakLabel => 'SERIE';

  @override
  String get referralsLabel => 'REFERRAL';

  @override
  String get sessionsLabel => 'SESSIONI';

  @override
  String get accountInfoSection => 'Info Account';

  @override
  String get accountInfoTile => 'Info Account';

  @override
  String get invitedByPrompt => 'Invitato da qualcuno?';

  @override
  String get enterReferralCode => 'Inserisci codice referral';

  @override
  String get invitedStatus => 'Invitato';

  @override
  String get lockedStatus => 'Bloccato';

  @override
  String get applyButton => 'Applica';

  @override
  String get aboutPageTitle => 'Informazioni';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Contattaci';

  @override
  String get securitySettingsTile => 'Impostazioni di Sicurezza';

  @override
  String get securitySettingsPageTitle => 'Impostazioni di Sicurezza';

  @override
  String get deleteAccountTile => 'Elimina Account';

  @override
  String get deleteAccountSubtitle =>
      'Elimina permanentemente il tuo account e i dati';

  @override
  String get deleteAccountDialogTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountDialogContent =>
      'Questo eliminerà permanentemente il tuo account, i dati e le sessioni. Questa azione non può essere annullata.';

  @override
  String get deleteButton => 'Elimina';

  @override
  String get kycVerificationTile => 'Verifica KYC';

  @override
  String get kycVerificationDialogTitle => 'Verifica KYC';

  @override
  String get kycComingSoonMessage => 'Sarà attivato nelle prossime fasi.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Disconnetti';

  @override
  String get confirmDeletionTitle => 'Conferma eliminazione';

  @override
  String get enterAccountPassword => 'Inserisci password account';

  @override
  String get confirmButton => 'Conferma';

  @override
  String get usernameLabel => 'Nome utente';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Nome';

  @override
  String get ageLabel => 'Età';

  @override
  String get countryLabel => 'Paese';

  @override
  String get addressLabel => 'Indirizzo';

  @override
  String get genderLabel => 'Genere';

  @override
  String get enterUsernameHint => 'Inserisci nome utente';

  @override
  String get enterNameHint => 'Inserisci nome';

  @override
  String get enterAgeHint => 'Inserisci età';

  @override
  String get enterCountryHint => 'Inserisci paese';

  @override
  String get enterAddressHint => 'Inserisci indirizzo';

  @override
  String get enterGenderHint => 'Inserisci genere';

  @override
  String get savingLabel => 'Salvataggio...';

  @override
  String get usernameEmptyError => 'Il nome utente non può essere vuoto';

  @override
  String get invalidAgeError => 'Valore età non valido';

  @override
  String get saveError => 'Impossibile salvare le modifiche';

  @override
  String get cancelButton => 'Annulla';
}
