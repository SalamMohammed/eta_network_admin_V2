// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get totalBalance => 'Solde Total';

  @override
  String joinedDate(String link, Object date) {
    return 'Rejoint le $date';
  }

  @override
  String get inviteEarn => 'Inviter et Gagner';

  @override
  String get shareCodeDescription =>
      'Partagez votre code unique avec des amis pour augmenter votre taux de minage.';

  @override
  String get shareLink => 'Partager le lien';

  @override
  String get totalInvited => 'TOTAL INVITÉS';

  @override
  String get activeNow => 'ACTIF MAINTENANT';

  @override
  String get viewAll => 'Voir tout';

  @override
  String get createCoin => 'Créer une pièce';

  @override
  String get mining => 'Minage';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get languageSubtitle => 'Changer la langue de l\'application';

  @override
  String get selectLanguage => 'Choisir la langue';

  @override
  String get balanceTitle => 'Solde';

  @override
  String get home => 'Accueil';

  @override
  String get referral => 'Parrainage';

  @override
  String get profile => 'Profil';

  @override
  String get dayStreak => 'Série de jours';

  @override
  String dayStreakValue(int count) {
    return 'Série de $count jours';
  }

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get sessionEndsIn => 'La session se termine dans';

  @override
  String get startEarning => 'Commencer à gagner';

  @override
  String get loadingAd => 'Chargement de la publicité...';

  @override
  String waitSeconds(int seconds) {
    return 'Attendez ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Récompense +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Publicité récompensée non disponible';

  @override
  String rateBoosted(String rate) {
    return 'Taux boosté : +$rate ETA/h';
  }

  @override
  String adBonusFailed(String message) {
    return 'Bonus publicitaire échoué : $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Détail du taux : Base $base, Série +$streak, Rang +$rank, Parrainages +$referrals = $total ETA/h';
  }

  @override
  String get unableToStartMining =>
      'Impossible de démarrer le minage. Veuillez vérifier votre connexion internet et réessayer.';

  @override
  String get createCommunityCoin => 'Créer une pièce communautaire';

  @override
  String get launchCoinDescription =>
      'Lancez votre propre pièce sur le réseau ETA instantanément.';

  @override
  String get createYourOwnCoin => 'Créez votre propre pièce';

  @override
  String get launchCommunityCoinDescription =>
      'Lancez votre propre pièce communautaire que d\'autres utilisateurs ETA peuvent miner.';

  @override
  String get editCoin => 'Modifier la pièce';

  @override
  String baseRate(String rate) {
    return 'Taux de base : $rate pièces/h';
  }

  @override
  String createdBy(String username) {
    return 'Créé par @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/h';
  }

  @override
  String get noCoinsYet =>
      'Pas encore de pièces. Ajoutez-en depuis les pièces en direct.';

  @override
  String get mine => 'Miner';

  @override
  String get remaining => 'restant';

  @override
  String get holders => 'Détenteurs';

  @override
  String get close => 'Fermer';

  @override
  String get readMore => 'Lire plus';

  @override
  String get readLess => 'Lire moins';

  @override
  String get projectLinks => 'Liens du projet';

  @override
  String get verifyEmailTitle => 'Vérifiez votre e-mail';

  @override
  String get verifyEmailMessage =>
      'Nous avons envoyé un lien de vérification à votre adresse e-mail. Veuillez vérifier votre compte pour débloquer toutes les fonctionnalités.';

  @override
  String get resendEmail => 'Renvoyer l\'e-mail';

  @override
  String get iHaveVerified => 'J\'ai vérifié';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get emailVerifiedSuccess => 'E-mail vérifié avec succès !';

  @override
  String get emailNotVerified =>
      'E-mail non encore vérifié. Veuillez vérifier votre boîte de réception.';

  @override
  String get verificationEmailSent => 'E-mail de vérification envoyé';

  @override
  String get startMining => 'Démarrer le minage';

  @override
  String get minedCoins => 'Pièces minées';

  @override
  String get liveCoins => 'Pièces en direct';

  @override
  String get asset => 'Actif';

  @override
  String get filterStatus => 'Statut';

  @override
  String get filterPopular => 'Populaire';

  @override
  String get filterNames => 'Noms';

  @override
  String get filterOldNew => 'Ancien - Nouveau';

  @override
  String get filterNewOld => 'Nouveau - Ancien';

  @override
  String startMiningWithCount(int count) {
    return 'Démarrer le minage ($count)';
  }

  @override
  String get clearSelection => 'Effacer la sélection';

  @override
  String get cancel => 'Annuler';

  @override
  String get refreshStatus => 'Actualiser le statut';

  @override
  String get purchaseFailed => 'Échec de l\'achat';

  @override
  String get securePaymentViaGooglePlay => 'Paiement sécurisé via Google Play';

  @override
  String get addedToMinedCoins => 'Ajouté aux pièces minées';

  @override
  String failedToAdd(String message) {
    return 'Échec de l\'ajout : $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Les abonnements ne sont disponibles que sur Android/iOS.';

  @override
  String get miningRate => 'Taux de minage';

  @override
  String get about => 'À propos';

  @override
  String get yourMined => 'Votre minage';

  @override
  String get totalMined => 'Total miné';

  @override
  String get noReferrals => 'Pas encore de parrainages';

  @override
  String get linkCopied => 'Lien copié';

  @override
  String get copy => 'Copier';

  @override
  String get howItWorks => 'Comment ça marche';

  @override
  String get referralDescription =>
      'Partagez votre code avec des amis. Lorsqu\'ils rejoignent et deviennent actifs, votre équipe s\'agrandit et votre potentiel de gain s\'améliore.';

  @override
  String get yourTeam => 'Votre équipe';

  @override
  String get referralsTitle => 'Parrainages';

  @override
  String get shareLinkTitle => 'Partager le lien';

  @override
  String get copyLinkInstruction => 'Copiez ce lien pour partager :';

  @override
  String get referralCodeCopied => 'Code de parrainage copié';

  @override
  String joinMeText(String code, String link) {
    return 'Rejoignez-moi sur le réseau Eta ! Utilisez mon code : $code $link';
  }

  @override
  String get etaNetwork => 'Réseau ETA';

  @override
  String get noLiveCommunityCoins => 'Aucune pièce communautaire en direct';

  @override
  String get rate => 'TAUX';

  @override
  String get filterRandom => 'Aléatoire';

  @override
  String get baseRateLabel => 'Taux de base';

  @override
  String startFailed(String error) {
    return 'Échec du démarrage : $error';
  }

  @override
  String get sessionProgress => 'Progression de la session';

  @override
  String get remainingLabel => 'restant';

  @override
  String get boostRate => 'Taux de boost';

  @override
  String get minedLabel => 'Miné';

  @override
  String get noSubscriptionPlansAvailable =>
      'Aucun plan d\'abonnement disponible';

  @override
  String get subscriptionPlans => 'Plans d\'abonnement';

  @override
  String get recommended => 'Recommandé';

  @override
  String get editCommunityCoin => 'Modifier la pièce communautaire';

  @override
  String get launchCoinEcosystemDescription =>
      'Lancez votre propre pièce au sein de l\'écosystème ETA pour votre communauté.';

  @override
  String get upload => 'Télécharger';

  @override
  String get recommendedImageSize => 'Recommandé 200x200px';

  @override
  String get coinNameLabel => 'Nom de la pièce';

  @override
  String get symbolLabel => 'Symbole';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get baseMiningRateLabel => 'Taux de minage de base (pièces/h)';

  @override
  String maxAllowed(String max) {
    return 'Maximum autorisé : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Liens sociaux et du projet (facultatif)';

  @override
  String get linkTypeWebsite => 'Site Web';

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
  String get linkTypeOther => 'Autre';

  @override
  String get pasteUrl => 'Coller l\'URL';

  @override
  String get importantNoticeTitle => 'Avis important';

  @override
  String get importantNoticeBody =>
      'Cette pièce fait partie de l\'écosystème ETA Network et représente la participation à une communauté numérique en pleine croissance. Les pièces communautaires sont créées par les utilisateurs pour construire, expérimenter et s\'engager au sein du réseau. Le réseau ETA en est aux premiers stades de développement. À mesure que l\'écosystème se développe, de nouveaux utilitaires, fonctionnalités et intégrations peuvent être introduits en fonction de l\'activité de la communauté, de l\'évolution de la plateforme et des directives applicables.';

  @override
  String get pleaseWait => 'Veuillez patienter...';

  @override
  String get save => 'Enregistrer';

  @override
  String createCoinFailed(String error) {
    return 'Échec de la création de la pièce : $error';
  }

  @override
  String get coinNameLengthError =>
      'Le nom de la pièce doit comporter entre 3 et 30 caractères.';

  @override
  String get symbolRequiredError => 'Le symbole est requis.';

  @override
  String get symbolLengthError =>
      'Le symbole doit comporter entre 2 et 6 lettres/chiffres.';

  @override
  String get descriptionTooLongError => 'La description est trop longue.';

  @override
  String baseRateRangeError(String max) {
    return 'Le taux de minage de base doit être compris entre 0,000000001 et $max.';
  }

  @override
  String get coinNameExistsError =>
      'Le nom de la pièce existe déjà. Veuillez en choisir un autre.';

  @override
  String get symbolExistsError =>
      'Le symbole existe déjà. Veuillez en choisir un autre.';

  @override
  String get urlInvalidError => 'L\'une des URL n\'est pas valide.';

  @override
  String get subscribeAndBoost => 'S\'abonner et booster le minage';

  @override
  String get autoCollect => 'Collecte automatique';

  @override
  String autoMineCoins(int count) {
    return 'Miner automatiquement $count pièces';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Vitesse';
  }

  @override
  String get perHourSuffix => '/h';

  @override
  String get etaPerHourSuffix => 'ETA/h';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Aucune description disponible.';

  @override
  String get unknownUser => 'Inconnu';

  @override
  String get streakLabel => 'SÉRIE';

  @override
  String get referralsLabel => 'PARRAINAGES';

  @override
  String get sessionsLabel => 'SESSIONS';

  @override
  String get accountInfoSection => 'Infos du compte';

  @override
  String get accountInfoTile => 'Infos du compte';

  @override
  String get invitedByPrompt => 'Invité par quelqu\'un ?';

  @override
  String get enterReferralCode => 'Entrez le code de parrainage';

  @override
  String get invitedStatus => 'Invité';

  @override
  String get lockedStatus => 'Verrouillé';

  @override
  String get applyButton => 'Appliquer';

  @override
  String get aboutPageTitle => 'À propos';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'Livre blanc';

  @override
  String get contactUsTile => 'Contactez-nous';

  @override
  String get securitySettingsTile => 'Paramètres de sécurité';

  @override
  String get securitySettingsPageTitle => 'Paramètres de sécurité';

  @override
  String get deleteAccountTile => 'Supprimer le compte';

  @override
  String get deleteAccountSubtitle =>
      'Supprimer définitivement votre compte et vos données';

  @override
  String get deleteAccountDialogTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountDialogContent =>
      'Cela supprimera définitivement votre compte, vos données et vos sessions. Cette action ne peut pas être annulée.';

  @override
  String get deleteButton => 'Supprimer';

  @override
  String get kycVerificationTile => 'Vérification KYC';

  @override
  String get kycVerificationDialogTitle => 'Vérification KYC';

  @override
  String get kycComingSoonMessage => 'Sera activé dans les prochaines étapes.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Se déconnecter';

  @override
  String get confirmDeletionTitle => 'Confirmer la suppression';

  @override
  String get enterAccountPassword => 'Entrez le mot de passe du compte';

  @override
  String get confirmButton => 'Confirmer';

  @override
  String get usernameLabel => 'Nom d\'utilisateur';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get nameLabel => 'Nom';

  @override
  String get ageLabel => 'Âge';

  @override
  String get countryLabel => 'Pays';

  @override
  String get addressLabel => 'Adresse';

  @override
  String get genderLabel => 'Genre';

  @override
  String get enterUsernameHint => 'Entrez le nom d\'utilisateur';

  @override
  String get enterNameHint => 'Entrez le nom';

  @override
  String get enterAgeHint => 'Entrez l\'âge';

  @override
  String get enterCountryHint => 'Entrez le pays';

  @override
  String get enterAddressHint => 'Entrez l\'adresse';

  @override
  String get enterGenderHint => 'Entrez le genre';

  @override
  String get savingLabel => 'Enregistrement...';

  @override
  String get usernameEmptyError =>
      'Le nom d\'utilisateur ne peut pas être vide';

  @override
  String get invalidAgeError => 'Valeur d\'âge invalide';

  @override
  String get saveError => 'Échec de l\'enregistrement des modifications';

  @override
  String get cancelButton => 'Annuler';
}
