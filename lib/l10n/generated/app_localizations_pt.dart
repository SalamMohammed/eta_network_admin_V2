// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get totalBalance => 'Saldo Total';

  @override
  String joinedDate(String link, Object date) {
    return 'Entrou em $date';
  }

  @override
  String get inviteEarn => 'Convidar e Ganhar';

  @override
  String get shareCodeDescription =>
      'Compartilhe seu código único com amigos para aumentar sua taxa de mineração.';

  @override
  String get shareLink => 'Compartilhar Link';

  @override
  String get totalInvited => 'TOTAL CONVIDADO';

  @override
  String get activeNow => 'ATIVO AGORA';

  @override
  String get viewAll => 'Ver Tudo';

  @override
  String get createCoin => 'Criar Moeda';

  @override
  String get mining => 'Minerando';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get languageSubtitle => 'Alterar idioma do aplicativo';

  @override
  String get selectLanguage => 'Selecionar Idioma';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get home => 'Início';

  @override
  String get referral => 'Indicação';

  @override
  String get profile => 'Perfil';

  @override
  String get dayStreak => 'Sequência de Dias';

  @override
  String dayStreakValue(int count) {
    return 'Sequência de $count Dias';
  }

  @override
  String get active => 'Ativo';

  @override
  String get inactive => 'Inativo';

  @override
  String get sessionEndsIn => 'Sessão termina em';

  @override
  String get startEarning => 'Começar a Ganhar';

  @override
  String get loadingAd => 'Carregando anúncio...';

  @override
  String waitSeconds(int seconds) {
    return 'Aguarde ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Recompensa +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Anúncio premiado não disponível';

  @override
  String rateBoosted(String rate) {
    return 'Taxa impulsionada: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return 'Bônus de anúncio falhou: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Detalhamento da taxa: Base $base, Sequência +$streak, Classificação +$rank, Indicações +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining =>
      'Não foi possível iniciar a mineração. Verifique sua conexão com a internet e tente novamente.';

  @override
  String get createCommunityCoin => 'Criar Moeda da Comunidade';

  @override
  String get launchCoinDescription =>
      'Lance sua própria moeda na Rede ETA instantaneamente.';

  @override
  String get createYourOwnCoin => 'Crie sua própria moeda';

  @override
  String get launchCommunityCoinDescription =>
      'Lance sua própria moeda comunitária que outros usuários da ETA podem minerar.';

  @override
  String get editCoin => 'Editar moeda';

  @override
  String baseRate(String rate) {
    return 'Taxa base: $rate moedas/hora';
  }

  @override
  String createdBy(String username) {
    return 'Criado por @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => 'Sem moedas ainda. Adicione de Moedas ao Vivo.';

  @override
  String get mine => 'Minerar';

  @override
  String get remaining => 'restante';

  @override
  String get holders => 'Detentores';

  @override
  String get close => 'Fechar';

  @override
  String get readMore => 'Ler Mais';

  @override
  String get readLess => 'Ler Menos';

  @override
  String get projectLinks => 'Links do Projeto';

  @override
  String get verifyEmailTitle => 'Verifique Seu E-mail';

  @override
  String get verifyEmailMessage =>
      'Enviamos um link de verificação para o seu endereço de e-mail. Verifique sua conta para desbloquear todos os recursos.';

  @override
  String get resendEmail => 'Reenviar E-mail';

  @override
  String get iHaveVerified => 'Eu verifiquei';

  @override
  String get logout => 'Sair';

  @override
  String get emailVerifiedSuccess => 'E-mail verificado com sucesso!';

  @override
  String get emailNotVerified =>
      'E-mail ainda não verificado. Verifique sua caixa de entrada.';

  @override
  String get verificationEmailSent => 'E-mail de verificação enviado';

  @override
  String get startMining => 'Iniciar Mineração';

  @override
  String get minedCoins => 'Moedas Mineradas';

  @override
  String get liveCoins => 'Moedas ao Vivo';

  @override
  String get asset => 'Ativo';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterNames => 'Nomes';

  @override
  String get filterOldNew => 'Antigo - Novo';

  @override
  String get filterNewOld => 'Novo - Antigo';

  @override
  String startMiningWithCount(int count) {
    return 'Iniciar Mineração ($count)';
  }

  @override
  String get clearSelection => 'Limpar Seleção';

  @override
  String get cancel => 'Cancelar';

  @override
  String get refreshStatus => 'Atualizar Status';

  @override
  String get purchaseFailed => 'Compra falhou';

  @override
  String get securePaymentViaGooglePlay => 'Pagamento seguro via Google Play';

  @override
  String get addedToMinedCoins => 'Adicionado às Moedas Mineradas';

  @override
  String failedToAdd(String message) {
    return 'Falha ao adicionar: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Assinaturas disponíveis apenas em Android/iOS.';

  @override
  String get miningRate => 'Taxa de mineração';

  @override
  String get about => 'Sobre';

  @override
  String get yourMined => 'Sua Mineração';

  @override
  String get totalMined => 'Total Minerado';

  @override
  String get noReferrals => 'Nenhuma indicação ainda';

  @override
  String get linkCopied => 'Link copiado';

  @override
  String get copy => 'Copiar';

  @override
  String get howItWorks => 'Como funciona';

  @override
  String get referralDescription =>
      'Compartilhe seu código com amigos. Quando eles entram e se tornam ativos, você aumenta sua equipe e melhora seu potencial de ganho.';

  @override
  String get yourTeam => 'Sua Equipe';

  @override
  String get referralsTitle => 'Indicações';

  @override
  String get shareLinkTitle => 'Compartilhar Link';

  @override
  String get copyLinkInstruction => 'Copie este link para compartilhar:';

  @override
  String get referralCodeCopied => 'Código de indicação copiado';

  @override
  String joinMeText(String code, String link) {
    return 'Junte-se a mim na Eta Network! Use meu código: $code $link';
  }

  @override
  String get etaNetwork => 'Rede ETA';

  @override
  String get noLiveCommunityCoins => 'Nenhuma moeda comunitária ao vivo';

  @override
  String get rate => 'TAXA';

  @override
  String get filterRandom => 'Aleatório';

  @override
  String get baseRateLabel => 'Taxa Base';

  @override
  String startFailed(String error) {
    return 'Falha ao iniciar: $error';
  }

  @override
  String get sessionProgress => 'Progresso da Sessão';

  @override
  String get remainingLabel => 'restante';

  @override
  String get boostRate => 'Taxa de Impulso';

  @override
  String get minedLabel => 'Minerado';

  @override
  String get noSubscriptionPlansAvailable =>
      'Nenhum plano de assinatura disponível';

  @override
  String get subscriptionPlans => 'Planos de Assinatura';

  @override
  String get recommended => 'Recomendado';

  @override
  String get editCommunityCoin => 'Editar Moeda da Comunidade';

  @override
  String get launchCoinEcosystemDescription =>
      'Lance sua própria moeda dentro do ecossistema ETA para sua comunidade.';

  @override
  String get upload => 'Carregar';

  @override
  String get recommendedImageSize => 'Recomendado 200x200px';

  @override
  String get coinNameLabel => 'Nome da moeda';

  @override
  String get symbolLabel => 'Símbolo';

  @override
  String get descriptionLabel => 'Descrição';

  @override
  String get baseMiningRateLabel => 'Taxa básica de mineração (moedas/hora)';

  @override
  String maxAllowed(String max) {
    return 'Máximo Permitido : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Links sociais e do projeto (opcional)';

  @override
  String get linkTypeWebsite => 'Site';

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
  String get linkTypeOther => 'Outro';

  @override
  String get pasteUrl => 'Colar URL';

  @override
  String get importantNoticeTitle => 'Aviso Importante';

  @override
  String get importantNoticeBody =>
      'Esta moeda faz parte do ecossistema ETA Network e representa a participação em uma comunidade digital em crescimento. Moedas comunitárias são criadas por usuários para construir, experimentar e se envolver dentro da rede. A ETA Network está em um estágio inicial de desenvolvimento. À medida que o ecossistema cresce, novos utilitários, recursos e integrações podem ser introduzidos com base na atividade da comunidade, evolução da plataforma e diretrizes aplicáveis.';

  @override
  String get pleaseWait => 'Por favor, aguarde...';

  @override
  String get save => 'Salvar';

  @override
  String createCoinFailed(String error) {
    return 'Falha ao criar moeda: $error';
  }

  @override
  String get coinNameLengthError =>
      'O nome da moeda deve ter de 3 a 30 caracteres.';

  @override
  String get symbolRequiredError => 'O símbolo é obrigatório.';

  @override
  String get symbolLengthError => 'O símbolo deve ter de 2 a 6 letras/números.';

  @override
  String get descriptionTooLongError => 'A descrição é muito longa.';

  @override
  String baseRateRangeError(String max) {
    return 'A taxa básica de mineração deve estar entre 0.000000001 e $max.';
  }

  @override
  String get coinNameExistsError =>
      'O nome da moeda já existe. Por favor, escolha outro.';

  @override
  String get symbolExistsError =>
      'O símbolo já existe. Por favor, escolha outro.';

  @override
  String get urlInvalidError => 'Uma das URLs é inválida.';

  @override
  String get subscribeAndBoost => 'Assinar e Impulsionar Mineração';

  @override
  String get autoCollect => 'Coleta automática';

  @override
  String autoMineCoins(int count) {
    return 'Minerar automaticamente $count moedas';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Velocidade';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Nenhuma descrição disponível.';

  @override
  String get unknownUser => 'Desconhecido';

  @override
  String get streakLabel => 'SEQUÊNCIA';

  @override
  String get referralsLabel => 'INDICAÇÕES';

  @override
  String get sessionsLabel => 'SESSÕES';

  @override
  String get accountInfoSection => 'Informações da Conta';

  @override
  String get accountInfoTile => 'Informações da Conta';

  @override
  String get invitedByPrompt => 'Convidado por alguém?';

  @override
  String get enterReferralCode => 'Digite o código de indicação';

  @override
  String get invitedStatus => 'Convidado';

  @override
  String get lockedStatus => 'Bloqueado';

  @override
  String get applyButton => 'Aplicar';

  @override
  String get aboutPageTitle => 'Sobre';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Fale Conosco';

  @override
  String get securitySettingsTile => 'Configurações de Segurança';

  @override
  String get securitySettingsPageTitle => 'Configurações de Segurança';

  @override
  String get deleteAccountTile => 'Excluir Conta';

  @override
  String get deleteAccountSubtitle =>
      'Excluir permanentemente sua conta e dados';

  @override
  String get deleteAccountDialogTitle => 'Excluir conta?';

  @override
  String get deleteAccountDialogContent =>
      'Isso excluirá permanentemente sua conta, dados e sessões. Esta ação não pode ser desfeita.';

  @override
  String get deleteButton => 'Excluir';

  @override
  String get kycVerificationTile => 'Verificação KYC';

  @override
  String get kycVerificationDialogTitle => 'Verificação KYC';

  @override
  String get kycComingSoonMessage => 'Será ativado nas próximas etapas.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Sair';

  @override
  String get confirmDeletionTitle => 'Confirmar exclusão';

  @override
  String get enterAccountPassword => 'Digite a senha da conta';

  @override
  String get confirmButton => 'Confirmar';

  @override
  String get usernameLabel => 'Nome de usuário';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get nameLabel => 'Nome';

  @override
  String get ageLabel => 'Idade';

  @override
  String get countryLabel => 'País';

  @override
  String get addressLabel => 'Endereço';

  @override
  String get genderLabel => 'Gênero';

  @override
  String get enterUsernameHint => 'Digite o nome de usuário';

  @override
  String get enterNameHint => 'Digite o nome';

  @override
  String get enterAgeHint => 'Digite a idade';

  @override
  String get enterCountryHint => 'Digite o país';

  @override
  String get enterAddressHint => 'Digite o endereço';

  @override
  String get enterGenderHint => 'Digite o gênero';

  @override
  String get savingLabel => 'Salvando...';

  @override
  String get usernameEmptyError => 'O nome de usuário não pode estar vazio';

  @override
  String get invalidAgeError => 'Valor de idade inválido';

  @override
  String get saveError => 'Falha ao salvar alterações';

  @override
  String get cancelButton => 'Cancelar';
}
