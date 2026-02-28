// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get totalBalance => '総残高';

  @override
  String joinedDate(String link, Object date) {
    return '参加日 $date';
  }

  @override
  String get inviteEarn => '招待して稼ぐ';

  @override
  String get shareCodeDescription => '独自のコードを友達と共有して、マイニング率を上げましょう。';

  @override
  String get shareLink => 'リンクを共有';

  @override
  String get totalInvited => '招待総数';

  @override
  String get activeNow => '現在アクティブ';

  @override
  String get viewAll => 'すべて見る';

  @override
  String get createCoin => 'コインを作成';

  @override
  String get mining => 'マイニング';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageSubtitle => 'アプリの言語を変更';

  @override
  String get selectLanguage => '言語を選択';

  @override
  String get balanceTitle => '残高';

  @override
  String get home => 'ホーム';

  @override
  String get referral => '紹介';

  @override
  String get profile => 'プロフィール';

  @override
  String get dayStreak => '連続日数';

  @override
  String dayStreakValue(int count) {
    return '$count 日連続';
  }

  @override
  String get active => 'アクティブ';

  @override
  String get inactive => '非アクティブ';

  @override
  String get sessionEndsIn => 'セッション終了まで';

  @override
  String get startEarning => '稼ぎ始める';

  @override
  String get loadingAd => '広告を読み込み中...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds秒お待ちください';
  }

  @override
  String rewardPlusPercent(String percent) {
    return '報酬 +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'リワード広告は利用できません';

  @override
  String rateBoosted(String rate) {
    return 'レートブースト: +$rate ETA/時';
  }

  @override
  String adBonusFailed(String message) {
    return '広告ボーナス失敗: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'レート内訳: 基本 $base, ストリーク +$streak, ランク +$rank, 紹介 +$referrals = $total ETA/時';
  }

  @override
  String get unableToStartMining => 'マイニングを開始できません。インターネット接続を確認して再試行してください。';

  @override
  String get createCommunityCoin => 'コミュニティコインを作成';

  @override
  String get launchCoinDescription => 'ETAネットワーク上で独自のコインを即座にローンチします。';

  @override
  String get createYourOwnCoin => '独自のコインを作成';

  @override
  String get launchCommunityCoinDescription =>
      '他のETAユーザーがマイニングできるコミュニティコインをローンチします。';

  @override
  String get editCoin => 'コインを編集';

  @override
  String baseRate(String rate) {
    return '基本レート: $rate コイン/時間';
  }

  @override
  String createdBy(String username) {
    return '作成者 @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/時';
  }

  @override
  String get noCoinsYet => 'コインはまだありません。ライブコインから追加してください。';

  @override
  String get mine => 'マイニング';

  @override
  String get remaining => '残り';

  @override
  String get holders => '保有者';

  @override
  String get close => '閉じる';

  @override
  String get readMore => '続きを読む';

  @override
  String get readLess => '閉じる';

  @override
  String get projectLinks => 'プロジェクトリンク';

  @override
  String get verifyEmailTitle => 'メールを確認';

  @override
  String get verifyEmailMessage =>
      '確認リンクをメールアドレスに送信しました。すべての機能を利用するにはアカウントを確認してください。';

  @override
  String get resendEmail => 'メールを再送信';

  @override
  String get iHaveVerified => '確認しました';

  @override
  String get logout => 'ログアウト';

  @override
  String get emailVerifiedSuccess => 'メールが正常に確認されました！';

  @override
  String get emailNotVerified => 'メールはまだ確認されていません。受信トレイを確認してください。';

  @override
  String get verificationEmailSent => '確認メールを送信しました';

  @override
  String get startMining => 'マイニング開始';

  @override
  String get minedCoins => 'マイニング済みコイン';

  @override
  String get liveCoins => 'ライブコイン';

  @override
  String get asset => '資産';

  @override
  String get filterStatus => 'ステータス';

  @override
  String get filterPopular => '人気';

  @override
  String get filterNames => '名前';

  @override
  String get filterOldNew => '古い - 新しい';

  @override
  String get filterNewOld => '新しい - 古い';

  @override
  String startMiningWithCount(int count) {
    return 'マイニング開始 ($count)';
  }

  @override
  String get clearSelection => '選択をクリア';

  @override
  String get cancel => 'キャンセル';

  @override
  String get refreshStatus => 'ステータスを更新';

  @override
  String get purchaseFailed => '購入に失敗しました';

  @override
  String get securePaymentViaGooglePlay => 'Google Playでの安全な支払い';

  @override
  String get addedToMinedCoins => 'マイニング済みコインに追加されました';

  @override
  String failedToAdd(String message) {
    return '追加に失敗しました: $message';
  }

  @override
  String get subscriptionsUnavailable => 'サブスクリプションはAndroid/iOSでのみ利用可能です。';

  @override
  String get miningRate => 'マイニングレート';

  @override
  String get about => 'アプリについて';

  @override
  String get yourMined => 'あなたのマイニング';

  @override
  String get totalMined => '総マイニング数';

  @override
  String get noReferrals => '紹介はまだありません';

  @override
  String get linkCopied => 'リンクをコピーしました';

  @override
  String get copy => 'コピー';

  @override
  String get howItWorks => '仕組み';

  @override
  String get referralDescription =>
      'コードを友達と共有してください。彼らが参加してアクティブになると、チームが成長し、収益の可能性が向上します。';

  @override
  String get yourTeam => 'あなたのチーム';

  @override
  String get referralsTitle => '紹介';

  @override
  String get shareLinkTitle => 'リンクを共有';

  @override
  String get copyLinkInstruction => 'このリンクをコピーして共有:';

  @override
  String get referralCodeCopied => '紹介コードをコピーしました';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Networkに参加しましょう！私のコードを使ってください: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'ライブコミュニティコインはありません';

  @override
  String get rate => 'レート';

  @override
  String get filterRandom => 'ランダム';

  @override
  String get baseRateLabel => '基本レート';

  @override
  String startFailed(String error) {
    return '開始に失敗しました: $error';
  }

  @override
  String get sessionProgress => 'セッション進行状況';

  @override
  String get remainingLabel => '残り';

  @override
  String get boostRate => 'ブーストレート';

  @override
  String get minedLabel => 'マイニング済み';

  @override
  String get noSubscriptionPlansAvailable => '利用可能なサブスクリプションプランはありません';

  @override
  String get subscriptionPlans => 'サブスクリプションプラン';

  @override
  String get recommended => '推奨';

  @override
  String get editCommunityCoin => 'コミュニティコインを編集';

  @override
  String get launchCoinEcosystemDescription =>
      'コミュニティのためにETAエコシステム内で独自のコインをローンチします。';

  @override
  String get upload => 'アップロード';

  @override
  String get recommendedImageSize => '推奨 200×200px';

  @override
  String get coinNameLabel => 'コイン名';

  @override
  String get symbolLabel => 'シンボル';

  @override
  String get descriptionLabel => '説明';

  @override
  String get baseMiningRateLabel => '基本マイニングレート (コイン/時間)';

  @override
  String maxAllowed(String max) {
    return '最大許容 : $max';
  }

  @override
  String get socialProjectLinksOptional => 'ソーシャル＆プロジェクトリンク (オプション)';

  @override
  String get linkTypeWebsite => 'ウェブサイト';

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
  String get linkTypeOther => 'その他';

  @override
  String get pasteUrl => 'URLを貼り付け';

  @override
  String get importantNoticeTitle => '重要なお知らせ';

  @override
  String get importantNoticeBody =>
      'このコインはETA Networkエコシステムの一部であり、成長するデジタルコミュニティへの参加を表しています。コミュニティコインは、ユーザーがネットワーク内で構築、実験、関与するために作成されます。ETA Networkは開発の初期段階にあります。エコシステムが成長するにつれて、コミュニティの活動、プラットフォームの進化、および適用されるガイドラインに基づいて、新しいユーティリティ、機能、および統合が導入される場合があります。';

  @override
  String get pleaseWait => 'お待ちください...';

  @override
  String get save => '保存';

  @override
  String createCoinFailed(String error) {
    return 'コインの作成に失敗しました: $error';
  }

  @override
  String get coinNameLengthError => 'コイン名は3〜30文字である必要があります。';

  @override
  String get symbolRequiredError => 'シンボルは必須です。';

  @override
  String get symbolLengthError => 'シンボルは2〜6文字の英数字である必要があります。';

  @override
  String get descriptionTooLongError => '説明が長すぎます。';

  @override
  String baseRateRangeError(String max) {
    return '基本マイニングレートは0.000000001から$maxの間である必要があります。';
  }

  @override
  String get coinNameExistsError => 'コイン名は既に存在します。別の名前を選択してください。';

  @override
  String get symbolExistsError => 'シンボルは既に存在します。別のシンボルを選択してください。';

  @override
  String get urlInvalidError => 'URLの1つが無効です。';

  @override
  String get subscribeAndBoost => '購読してマイニングをブースト';

  @override
  String get autoCollect => '自動収集';

  @override
  String autoMineCoins(int count) {
    return '自動マイニング $count コイン';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% 速度';
  }

  @override
  String get perHourSuffix => '/時';

  @override
  String get etaPerHourSuffix => 'ETA/時';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => '説明はありません。';

  @override
  String get unknownUser => '不明';

  @override
  String get streakLabel => 'ストリーク';

  @override
  String get referralsLabel => '紹介';

  @override
  String get sessionsLabel => 'セッション';

  @override
  String get accountInfoSection => 'アカウント情報';

  @override
  String get accountInfoTile => 'アカウント情報';

  @override
  String get invitedByPrompt => '招待されましたか？';

  @override
  String get enterReferralCode => '紹介コードを入力';

  @override
  String get invitedStatus => '招待済み';

  @override
  String get lockedStatus => 'ロック済み';

  @override
  String get applyButton => '適用';

  @override
  String get aboutPageTitle => 'アプリについて';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'ホワイトペーパー';

  @override
  String get contactUsTile => 'お問い合わせ';

  @override
  String get securitySettingsTile => 'セキュリティ設定';

  @override
  String get securitySettingsPageTitle => 'セキュリティ設定';

  @override
  String get deleteAccountTile => 'アカウント削除';

  @override
  String get deleteAccountSubtitle => 'アカウントとデータを完全に削除';

  @override
  String get deleteAccountDialogTitle => 'アカウントを削除しますか？';

  @override
  String get deleteAccountDialogContent =>
      'これにより、アカウント、データ、セッションが完全に削除されます。この操作は元に戻せません。';

  @override
  String get deleteButton => '削除';

  @override
  String get kycVerificationTile => 'KYC確認';

  @override
  String get kycVerificationDialogTitle => 'KYC確認';

  @override
  String get kycComingSoonMessage => '今後の段階で有効になります。';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'ログアウト';

  @override
  String get confirmDeletionTitle => '削除の確認';

  @override
  String get enterAccountPassword => 'アカウントのパスワードを入力';

  @override
  String get confirmButton => '確認';

  @override
  String get usernameLabel => 'ユーザー名';

  @override
  String get emailLabel => 'メール';

  @override
  String get nameLabel => '名前';

  @override
  String get ageLabel => '年齢';

  @override
  String get countryLabel => '国';

  @override
  String get addressLabel => '住所';

  @override
  String get genderLabel => '性別';

  @override
  String get enterUsernameHint => 'ユーザー名を入力';

  @override
  String get enterNameHint => '名前を入力';

  @override
  String get enterAgeHint => '年齢を入力';

  @override
  String get enterCountryHint => '国を入力';

  @override
  String get enterAddressHint => '住所を入力';

  @override
  String get enterGenderHint => '性別を入力';

  @override
  String get savingLabel => '保存中...';

  @override
  String get usernameEmptyError => 'ユーザー名は空にできません';

  @override
  String get invalidAgeError => '無効な年齢';

  @override
  String get saveError => '変更を保存できませんでした';

  @override
  String get cancelButton => 'キャンセル';
}
