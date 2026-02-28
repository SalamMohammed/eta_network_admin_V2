// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get totalBalance => 'Saldo Total';

  @override
  String joinedDate(String link, Object date) {
    return 'Se unió el $date';
  }

  @override
  String get inviteEarn => 'Invita y Gana';

  @override
  String get shareCodeDescription =>
      'Comparte tu código único con amigos para aumentar tu tasa de minería.';

  @override
  String get shareLink => 'Compartir Enlace';

  @override
  String get totalInvited => 'TOTAL INVITADOS';

  @override
  String get activeNow => 'ACTIVOS AHORA';

  @override
  String get viewAll => 'Ver Todo';

  @override
  String get createCoin => 'Crear Moneda';

  @override
  String get mining => 'Minería';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Cambiar idioma de la aplicación';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get home => 'Inicio';

  @override
  String get referral => 'Referidos';

  @override
  String get profile => 'Perfil';

  @override
  String get dayStreak => 'Racha';

  @override
  String dayStreakValue(int count) {
    return 'Racha de $count días';
  }

  @override
  String get active => 'Activo';

  @override
  String get inactive => 'Inactivo';

  @override
  String get sessionEndsIn => 'La sesión termina en';

  @override
  String get startEarning => 'Empezar a Ganar';

  @override
  String get loadingAd => 'Cargando anuncio…';

  @override
  String waitSeconds(int seconds) {
    return 'Espera ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Recompensa +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Anuncio recompensado no disponible';

  @override
  String rateBoosted(String rate) {
    return 'Tasa aumentada: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Fallo al aplicar el bono del anuncio: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Desglose de tasa: Base $base, Racha +$streak, Rango +$rank, Referidos +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'No se pudo iniciar la minería. Comprueba tu conexión a internet e inténtalo de nuevo.';

  @override
  String get createCommunityCoin => 'Crear Moneda Comunitaria';

  @override
  String get launchCoinDescription =>
      'Lanza tu propia moneda en ETA Network al instante.';

  @override
  String get createYourOwnCoin => 'Crea tu propia moneda';

  @override
  String get launchCommunityCoinDescription =>
      'Lanza tu propia moneda comunitaria que otros usuarios de ETA pueden minar.';

  @override
  String get editCoin => 'Editar moneda';

  @override
  String baseRate(String rate) {
    return 'Tasa base: $rate monedas/hora';
  }

  @override
  String createdBy(String username) {
    return 'Creado por @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Aún no hay monedas. Añade desde Monedas en Vivo.';

  @override
  String get mine => 'Minar';

  @override
  String get remaining => 'restante';

  @override
  String get holders => 'Titulares';

  @override
  String get close => 'Cerrar';

  @override
  String get readMore => 'Leer Más';

  @override
  String get readLess => 'Leer Menos';

  @override
  String get projectLinks => 'Enlaces del Proyecto';

  @override
  String get verifyEmailTitle => 'Verifica tu Correo';

  @override
  String get verifyEmailMessage =>
      'Hemos enviado un enlace de verificación a tu correo electrónico. Por favor verifica tu cuenta para desbloquear todas las funciones.';

  @override
  String get resendEmail => 'Reenviar Correo';

  @override
  String get iHaveVerified => 'Ya he verificado';

  @override
  String get logout => 'Cerrar Sesión';

  @override
  String get emailVerifiedSuccess => '¡Correo verificado exitosamente!';

  @override
  String get emailNotVerified =>
      'Correo no verificado aún. Por favor revisa tu bandeja de entrada.';

  @override
  String get verificationEmailSent => 'Correo de verificación enviado';

  @override
  String get startMining => 'Iniciar Minería';

  @override
  String get minedCoins => 'Monedas Minadas';

  @override
  String get liveCoins => 'Monedas en Vivo';

  @override
  String get asset => 'Activo';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterNames => 'Nombres';

  @override
  String get filterOldNew => 'Antiguo - Nuevo';

  @override
  String get filterNewOld => 'Nuevo - Antiguo';

  @override
  String startMiningWithCount(int count) {
    return 'Iniciar Minería ($count)';
  }

  @override
  String get clearSelection => 'Borrar selección';

  @override
  String get cancel => 'Cancelar';

  @override
  String get refreshStatus => 'Actualizar estado';

  @override
  String get purchaseFailed => 'Fallo en la compra';

  @override
  String get securePaymentViaGooglePlay => 'Pago seguro mediante Google Play';

  @override
  String get addedToMinedCoins => 'Añadido a Monedas Minadas';

  @override
  String failedToAdd(String message) {
    return 'No se pudo añadir: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Las suscripciones solo están disponibles en Android/iOS.';

  @override
  String get miningRate => 'Tasa de minería';

  @override
  String get about => 'Acerca de';

  @override
  String get yourMined => 'Tus minados';

  @override
  String get totalMined => 'Total Minado';

  @override
  String get noReferrals => 'Aún no hay referidos';

  @override
  String get linkCopied => 'Enlace copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get howItWorks => 'Cómo funciona';

  @override
  String get referralDescription =>
      'Comparte tu código con amigos. Cuando se unan y estén activos, crecerá tu equipo y mejorará tu potencial de ganancias.';

  @override
  String get yourTeam => 'Tu equipo';

  @override
  String get referralsTitle => 'Referidos';

  @override
  String get shareLinkTitle => 'Compartir enlace';

  @override
  String get copyLinkInstruction => 'Copia este enlace para compartir:';

  @override
  String get referralCodeCopied => 'Código de referencia copiado';

  @override
  String joinMeText(String code, String link) {
    return '¡Únete a mí en Eta Network! Usa mi código: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'No hay monedas comunitarias en vivo';

  @override
  String get rate => 'TASA';

  @override
  String get filterRandom => 'Aleatorio';

  @override
  String get baseRateLabel => 'Tasa Base';

  @override
  String startFailed(String error) {
    return 'Inicio fallido: $error';
  }

  @override
  String get sessionProgress => 'Progreso de Sesión';

  @override
  String get remainingLabel => 'restante';

  @override
  String get boostRate => 'Tasa de Impulso';

  @override
  String get minedLabel => 'Minado';

  @override
  String get noSubscriptionPlansAvailable =>
      'No hay planes de suscripción disponibles';

  @override
  String get subscriptionPlans => 'Planes de Suscripción';

  @override
  String get recommended => 'Recomendado';

  @override
  String get editCommunityCoin => 'Editar Moneda Comunitaria';

  @override
  String get launchCoinEcosystemDescription =>
      'Lanza tu propia moneda dentro del ecosistema ETA para tu comunidad.';

  @override
  String get upload => 'Subir';

  @override
  String get recommendedImageSize => 'Recomendado 200×200px';

  @override
  String get coinNameLabel => 'Nombre de la moneda';

  @override
  String get symbolLabel => 'Símbolo';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get baseMiningRateLabel => 'Tasa base de minería (monedas/hora)';

  @override
  String maxAllowed(String max) {
    return 'Máximo permitido : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Enlaces sociales y del proyecto (opcional)';

  @override
  String get linkTypeWebsite => 'Sitio web';

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
  String get linkTypeOther => 'Otro';

  @override
  String get pasteUrl => 'Pegar URL';

  @override
  String get importantNoticeTitle => 'Aviso Importante';

  @override
  String get importantNoticeBody =>
      'Esta moneda es parte del ecosistema ETA Network y representa la participación en una comunidad digital en crecimiento. Las monedas comunitarias son creadas por usuarios para construir, experimentar y participar dentro de la red. ETA Network está en una etapa temprana de desarrollo. A medida que el ecosistema crece, pueden introducirse nuevas utilidades, funciones e integraciones según la actividad de la comunidad, la evolución de la plataforma y las pautas aplicables.';

  @override
  String get pleaseWait => 'Por favor espera…';

  @override
  String get save => 'Guardar';

  @override
  String createCoinFailed(String error) {
    return 'Error al crear moneda: $error';
  }

  @override
  String get coinNameLengthError =>
      'El nombre de la moneda debe tener entre 3 y 30 caracteres.';

  @override
  String get symbolRequiredError => 'El símbolo es obligatorio.';

  @override
  String get symbolLengthError =>
      'El símbolo debe tener entre 2 y 6 letras/números.';

  @override
  String get descriptionTooLongError => 'La descripción es demasiado larga.';

  @override
  String baseRateRangeError(String max) {
    return 'La tasa base de minería debe estar entre 0.000000001 y $max.';
  }

  @override
  String get coinNameExistsError =>
      'El nombre de la moneda ya existe. Por favor elige otro.';

  @override
  String get symbolExistsError => 'El símbolo ya existe. Por favor elige otro.';

  @override
  String get urlInvalidError => 'Una de las URL no es válida.';

  @override
  String get subscribeAndBoost => 'Suscríbete y Aumenta Minería';

  @override
  String get autoCollect => 'Recolección automática';

  @override
  String autoMineCoins(int count) {
    return 'Minar auto $count monedas';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Velocidad';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'No hay descripción disponible.';

  @override
  String get unknownUser => 'Desconocido';

  @override
  String get streakLabel => 'RACHA';

  @override
  String get referralsLabel => 'REFERIDOS';

  @override
  String get sessionsLabel => 'SESIONES';

  @override
  String get accountInfoSection => 'Información de la Cuenta';

  @override
  String get accountInfoTile => 'Información de la Cuenta';

  @override
  String get invitedByPrompt => '¿Invitado por alguien?';

  @override
  String get enterReferralCode => 'Ingresa código de referido';

  @override
  String get invitedStatus => 'Invitado';

  @override
  String get lockedStatus => 'Bloqueado';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get aboutPageTitle => 'Acerca de';

  @override
  String get faqTile => 'Preguntas Frecuentes';

  @override
  String get whitePaperTile => 'Libro Blanco';

  @override
  String get contactUsTile => 'Contáctanos';

  @override
  String get securitySettingsTile => 'Configuración de Seguridad';

  @override
  String get securitySettingsPageTitle => 'Configuración de Seguridad';

  @override
  String get deleteAccountTile => 'Eliminar Cuenta';

  @override
  String get deleteAccountSubtitle =>
      'Eliminar permanentemente tu cuenta y datos';

  @override
  String get deleteAccountDialogTitle => '¿Eliminar cuenta?';

  @override
  String get deleteAccountDialogContent =>
      'Esto eliminará permanentemente tu cuenta, datos y sesiones. Esta acción no se puede deshacer.';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get kycVerificationTile => 'Verificación KYC';

  @override
  String get kycVerificationDialogTitle => 'Verificación KYC';

  @override
  String get kycComingSoonMessage => 'Se activará en las próximas etapas.';

  @override
  String get okButton => 'Aceptar';

  @override
  String get logOutLabel => 'Cerrar Sesión';

  @override
  String get confirmDeletionTitle => 'Confirmar eliminación';

  @override
  String get enterAccountPassword => 'Ingresa la contraseña de la cuenta';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get usernameLabel => 'Nombre de usuario';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get ageLabel => 'Edad';

  @override
  String get countryLabel => 'País';

  @override
  String get addressLabel => 'Dirección';

  @override
  String get genderLabel => 'Género';

  @override
  String get enterUsernameHint => 'Ingresa nombre de usuario';

  @override
  String get enterNameHint => 'Ingresa nombre';

  @override
  String get enterAgeHint => 'Ingresa edad';

  @override
  String get enterCountryHint => 'Ingresa país';

  @override
  String get enterAddressHint => 'Ingresa dirección';

  @override
  String get enterGenderHint => 'Ingresa género';

  @override
  String get savingLabel => 'Guardando...';

  @override
  String get usernameEmptyError => 'El nombre de usuario no puede estar vacío';

  @override
  String get invalidAgeError => 'Valor de edad inválido';

  @override
  String get saveError => 'Fallo al guardar los cambios';

  @override
  String get cancelButton => 'Cancelar';
}
