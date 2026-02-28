// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get totalBalance => 'Общий баланс';

  @override
  String joinedDate(String link, Object date) {
    return 'Присоединился $date';
  }

  @override
  String get inviteEarn => 'Приглашай и Зарабатывай';

  @override
  String get shareCodeDescription =>
      'Поделитесь своим уникальным кодом с друзьями, чтобы увеличить скорость майнинга.';

  @override
  String get shareLink => 'Поделиться ссылкой';

  @override
  String get totalInvited => 'ВСЕГО ПРИГЛАШЕНО';

  @override
  String get activeNow => 'АКТИВНЫ СЕЙЧАС';

  @override
  String get viewAll => 'Посмотреть все';

  @override
  String get createCoin => 'Создать монету';

  @override
  String get mining => 'Майнинг';

  @override
  String get settings => 'Настройки';

  @override
  String get language => 'Язык';

  @override
  String get languageSubtitle => 'Изменить язык приложения';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get balanceTitle => 'Баланс';

  @override
  String get home => 'Главная';

  @override
  String get referral => 'Рефералы';

  @override
  String get profile => 'Профиль';

  @override
  String get dayStreak => 'Серия дней';

  @override
  String dayStreakValue(int count) {
    return '$count дн. подряд';
  }

  @override
  String get active => 'Активен';

  @override
  String get inactive => 'Неактивен';

  @override
  String get sessionEndsIn => 'Сессия заканчивается через';

  @override
  String get startEarning => 'Начать зарабатывать';

  @override
  String get loadingAd => 'Загрузка рекламы...';

  @override
  String waitSeconds(int seconds) {
    return 'Ждите $seconds сек';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Награда +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Реклама с вознаграждением недоступна';

  @override
  String rateBoosted(String rate) {
    return 'Скорость увеличена: +$rate ETA/ч';
  }

  @override
  String adBonusFailed(String message) {
    return 'Ошибка бонуса за рекламу: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Детализация: База $base, Серия +$streak, Ранг +$rank, Рефералы +$referrals = $total ETA/ч';
  }

  @override
  String get unableToStartMining =>
      'Не удалось начать майнинг. Проверьте подключение к интернету и попробуйте снова.';

  @override
  String get createCommunityCoin => 'Создать монету сообщества';

  @override
  String get launchCoinDescription =>
      'Запустите свою собственную монету в сети ETA мгновенно.';

  @override
  String get createYourOwnCoin => 'Создайте свою монету';

  @override
  String get launchCommunityCoinDescription =>
      'Запустите свою монету сообщества, которую другие пользователи ETA смогут майнить.';

  @override
  String get editCoin => 'Редактировать монету';

  @override
  String baseRate(String rate) {
    return 'Базовая скорость: $rate монет/час';
  }

  @override
  String createdBy(String username) {
    return 'Создано @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ч';
  }

  @override
  String get noCoinsYet => 'Монет пока нет. Добавьте из Live Coins.';

  @override
  String get mine => 'Майнить';

  @override
  String get remaining => 'осталось';

  @override
  String get holders => 'Держатели';

  @override
  String get close => 'Закрыть';

  @override
  String get readMore => 'Читать далее';

  @override
  String get readLess => 'Свернуть';

  @override
  String get projectLinks => 'Ссылки проекта';

  @override
  String get verifyEmailTitle => 'Подтвердите Email';

  @override
  String get verifyEmailMessage =>
      'Мы отправили ссылку для подтверждения на ваш email. Пожалуйста, подтвердите аккаунт, чтобы разблокировать все функции.';

  @override
  String get resendEmail => 'Отправить снова';

  @override
  String get iHaveVerified => 'Я подтвердил';

  @override
  String get logout => 'Выйти';

  @override
  String get emailVerifiedSuccess => 'Email успешно подтвержден!';

  @override
  String get emailNotVerified => 'Email еще не подтвержден. Проверьте почту.';

  @override
  String get verificationEmailSent => 'Письмо с подтверждением отправлено';

  @override
  String get startMining => 'Начать майнинг';

  @override
  String get minedCoins => 'Добытые монеты';

  @override
  String get liveCoins => 'Живые монеты';

  @override
  String get asset => 'Актив';

  @override
  String get filterStatus => 'Статус';

  @override
  String get filterPopular => 'Популярные';

  @override
  String get filterNames => 'Имена';

  @override
  String get filterOldNew => 'Старые - Новые';

  @override
  String get filterNewOld => 'Новые - Старые';

  @override
  String startMiningWithCount(int count) {
    return 'Начать майнинг ($count)';
  }

  @override
  String get clearSelection => 'Очистить выбор';

  @override
  String get cancel => 'Отмена';

  @override
  String get refreshStatus => 'Обновить статус';

  @override
  String get purchaseFailed => 'Покупка не удалась';

  @override
  String get securePaymentViaGooglePlay =>
      'Безопасная оплата через Google Play';

  @override
  String get addedToMinedCoins => 'Добавлено в добытые монеты';

  @override
  String failedToAdd(String message) {
    return 'Не удалось добавить: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Подписки доступны только на Android/iOS.';

  @override
  String get miningRate => 'Скорость майнинга';

  @override
  String get about => 'О приложении';

  @override
  String get yourMined => 'Ваши добытые';

  @override
  String get totalMined => 'Всего добыто';

  @override
  String get noReferrals => 'Рефералов пока нет';

  @override
  String get linkCopied => 'Ссылка скопирована';

  @override
  String get copy => 'Копировать';

  @override
  String get howItWorks => 'Как это работает';

  @override
  String get referralDescription =>
      'Поделитесь кодом с друзьями. Когда они присоединяются и становятся активными, ваша команда растет, и вы увеличиваете свой потенциал заработка.';

  @override
  String get yourTeam => 'Ваша команда';

  @override
  String get referralsTitle => 'Рефералы';

  @override
  String get shareLinkTitle => 'Поделиться ссылкой';

  @override
  String get copyLinkInstruction => 'Скопируйте ссылку для обмена:';

  @override
  String get referralCodeCopied => 'Реферальный код скопирован';

  @override
  String joinMeText(String code, String link) {
    return 'Присоединяйся ко мне в Eta Network! Используй мой код: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'Нет живых монет сообщества';

  @override
  String get rate => 'СКОРОСТЬ';

  @override
  String get filterRandom => 'Случайно';

  @override
  String get baseRateLabel => 'Базовая скорость';

  @override
  String startFailed(String error) {
    return 'Ошибка запуска: $error';
  }

  @override
  String get sessionProgress => 'Прогресс сессии';

  @override
  String get remainingLabel => 'осталось';

  @override
  String get boostRate => 'Ускорение';

  @override
  String get minedLabel => 'Добыто';

  @override
  String get noSubscriptionPlansAvailable => 'Нет доступных планов подписки';

  @override
  String get subscriptionPlans => 'Планы подписки';

  @override
  String get recommended => 'Рекомендуемый';

  @override
  String get editCommunityCoin => 'Редактировать монету сообщества';

  @override
  String get launchCoinEcosystemDescription =>
      'Запустите свою монету внутри экосистемы ETA для вашего сообщества.';

  @override
  String get upload => 'Загрузить';

  @override
  String get recommendedImageSize => 'Рекомендуется 200×200px';

  @override
  String get coinNameLabel => 'Название монеты';

  @override
  String get symbolLabel => 'Символ';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get baseMiningRateLabel => 'Базовая скорость (монет/час)';

  @override
  String maxAllowed(String max) {
    return 'Максимум: $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Социальные сети и ссылки (необязательно)';

  @override
  String get linkTypeWebsite => 'Веб-сайт';

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
  String get linkTypeOther => 'Другое';

  @override
  String get pasteUrl => 'Вставить URL';

  @override
  String get importantNoticeTitle => 'Важное уведомление';

  @override
  String get importantNoticeBody =>
      'Эта монета является частью экосистемы ETA Network и представляет участие в растущем цифровом сообществе. Монеты сообщества создаются пользователями для строительства, экспериментов и взаимодействия внутри сети. ETA Network находится на ранней стадии развития. По мере роста экосистемы могут внедряться новые утилиты, функции и интеграции на основе активности сообщества, эволюции платформы и применимых правил.';

  @override
  String get pleaseWait => 'Пожалуйста, подождите...';

  @override
  String get save => 'Сохранить';

  @override
  String createCoinFailed(String error) {
    return 'Не удалось создать монету: $error';
  }

  @override
  String get coinNameLengthError =>
      'Название монеты должно быть от 3 до 30 символов.';

  @override
  String get symbolRequiredError => 'Символ обязателен.';

  @override
  String get symbolLengthError => 'Символ должен содержать 2–6 букв/цифр.';

  @override
  String get descriptionTooLongError => 'Описание слишком длинное.';

  @override
  String baseRateRangeError(String max) {
    return 'Базовая скорость должна быть между 0.000000001 и $max.';
  }

  @override
  String get coinNameExistsError =>
      'Название монеты уже существует. Выберите другое.';

  @override
  String get symbolExistsError => 'Символ уже существует. Выберите другой.';

  @override
  String get urlInvalidError => 'Один из URL недействителен.';

  @override
  String get subscribeAndBoost => 'Подписаться и ускорить';

  @override
  String get autoCollect => 'Авто-сбор';

  @override
  String autoMineCoins(int count) {
    return 'Авто-майнинг $count монет';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Скорость';
  }

  @override
  String get perHourSuffix => '/ч';

  @override
  String get etaPerHourSuffix => 'ETA/ч';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Описание недоступно.';

  @override
  String get unknownUser => 'Неизвестный';

  @override
  String get streakLabel => 'СЕРИЯ';

  @override
  String get referralsLabel => 'РЕФЕРАЛЫ';

  @override
  String get sessionsLabel => 'СЕССИИ';

  @override
  String get accountInfoSection => 'Инфо об аккаунте';

  @override
  String get accountInfoTile => 'Инфо об аккаунте';

  @override
  String get invitedByPrompt => 'Приглашены кем-то?';

  @override
  String get enterReferralCode => 'Введите реферальный код';

  @override
  String get invitedStatus => 'Приглашен';

  @override
  String get lockedStatus => 'Заблокировано';

  @override
  String get applyButton => 'Применить';

  @override
  String get aboutPageTitle => 'О приложении';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'White Paper';

  @override
  String get contactUsTile => 'Связаться с нами';

  @override
  String get securitySettingsTile => 'Настройки безопасности';

  @override
  String get securitySettingsPageTitle => 'Настройки безопасности';

  @override
  String get deleteAccountTile => 'Удалить аккаунт';

  @override
  String get deleteAccountSubtitle => 'Навсегда удалить аккаунт и данные';

  @override
  String get deleteAccountDialogTitle => 'Удалить аккаунт?';

  @override
  String get deleteAccountDialogContent =>
      'Это навсегда удалит ваш аккаунт, данные и сессии. Это действие нельзя отменить.';

  @override
  String get deleteButton => 'Удалить';

  @override
  String get kycVerificationTile => 'KYC Верификация';

  @override
  String get kycVerificationDialogTitle => 'KYC Верификация';

  @override
  String get kycComingSoonMessage => 'Будет активировано на следующих этапах.';

  @override
  String get okButton => 'ОК';

  @override
  String get logOutLabel => 'Выйти';

  @override
  String get confirmDeletionTitle => 'Подтвердите удаление';

  @override
  String get enterAccountPassword => 'Введите пароль аккаунта';

  @override
  String get confirmButton => 'Подтвердить';

  @override
  String get usernameLabel => 'Имя пользователя';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Имя';

  @override
  String get ageLabel => 'Возраст';

  @override
  String get countryLabel => 'Страна';

  @override
  String get addressLabel => 'Адрес';

  @override
  String get genderLabel => 'Пол';

  @override
  String get enterUsernameHint => 'Введите имя пользователя';

  @override
  String get enterNameHint => 'Введите имя';

  @override
  String get enterAgeHint => 'Введите возраст';

  @override
  String get enterCountryHint => 'Введите страну';

  @override
  String get enterAddressHint => 'Введите адрес';

  @override
  String get enterGenderHint => 'Введите пол';

  @override
  String get savingLabel => 'Сохранение...';

  @override
  String get usernameEmptyError => 'Имя пользователя не может быть пустым';

  @override
  String get invalidAgeError => 'Неверный возраст';

  @override
  String get saveError => 'Не удалось сохранить изменения';

  @override
  String get cancelButton => 'Отмена';
}
