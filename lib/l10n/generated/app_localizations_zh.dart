// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get totalBalance => '总余额';

  @override
  String joinedDate(String link, Object date) {
    return '加入时间 $date';
  }

  @override
  String get inviteEarn => '邀请赚钱';

  @override
  String get shareCodeDescription => '分享您的唯一代码给朋友以提高您的挖矿率。';

  @override
  String get shareLink => '分享链接';

  @override
  String get totalInvited => '邀请总数';

  @override
  String get activeNow => '当前活跃';

  @override
  String get viewAll => '查看全部';

  @override
  String get createCoin => '创建代币';

  @override
  String get mining => '挖矿中';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageSubtitle => '更改应用语言';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get balanceTitle => '余额';

  @override
  String get home => '首页';

  @override
  String get referral => '推荐';

  @override
  String get profile => '个人资料';

  @override
  String get dayStreak => '连续天数';

  @override
  String dayStreakValue(int count) {
    return '连续 $count 天';
  }

  @override
  String get active => '活跃';

  @override
  String get inactive => '不活跃';

  @override
  String get sessionEndsIn => '会话结束于';

  @override
  String get startEarning => '开始赚钱';

  @override
  String get loadingAd => '加载广告中…';

  @override
  String waitSeconds(int seconds) {
    return '等待 $seconds 秒';
  }

  @override
  String rewardPlusPercent(String percent) {
    return '奖励 +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => '奖励广告不可用';

  @override
  String rateBoosted(String rate) {
    return '速率提升: +$rate ETA/小时';
  }

  @override
  String adBonusFailed(String message) {
    return '广告奖励失败: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return '速率明细: 基础 $base, 连续 +$streak, 等级 +$rank, 推荐 +$referrals = $total ETA/小时';
  }

  @override
  String get unableToStartMining => '无法开始挖矿。请检查您的网络连接并重试。';

  @override
  String get createCommunityCoin => '创建社区代币';

  @override
  String get launchCoinDescription => '立即在 ETA 网络上发布您自己的代币。';

  @override
  String get createYourOwnCoin => '创建您自己的代币';

  @override
  String get launchCommunityCoinDescription => '发布您自己的社区代币，其他 ETA 用户可以挖掘。';

  @override
  String get editCoin => '编辑代币';

  @override
  String baseRate(String rate) {
    return '基础速率: $rate 代币/小时';
  }

  @override
  String createdBy(String username) {
    return '创建者 @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/小时';
  }

  @override
  String get noCoinsYet => '暂无代币。从实时代币中添加。';

  @override
  String get mine => '挖矿';

  @override
  String get remaining => '剩余';

  @override
  String get holders => '持有人';

  @override
  String get close => '关闭';

  @override
  String get readMore => '阅读更多';

  @override
  String get readLess => '收起';

  @override
  String get projectLinks => '项目链接';

  @override
  String get verifyEmailTitle => '验证您的邮箱';

  @override
  String get verifyEmailMessage => '我们已向您的邮箱发送了验证链接。请验证您的帐户以解锁所有功能。';

  @override
  String get resendEmail => '重发邮件';

  @override
  String get iHaveVerified => '我已验证';

  @override
  String get logout => '登出';

  @override
  String get emailVerifiedSuccess => '邮箱验证成功！';

  @override
  String get emailNotVerified => '邮箱尚未验证。请检查您的收件箱。';

  @override
  String get verificationEmailSent => '验证邮件已发送';

  @override
  String get startMining => '开始挖矿';

  @override
  String get minedCoins => '已挖代币';

  @override
  String get liveCoins => '实时代币';

  @override
  String get asset => '资产';

  @override
  String get filterStatus => '状态';

  @override
  String get filterPopular => '热门';

  @override
  String get filterNames => '名称';

  @override
  String get filterOldNew => '旧 - 新';

  @override
  String get filterNewOld => '新 - 旧';

  @override
  String startMiningWithCount(int count) {
    return '开始挖矿 ($count)';
  }

  @override
  String get clearSelection => '清除选择';

  @override
  String get cancel => '取消';

  @override
  String get refreshStatus => '刷新状态';

  @override
  String get purchaseFailed => '购买失败';

  @override
  String get securePaymentViaGooglePlay => 'Google Play 安全支付';

  @override
  String get addedToMinedCoins => '已添加到已挖代币';

  @override
  String failedToAdd(String message) {
    return '添加失败: $message';
  }

  @override
  String get subscriptionsUnavailable => '订阅仅在 Android/iOS 上可用。';

  @override
  String get miningRate => '挖矿速率';

  @override
  String get about => '关于';

  @override
  String get yourMined => '您已挖掘';

  @override
  String get totalMined => '挖掘总数';

  @override
  String get noReferrals => '暂无推荐';

  @override
  String get linkCopied => '链接已复制';

  @override
  String get copy => '复制';

  @override
  String get howItWorks => '工作原理';

  @override
  String get referralDescription => '与朋友分享您的代码。当他们加入并活跃时，您的团队将壮大，您的收入潜力也会提高。';

  @override
  String get yourTeam => '您的团队';

  @override
  String get referralsTitle => '推荐';

  @override
  String get shareLinkTitle => '分享链接';

  @override
  String get copyLinkInstruction => '复制此链接以分享:';

  @override
  String get referralCodeCopied => '推荐码已复制';

  @override
  String joinMeText(String code, String link) {
    return '加入我在 Eta Network！使用我的代码: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => '没有实时社区代币';

  @override
  String get rate => '速率';

  @override
  String get filterRandom => '随机';

  @override
  String get baseRateLabel => '基础速率';

  @override
  String startFailed(String error) {
    return '启动失败: $error';
  }

  @override
  String get sessionProgress => '会话进度';

  @override
  String get remainingLabel => '剩余';

  @override
  String get boostRate => '提升速率';

  @override
  String get minedLabel => '已挖掘';

  @override
  String get noSubscriptionPlansAvailable => '没有可用的订阅计划';

  @override
  String get subscriptionPlans => '订阅计划';

  @override
  String get recommended => '推荐';

  @override
  String get editCommunityCoin => '编辑社区代币';

  @override
  String get launchCoinEcosystemDescription => '在 ETA 生态系统内为您的社区发布您自己的代币。';

  @override
  String get upload => '上传';

  @override
  String get recommendedImageSize => '推荐尺寸 200×200px';

  @override
  String get coinNameLabel => '代币名称';

  @override
  String get symbolLabel => '符号';

  @override
  String get descriptionLabel => '描述';

  @override
  String get baseMiningRateLabel => '基础挖矿速率 (代币/小时)';

  @override
  String maxAllowed(String max) {
    return '最大允许 : $max';
  }

  @override
  String get socialProjectLinksOptional => '社交和项目链接 (可选)';

  @override
  String get linkTypeWebsite => '网站';

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
  String get linkTypeOther => '其他';

  @override
  String get pasteUrl => '粘贴 URL';

  @override
  String get importantNoticeTitle => '重要提示';

  @override
  String get importantNoticeBody =>
      '此代币是 ETA 网络生态系统的一部分，代表参与不断增长的数字社区。社区代币由用户创建，用于在网络内构建、实验和参与。ETA 网络处于早期开发阶段。随着生态系统的发展，可能会根据社区活动、平台演变和适用准则引入新的实用程序、功能和集成。';

  @override
  String get pleaseWait => '请稍候…';

  @override
  String get save => '保存';

  @override
  String createCoinFailed(String error) {
    return '创建代币失败: $error';
  }

  @override
  String get coinNameLengthError => '代币名称必须为 3–30 个字符。';

  @override
  String get symbolRequiredError => '符号为必填项。';

  @override
  String get symbolLengthError => '符号必须为 2–6 个字母/数字。';

  @override
  String get descriptionTooLongError => '描述太长。';

  @override
  String baseRateRangeError(String max) {
    return '基础挖矿速率必须在 0.000000001 和 $max 之间。';
  }

  @override
  String get coinNameExistsError => '代币名称已存在。请选择其他名称。';

  @override
  String get symbolExistsError => '符号已存在。请选择其他符号。';

  @override
  String get urlInvalidError => '其中一个 URL 无效。';

  @override
  String get subscribeAndBoost => '订阅并提升挖矿';

  @override
  String get autoCollect => '自动收集';

  @override
  String autoMineCoins(int count) {
    return '自动挖掘 $count 个代币';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% 速度';
  }

  @override
  String get perHourSuffix => '/小时';

  @override
  String get etaPerHourSuffix => 'ETA/小时';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => '无可用描述。';

  @override
  String get unknownUser => '未知';

  @override
  String get streakLabel => '连续';

  @override
  String get referralsLabel => '推荐';

  @override
  String get sessionsLabel => '会话';

  @override
  String get accountInfoSection => '账户信息';

  @override
  String get accountInfoTile => '账户信息';

  @override
  String get invitedByPrompt => '被邀请？';

  @override
  String get enterReferralCode => '输入推荐码';

  @override
  String get invitedStatus => '已邀请';

  @override
  String get lockedStatus => '已锁定';

  @override
  String get applyButton => '应用';

  @override
  String get aboutPageTitle => '关于';

  @override
  String get faqTile => '常见问题';

  @override
  String get whitePaperTile => '白皮书';

  @override
  String get contactUsTile => '联系我们';

  @override
  String get securitySettingsTile => '安全设置';

  @override
  String get securitySettingsPageTitle => '安全设置';

  @override
  String get deleteAccountTile => '删除账户';

  @override
  String get deleteAccountSubtitle => '永久删除您的账户和数据';

  @override
  String get deleteAccountDialogTitle => '删除账户？';

  @override
  String get deleteAccountDialogContent => '这将永久删除您的账户、数据和会话。此操作无法撤消。';

  @override
  String get deleteButton => '删除';

  @override
  String get kycVerificationTile => 'KYC 验证';

  @override
  String get kycVerificationDialogTitle => 'KYC 验证';

  @override
  String get kycComingSoonMessage => '将在接下来的阶段激活。';

  @override
  String get okButton => '确定';

  @override
  String get logOutLabel => '登出';

  @override
  String get confirmDeletionTitle => '确认删除';

  @override
  String get enterAccountPassword => '输入账户密码';

  @override
  String get confirmButton => '确认';

  @override
  String get usernameLabel => '用户名';

  @override
  String get emailLabel => '邮箱';

  @override
  String get nameLabel => '姓名';

  @override
  String get ageLabel => '年龄';

  @override
  String get countryLabel => '国家';

  @override
  String get addressLabel => '地址';

  @override
  String get genderLabel => '性别';

  @override
  String get enterUsernameHint => '输入用户名';

  @override
  String get enterNameHint => '输入姓名';

  @override
  String get enterAgeHint => '输入年龄';

  @override
  String get enterCountryHint => '输入国家';

  @override
  String get enterAddressHint => '输入地址';

  @override
  String get enterGenderHint => '输入性别';

  @override
  String get savingLabel => '保存中...';

  @override
  String get usernameEmptyError => '用户名不能为空';

  @override
  String get invalidAgeError => '年龄值无效';

  @override
  String get saveError => '保存更改失败';

  @override
  String get cancelButton => '取消';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant() : super('zh_Hant');

  @override
  String get totalBalance => '總餘額';

  @override
  String joinedDate(String link, Object date) {
    return '加入時間 $date';
  }

  @override
  String get inviteEarn => '邀請賺錢';

  @override
  String get shareCodeDescription => '分享您的唯一代碼給朋友以提高您的挖礦率。';

  @override
  String get shareLink => '分享鏈接';

  @override
  String get totalInvited => '邀請總數';

  @override
  String get activeNow => '當前活躍';

  @override
  String get viewAll => '查看全部';

  @override
  String get createCoin => '創建代幣';

  @override
  String get mining => '挖礦中';

  @override
  String get settings => '設置';

  @override
  String get language => '語言';

  @override
  String get languageSubtitle => '更改應用語言';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get balanceTitle => '餘額';

  @override
  String get home => '首頁';

  @override
  String get referral => '推薦';

  @override
  String get profile => '個人資料';

  @override
  String get dayStreak => '連續天數';

  @override
  String dayStreakValue(int count) {
    return '連續 $count 天';
  }

  @override
  String get active => '活躍';

  @override
  String get inactive => '不活躍';

  @override
  String get sessionEndsIn => '會話結束於';

  @override
  String get startEarning => '開始賺錢';

  @override
  String get loadingAd => '加載廣告中…';

  @override
  String waitSeconds(int seconds) {
    return '等待 $seconds 秒';
  }

  @override
  String rewardPlusPercent(String percent) {
    return '獎勵 +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => '獎勵廣告不可用';

  @override
  String rateBoosted(String rate) {
    return '速率提升: +$rate ETA/小時';
  }

  @override
  String adBonusFailed(String message) {
    return '廣告獎勵失敗: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return '速率明細: 基礎 $base, 連續 +$streak, 等級 +$rank, 推薦 +$referrals = $total ETA/小時';
  }

  @override
  String get unableToStartMining => '無法開始挖礦。請檢查您的網絡連接並重試。';

  @override
  String get createCommunityCoin => '創建社區代幣';

  @override
  String get launchCoinDescription => '立即在 ETA 網絡上發布您自己的代幣。';

  @override
  String get createYourOwnCoin => '創建您自己的代幣';

  @override
  String get launchCommunityCoinDescription => '發布您自己的社區代幣，其他 ETA 用戶可以挖掘。';

  @override
  String get editCoin => '編輯代幣';

  @override
  String baseRate(String rate) {
    return '基礎速率: $rate 代幣/小時';
  }

  @override
  String createdBy(String username) {
    return '創建者 @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/小時';
  }

  @override
  String get noCoinsYet => '暫無代幣。從實時代幣中添加。';

  @override
  String get mine => '挖礦';

  @override
  String get remaining => '剩餘';

  @override
  String get holders => '持有人';

  @override
  String get close => '關閉';

  @override
  String get readMore => '閱讀更多';

  @override
  String get readLess => '收起';

  @override
  String get projectLinks => '項目鏈接';

  @override
  String get verifyEmailTitle => '驗證您的郵箱';

  @override
  String get verifyEmailMessage => '我們已向您的郵箱發送了驗證鏈接。請驗證您的帳戶以解鎖所有功能。';

  @override
  String get resendEmail => '重發郵件';

  @override
  String get iHaveVerified => '我已驗證';

  @override
  String get logout => '登出';

  @override
  String get emailVerifiedSuccess => '郵箱驗證成功！';

  @override
  String get emailNotVerified => '郵箱尚未驗證。請檢查您的收件箱。';

  @override
  String get verificationEmailSent => '驗證郵件已發送';

  @override
  String get startMining => '開始挖礦';

  @override
  String get minedCoins => '已挖代幣';

  @override
  String get liveCoins => '實時代幣';

  @override
  String get asset => '資產';

  @override
  String get filterStatus => '狀態';

  @override
  String get filterPopular => '熱門';

  @override
  String get filterNames => '名稱';

  @override
  String get filterOldNew => '舊 - 新';

  @override
  String get filterNewOld => '新 - 舊';

  @override
  String startMiningWithCount(int count) {
    return '開始挖礦 ($count)';
  }

  @override
  String get clearSelection => '清除選擇';

  @override
  String get cancel => '取消';

  @override
  String get refreshStatus => '刷新狀態';

  @override
  String get purchaseFailed => '購買失敗';

  @override
  String get securePaymentViaGooglePlay => 'Google Play 安全支付';

  @override
  String get addedToMinedCoins => '已添加到已挖代幣';

  @override
  String failedToAdd(String message) {
    return '添加失敗: $message';
  }

  @override
  String get subscriptionsUnavailable => '訂閱僅在 Android/iOS 上可用。';

  @override
  String get miningRate => '挖礦速率';

  @override
  String get about => '關於';

  @override
  String get yourMined => '您已挖掘';

  @override
  String get totalMined => '挖掘總數';

  @override
  String get noReferrals => '暫無推薦';

  @override
  String get linkCopied => '鏈接已復制';

  @override
  String get copy => '復制';

  @override
  String get howItWorks => '工作原理';

  @override
  String get referralDescription => '與朋友分享您的代碼。當他們加入並活躍時，您的團隊將壯大，您的收入潛力也會提高。';

  @override
  String get yourTeam => '您的團隊';

  @override
  String get referralsTitle => '推薦';

  @override
  String get shareLinkTitle => '分享鏈接';

  @override
  String get copyLinkInstruction => '復制此鏈接以分享:';

  @override
  String get referralCodeCopied => '推薦碼已復制';

  @override
  String joinMeText(String code, String link) {
    return '加入我在 Eta Network！使用我的代碼: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => '沒有實時社區代幣';

  @override
  String get rate => '速率';

  @override
  String get filterRandom => '隨機';

  @override
  String get baseRateLabel => '基礎速率';

  @override
  String startFailed(String error) {
    return '啟動失敗: $error';
  }

  @override
  String get sessionProgress => '會話進度';

  @override
  String get remainingLabel => '剩餘';

  @override
  String get boostRate => '提升速率';

  @override
  String get minedLabel => '已挖掘';

  @override
  String get noSubscriptionPlansAvailable => '沒有訂閱計劃可用';

  @override
  String get subscriptionPlans => '訂閱計劃';

  @override
  String get recommended => '推薦';

  @override
  String get editCommunityCoin => '編輯社區代幣';

  @override
  String get launchCoinEcosystemDescription => '在 ETA 生態系統內為您的社區發布您自己的代幣。';

  @override
  String get upload => '上傳';

  @override
  String get recommendedImageSize => '推薦 200x200 像素';

  @override
  String get coinNameLabel => '代幣名稱';

  @override
  String get symbolLabel => '符號';

  @override
  String get descriptionLabel => '描述';

  @override
  String get baseMiningRateLabel => '基礎挖礦速率 (代幣/小時)';

  @override
  String maxAllowed(String max) {
    return '最大允許值 : $max';
  }

  @override
  String get socialProjectLinksOptional => '社交和項目鏈接 (可選)';

  @override
  String get linkTypeWebsite => '網站';

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
  String get linkTypeOther => '其他';

  @override
  String get pasteUrl => '粘貼 URL';

  @override
  String get importantNoticeTitle => '重要通知';

  @override
  String get importantNoticeBody =>
      '此代幣是 ETA Network 生態系統的一部分，代表參與一個不斷增長的數字社區。社區代幣由用戶創建，用於在網絡內建設、實驗和互動。ETA Network 處於早期開發階段。隨著生態系統的增長，可能會根據社區活動、平台演變和適用指南引入新的實用程序、功能和集成。';

  @override
  String get pleaseWait => '請稍候…';

  @override
  String get save => '保存';

  @override
  String createCoinFailed(String error) {
    return '創建代幣失敗: $error';
  }

  @override
  String get coinNameLengthError => '代幣名稱必須是 3-30 個字符。';

  @override
  String get symbolRequiredError => '符號是必需的。';

  @override
  String get symbolLengthError => '符號必須是 2-6 個字母/數字。';

  @override
  String get descriptionTooLongError => '描述太長。';

  @override
  String baseRateRangeError(String max) {
    return '基礎挖礦速率必須在 0.000000001 和 $max 之間。';
  }

  @override
  String get coinNameExistsError => '代幣名稱已存在。請選擇另一個。';

  @override
  String get symbolExistsError => '符號已存在。請選擇另一個。';

  @override
  String get urlInvalidError => '其中一個 URL 無效。';

  @override
  String get subscribeAndBoost => '訂閱並提升挖礦';

  @override
  String get autoCollect => '自動收集';

  @override
  String autoMineCoins(int count) {
    return '自動挖掘 $count 個代幣';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% 速度';
  }

  @override
  String get perHourSuffix => '/小時';

  @override
  String get etaPerHourSuffix => 'ETA/小時';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => '沒有可用的描述。';

  @override
  String get unknownUser => '未知';

  @override
  String get streakLabel => '連續';

  @override
  String get referralsLabel => '推薦';

  @override
  String get sessionsLabel => '會話';

  @override
  String get accountInfoSection => '帳戶信息';

  @override
  String get accountInfoTile => '帳戶信息';

  @override
  String get invitedByPrompt => '被邀請？';

  @override
  String get enterReferralCode => '輸入推薦碼';

  @override
  String get invitedStatus => '已邀請';

  @override
  String get lockedStatus => '已鎖定';

  @override
  String get applyButton => '應用';

  @override
  String get aboutPageTitle => '關於';

  @override
  String get faqTile => '常見問題';

  @override
  String get whitePaperTile => '白皮書';

  @override
  String get contactUsTile => '聯繫我們';

  @override
  String get securitySettingsTile => '安全設置';

  @override
  String get securitySettingsPageTitle => '安全設置';

  @override
  String get deleteAccountTile => '刪除帳戶';

  @override
  String get deleteAccountSubtitle => '永久刪除您的帳戶和數據';

  @override
  String get deleteAccountDialogTitle => '刪除帳戶？';

  @override
  String get deleteAccountDialogContent => '這將永久刪除您的帳戶、數據和會話。此操作無法撤消。';

  @override
  String get deleteButton => '刪除';

  @override
  String get kycVerificationTile => 'KYC 驗證';

  @override
  String get kycVerificationDialogTitle => 'KYC 驗證';

  @override
  String get kycComingSoonMessage => '將在接下來的階段激活。';

  @override
  String get okButton => '確定';

  @override
  String get logOutLabel => '登出';

  @override
  String get confirmDeletionTitle => '確認刪除';

  @override
  String get enterAccountPassword => '輸入帳戶密碼';

  @override
  String get confirmButton => '確認';

  @override
  String get usernameLabel => '用戶名';

  @override
  String get emailLabel => '電子郵件';

  @override
  String get nameLabel => '姓名';

  @override
  String get ageLabel => '年齡';

  @override
  String get countryLabel => '國家';

  @override
  String get addressLabel => '地址';

  @override
  String get genderLabel => '性別';

  @override
  String get enterUsernameHint => '輸入用戶名';

  @override
  String get enterNameHint => '輸入姓名';

  @override
  String get enterAgeHint => '輸入年齡';

  @override
  String get enterCountryHint => '輸入國家';

  @override
  String get enterAddressHint => '輸入地址';

  @override
  String get enterGenderHint => '輸入性別';

  @override
  String get savingLabel => '保存中...';

  @override
  String get usernameEmptyError => '用戶名不能為空';

  @override
  String get invalidAgeError => '無效的年齡值';

  @override
  String get saveError => '保存更改失敗';

  @override
  String get cancelButton => '取消';
}
