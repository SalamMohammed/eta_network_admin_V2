// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get totalBalance => '총 잔액';

  @override
  String joinedDate(String link, Object date) {
    return '가입일 $date';
  }

  @override
  String get inviteEarn => '초대 및 수익';

  @override
  String get shareCodeDescription => '친구들과 고유 코드를 공유하여 채굴 속도를 높이세요.';

  @override
  String get shareLink => '링크 공유';

  @override
  String get totalInvited => '총 초대';

  @override
  String get activeNow => '현재 활동 중';

  @override
  String get viewAll => '모두 보기';

  @override
  String get createCoin => '코인 만들기';

  @override
  String get mining => '채굴 중';

  @override
  String get settings => '설정';

  @override
  String get language => '언어';

  @override
  String get languageSubtitle => '앱 언어 변경';

  @override
  String get selectLanguage => '언어 선택';

  @override
  String get balanceTitle => '잔액';

  @override
  String get home => '홈';

  @override
  String get referral => '추천';

  @override
  String get profile => '프로필';

  @override
  String get dayStreak => '일 연속';

  @override
  String dayStreakValue(int count) {
    return '$count일 연속';
  }

  @override
  String get active => '활동 중';

  @override
  String get inactive => '비활동';

  @override
  String get sessionEndsIn => '세션 종료까지';

  @override
  String get startEarning => '수익 시작';

  @override
  String get loadingAd => '광고 로딩 중...';

  @override
  String waitSeconds(int seconds) {
    return '$seconds초 대기';
  }

  @override
  String rewardPlusPercent(String percent) {
    return '보상 +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => '보상형 광고를 사용할 수 없습니다';

  @override
  String rateBoosted(String rate) {
    return '속도 증가: +$rate ETA/hr';
  }

  @override
  String adBonusFailed(String message) {
    return '광고 보너스 실패: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return '속도 세부 정보: 기본 $base, 연속 +$streak, 등급 +$rank, 추천 +$referrals = $total ETA/hr';
  }

  @override
  String get unableToStartMining => '채굴을 시작할 수 없습니다. 인터넷 연결을 확인하고 다시 시도해 주세요.';

  @override
  String get createCommunityCoin => '커뮤니티 코인 만들기';

  @override
  String get launchCoinDescription => 'ETA 네트워크에서 나만의 코인을 즉시 출시하세요.';

  @override
  String get createYourOwnCoin => '나만의 코인 만들기';

  @override
  String get launchCommunityCoinDescription =>
      '다른 ETA 사용자가 채굴할 수 있는 나만의 커뮤니티 코인을 출시하세요.';

  @override
  String get editCoin => '코인 편집';

  @override
  String baseRate(String rate) {
    return '기본 속도: $rate 코인/시간';
  }

  @override
  String createdBy(String username) {
    return '제작자 @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/hr';
  }

  @override
  String get noCoinsYet => '아직 코인이 없습니다. 라이브 코인에서 추가하세요.';

  @override
  String get mine => '채굴';

  @override
  String get remaining => '남음';

  @override
  String get holders => '보유자';

  @override
  String get close => '닫기';

  @override
  String get readMore => '더 보기';

  @override
  String get readLess => '접기';

  @override
  String get projectLinks => '프로젝트 링크';

  @override
  String get verifyEmailTitle => '이메일 인증';

  @override
  String get verifyEmailMessage =>
      '이메일 주소로 인증 링크를 보냈습니다. 모든 기능을 잠금 해제하려면 계정을 인증해 주세요.';

  @override
  String get resendEmail => '이메일 재전송';

  @override
  String get iHaveVerified => '인증했습니다';

  @override
  String get logout => '로그아웃';

  @override
  String get emailVerifiedSuccess => '이메일 인증 성공!';

  @override
  String get emailNotVerified => '이메일이 아직 인증되지 않았습니다. 받은 편지함을 확인해 주세요.';

  @override
  String get verificationEmailSent => '인증 이메일 전송됨';

  @override
  String get startMining => '채굴 시작';

  @override
  String get minedCoins => '채굴된 코인';

  @override
  String get liveCoins => '라이브 코인';

  @override
  String get asset => '자산';

  @override
  String get filterStatus => '상태';

  @override
  String get filterPopular => '인기';

  @override
  String get filterNames => '이름';

  @override
  String get filterOldNew => '오래된 순 - 최신 순';

  @override
  String get filterNewOld => '최신 순 - 오래된 순';

  @override
  String startMiningWithCount(int count) {
    return '채굴 시작 ($count)';
  }

  @override
  String get clearSelection => '선택 해제';

  @override
  String get cancel => '취소';

  @override
  String get refreshStatus => '상태 새로고침';

  @override
  String get purchaseFailed => '구매 실패';

  @override
  String get securePaymentViaGooglePlay => 'Google Play를 통한 안전한 결제';

  @override
  String get addedToMinedCoins => '채굴된 코인에 추가됨';

  @override
  String failedToAdd(String message) {
    return '추가 실패: $message';
  }

  @override
  String get subscriptionsUnavailable => '구독은 Android/iOS에서만 가능합니다.';

  @override
  String get miningRate => '채굴 속도';

  @override
  String get about => '정보';

  @override
  String get yourMined => '나의 채굴량';

  @override
  String get totalMined => '총 채굴량';

  @override
  String get noReferrals => '아직 추천이 없습니다';

  @override
  String get linkCopied => '링크 복사됨';

  @override
  String get copy => '복사';

  @override
  String get howItWorks => '작동 방식';

  @override
  String get referralDescription =>
      '친구들과 코드를 공유하세요. 친구들이 가입하고 활동하면 팀이 성장하고 수익 잠재력이 향상됩니다.';

  @override
  String get yourTeam => '나의 팀';

  @override
  String get referralsTitle => '추천';

  @override
  String get shareLinkTitle => '링크 공유';

  @override
  String get copyLinkInstruction => '공유하려면 이 링크를 복사하세요:';

  @override
  String get referralCodeCopied => '추천 코드 복사됨';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network에서 함께해요! 제 코드를 사용하세요: $code $link';
  }

  @override
  String get etaNetwork => 'ETA 네트워크';

  @override
  String get noLiveCommunityCoins => '라이브 커뮤니티 코인이 없습니다';

  @override
  String get rate => '속도';

  @override
  String get filterRandom => '무작위';

  @override
  String get baseRateLabel => '기본 속도';

  @override
  String startFailed(String error) {
    return '시작 실패: $error';
  }

  @override
  String get sessionProgress => '세션 진행 상황';

  @override
  String get remainingLabel => '남음';

  @override
  String get boostRate => '부스트 속도';

  @override
  String get minedLabel => '채굴됨';

  @override
  String get noSubscriptionPlansAvailable => '이용 가능한 구독 요금제가 없습니다';

  @override
  String get subscriptionPlans => '구독 요금제';

  @override
  String get recommended => '추천';

  @override
  String get editCommunityCoin => '커뮤니티 코인 편집';

  @override
  String get launchCoinEcosystemDescription =>
      '커뮤니티를 위해 ETA 생태계 내에서 나만의 코인을 출시하세요.';

  @override
  String get upload => '업로드';

  @override
  String get recommendedImageSize => '권장 200x200px';

  @override
  String get coinNameLabel => '코인 이름';

  @override
  String get symbolLabel => '심볼';

  @override
  String get descriptionLabel => '설명';

  @override
  String get baseMiningRateLabel => '기본 채굴 속도 (코인/시간)';

  @override
  String maxAllowed(String max) {
    return '최대 허용 : $max';
  }

  @override
  String get socialProjectLinksOptional => '소셜 및 프로젝트 링크 (선택 사항)';

  @override
  String get linkTypeWebsite => '웹사이트';

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
  String get linkTypeOther => '기타';

  @override
  String get pasteUrl => 'URL 붙여넣기';

  @override
  String get importantNoticeTitle => '중요 공지';

  @override
  String get importantNoticeBody =>
      '이 코인은 ETA 네트워크 생태계의 일부이며 성장하는 디지털 커뮤니티 참여를 나타냅니다. 커뮤니티 코인은 사용자가 네트워크 내에서 구축, 실험 및 참여하기 위해 생성합니다. ETA 네트워크는 초기 개발 단계에 있습니다. 생태계가 성장함에 따라 커뮤니티 활동, 플랫폼 발전 및 적용 가능한 지침에 따라 새로운 유틸리티, 기능 및 통합이 도입될 수 있습니다.';

  @override
  String get pleaseWait => '잠시만 기다려주세요...';

  @override
  String get save => '저장';

  @override
  String createCoinFailed(String error) {
    return '코인 생성 실패: $error';
  }

  @override
  String get coinNameLengthError => '코인 이름은 3~30자여야 합니다.';

  @override
  String get symbolRequiredError => '심볼은 필수입니다.';

  @override
  String get symbolLengthError => '심볼은 2~6자의 문자/숫자여야 합니다.';

  @override
  String get descriptionTooLongError => '설명이 너무 깁니다.';

  @override
  String baseRateRangeError(String max) {
    return '기본 채굴 속도는 0.000000001에서 $max 사이여야 합니다.';
  }

  @override
  String get coinNameExistsError => '코인 이름이 이미 존재합니다. 다른 이름을 선택해 주세요.';

  @override
  String get symbolExistsError => '심볼이 이미 존재합니다. 다른 심볼을 선택해 주세요.';

  @override
  String get urlInvalidError => 'URL 중 하나가 유효하지 않습니다.';

  @override
  String get subscribeAndBoost => '구독 및 채굴 부스트';

  @override
  String get autoCollect => '자동 수집';

  @override
  String autoMineCoins(int count) {
    return '$count개 코인 자동 채굴';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% 속도';
  }

  @override
  String get perHourSuffix => '/hr';

  @override
  String get etaPerHourSuffix => 'ETA/hr';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => '설명이 없습니다.';

  @override
  String get unknownUser => '알 수 없음';

  @override
  String get streakLabel => '연속';

  @override
  String get referralsLabel => '추천';

  @override
  String get sessionsLabel => '세션';

  @override
  String get accountInfoSection => '계정 정보';

  @override
  String get accountInfoTile => '계정 정보';

  @override
  String get invitedByPrompt => '초대를 받으셨나요?';

  @override
  String get enterReferralCode => '추천 코드 입력';

  @override
  String get invitedStatus => '초대됨';

  @override
  String get lockedStatus => '잠김';

  @override
  String get applyButton => '적용';

  @override
  String get aboutPageTitle => '정보';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => '백서';

  @override
  String get contactUsTile => '문의하기';

  @override
  String get securitySettingsTile => '보안 설정';

  @override
  String get securitySettingsPageTitle => '보안 설정';

  @override
  String get deleteAccountTile => '계정 삭제';

  @override
  String get deleteAccountSubtitle => '계정 및 데이터 영구 삭제';

  @override
  String get deleteAccountDialogTitle => '계정을 삭제하시겠습니까?';

  @override
  String get deleteAccountDialogContent =>
      '이 작업은 계정, 데이터 및 세션을 영구적으로 삭제합니다. 이 작업은 되돌릴 수 없습니다.';

  @override
  String get deleteButton => '삭제';

  @override
  String get kycVerificationTile => 'KYC 인증';

  @override
  String get kycVerificationDialogTitle => 'KYC 인증';

  @override
  String get kycComingSoonMessage => '다음 단계에서 활성화될 예정입니다.';

  @override
  String get okButton => '확인';

  @override
  String get logOutLabel => '로그아웃';

  @override
  String get confirmDeletionTitle => '삭제 확인';

  @override
  String get enterAccountPassword => '계정 비밀번호 입력';

  @override
  String get confirmButton => '확인';

  @override
  String get usernameLabel => '사용자 이름';

  @override
  String get emailLabel => '이메일';

  @override
  String get nameLabel => '이름';

  @override
  String get ageLabel => '나이';

  @override
  String get countryLabel => '국가';

  @override
  String get addressLabel => '주소';

  @override
  String get genderLabel => '성별';

  @override
  String get enterUsernameHint => '사용자 이름 입력';

  @override
  String get enterNameHint => '이름 입력';

  @override
  String get enterAgeHint => '나이 입력';

  @override
  String get enterCountryHint => '국가 입력';

  @override
  String get enterAddressHint => '주소 입력';

  @override
  String get enterGenderHint => '성별 입력';

  @override
  String get savingLabel => '저장 중...';

  @override
  String get usernameEmptyError => '사용자 이름은 비워둘 수 없습니다';

  @override
  String get invalidAgeError => '유효하지 않은 나이 값';

  @override
  String get saveError => '변경 사항 저장 실패';

  @override
  String get cancelButton => '취소';
}
