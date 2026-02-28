// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get totalBalance => 'Tổng số dư';

  @override
  String joinedDate(String link, Object date) {
    return 'Đã tham gia $date';
  }

  @override
  String get inviteEarn => 'Mời & Kiếm tiền';

  @override
  String get shareCodeDescription =>
      'Chia sẻ mã duy nhất của bạn với bạn bè để tăng tốc độ khai thác của bạn.';

  @override
  String get shareLink => 'Chia sẻ liên kết';

  @override
  String get totalInvited => 'Tổng số đã mời';

  @override
  String get activeNow => 'Đang hoạt động';

  @override
  String get viewAll => 'Xem tất cả';

  @override
  String get createCoin => 'Tạo Coin';

  @override
  String get mining => 'Đang khai thác';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageSubtitle => 'Thay đổi ngôn ngữ ứng dụng';

  @override
  String get selectLanguage => 'Chọn ngôn ngữ';

  @override
  String get balanceTitle => 'Số dư';

  @override
  String get home => 'Trang chủ';

  @override
  String get referral => 'Giới thiệu';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get dayStreak => 'Chuỗi ngày';

  @override
  String dayStreakValue(int count) {
    return 'Chuỗi $count ngày';
  }

  @override
  String get active => 'Hoạt động';

  @override
  String get inactive => 'Không hoạt động';

  @override
  String get sessionEndsIn => 'Phiên kết thúc trong';

  @override
  String get startEarning => 'Bắt đầu kiếm tiền';

  @override
  String get loadingAd => 'Đang tải quảng cáo...';

  @override
  String waitSeconds(int seconds) {
    return 'Chờ $seconds giây';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Phần thưởng +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Quảng cáo có thưởng không khả dụng';

  @override
  String rateBoosted(String rate) {
    return 'Tăng tốc độ: +$rate ETA/giờ';
  }

  @override
  String adBonusFailed(String message) {
    return 'Thưởng quảng cáo thất bại: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Chi tiết tốc độ: Cơ bản $base, Chuỗi +$streak, Hạng +$rank, Giới thiệu +$referrals = $total ETA/giờ';
  }

  @override
  String get unableToStartMining =>
      'Không thể bắt đầu khai thác. Vui lòng kiểm tra kết nối internet và thử lại.';

  @override
  String get createCommunityCoin => 'Tạo Coin cộng đồng';

  @override
  String get launchCoinDescription =>
      'Ra mắt coin của riêng bạn trên Mạng ETA ngay lập tức.';

  @override
  String get createYourOwnCoin => 'Tạo coin của riêng bạn';

  @override
  String get launchCommunityCoinDescription =>
      'Ra mắt coin cộng đồng của riêng bạn mà người dùng ETA khác có thể khai thác.';

  @override
  String get editCoin => 'Chỉnh sửa coin';

  @override
  String baseRate(String rate) {
    return 'Tốc độ cơ bản: $rate coin/giờ';
  }

  @override
  String createdBy(String username) {
    return 'Được tạo bởi @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/giờ';
  }

  @override
  String get noCoinsYet => 'Chưa có coin nào. Thêm từ Coin trực tiếp.';

  @override
  String get mine => 'Khai thác';

  @override
  String get remaining => 'còn lại';

  @override
  String get holders => 'Người nắm giữ';

  @override
  String get close => 'Đóng';

  @override
  String get readMore => 'Đọc thêm';

  @override
  String get readLess => 'Thu gọn';

  @override
  String get projectLinks => 'Liên kết dự án';

  @override
  String get verifyEmailTitle => 'Xác minh email của bạn';

  @override
  String get verifyEmailMessage =>
      'Chúng tôi đã gửi liên kết xác minh đến địa chỉ email của bạn. Vui lòng xác minh tài khoản để mở khóa tất cả tính năng.';

  @override
  String get resendEmail => 'Gửi lại email';

  @override
  String get iHaveVerified => 'Tôi đã xác minh';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get emailVerifiedSuccess => 'Email đã được xác minh thành công!';

  @override
  String get emailNotVerified =>
      'Email chưa được xác minh. Vui lòng kiểm tra hộp thư đến của bạn.';

  @override
  String get verificationEmailSent => 'Đã gửi email xác minh';

  @override
  String get startMining => 'Bắt đầu khai thác';

  @override
  String get minedCoins => 'Coin đã khai thác';

  @override
  String get liveCoins => 'Coin trực tiếp';

  @override
  String get asset => 'Tài sản';

  @override
  String get filterStatus => 'Trạng thái';

  @override
  String get filterPopular => 'Phổ biến';

  @override
  String get filterNames => 'Tên';

  @override
  String get filterOldNew => 'Cũ - Mới';

  @override
  String get filterNewOld => 'Mới - Cũ';

  @override
  String startMiningWithCount(int count) {
    return 'Bắt đầu khai thác ($count)';
  }

  @override
  String get clearSelection => 'Xóa lựa chọn';

  @override
  String get cancel => 'Hủy';

  @override
  String get refreshStatus => 'Làm mới trạng thái';

  @override
  String get purchaseFailed => 'Giao dịch thất bại';

  @override
  String get securePaymentViaGooglePlay => 'Thanh toán an toàn qua Google Play';

  @override
  String get addedToMinedCoins => 'Đã thêm vào Coin đã khai thác';

  @override
  String failedToAdd(String message) {
    return 'Thêm thất bại: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Đăng ký chỉ khả dụng trên Android/iOS.';

  @override
  String get miningRate => 'Tốc độ khai thác';

  @override
  String get about => 'Giới thiệu';

  @override
  String get yourMined => 'Bạn đã khai thác';

  @override
  String get totalMined => 'Tổng đã khai thác';

  @override
  String get noReferrals => 'Chưa có giới thiệu nào';

  @override
  String get linkCopied => 'Đã sao chép liên kết';

  @override
  String get copy => 'Sao chép';

  @override
  String get howItWorks => 'Cách hoạt động';

  @override
  String get referralDescription =>
      'Chia sẻ mã của bạn với bạn bè. Khi họ tham gia và hoạt động, đội của bạn sẽ phát triển và tiềm năng kiếm tiền của bạn được cải thiện.';

  @override
  String get yourTeam => 'Đội của bạn';

  @override
  String get referralsTitle => 'Giới thiệu';

  @override
  String get shareLinkTitle => 'Chia sẻ liên kết';

  @override
  String get copyLinkInstruction => 'Sao chép liên kết này để chia sẻ:';

  @override
  String get referralCodeCopied => 'Đã sao chép mã giới thiệu';

  @override
  String joinMeText(String code, String link) {
    return 'Tham gia cùng tôi trên Mạng Eta! Sử dụng mã của tôi: $code $link';
  }

  @override
  String get etaNetwork => 'Mạng ETA';

  @override
  String get noLiveCommunityCoins => 'Không có coin cộng đồng trực tiếp';

  @override
  String get rate => 'Tốc độ';

  @override
  String get filterRandom => 'Ngẫu nhiên';

  @override
  String get baseRateLabel => 'Tốc độ cơ bản';

  @override
  String startFailed(String error) {
    return 'Khởi động thất bại: $error';
  }

  @override
  String get sessionProgress => 'Tiến trình phiên';

  @override
  String get remainingLabel => 'còn lại';

  @override
  String get boostRate => 'Tốc độ tăng cường';

  @override
  String get minedLabel => 'Đã khai thác';

  @override
  String get noSubscriptionPlansAvailable => 'Không có gói đăng ký nào';

  @override
  String get subscriptionPlans => 'Gói đăng ký';

  @override
  String get recommended => 'Được đề xuất';

  @override
  String get editCommunityCoin => 'Chỉnh sửa Coin cộng đồng';

  @override
  String get launchCoinEcosystemDescription =>
      'Ra mắt coin của riêng bạn bên trong hệ sinh thái ETA cho cộng đồng của bạn.';

  @override
  String get upload => 'Tải lên';

  @override
  String get recommendedImageSize => 'Khuyến nghị 200x200px';

  @override
  String get coinNameLabel => 'Tên coin';

  @override
  String get symbolLabel => 'Ký hiệu';

  @override
  String get descriptionLabel => 'Mô tả';

  @override
  String get baseMiningRateLabel => 'Tốc độ khai thác cơ bản (coin/giờ)';

  @override
  String maxAllowed(String max) {
    return 'Tối đa cho phép : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Liên kết xã hội & dự án (tùy chọn)';

  @override
  String get linkTypeWebsite => 'Trang web';

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
  String get linkTypeOther => 'Khác';

  @override
  String get pasteUrl => 'Dán URL';

  @override
  String get importantNoticeTitle => 'Thông báo quan trọng';

  @override
  String get importantNoticeBody =>
      'Coin này là một phần của hệ sinh thái Mạng ETA và đại diện cho sự tham gia vào một cộng đồng kỹ thuật số đang phát triển. Coin cộng đồng được tạo ra bởi người dùng để xây dựng, thử nghiệm và tham gia trong mạng lưới. Mạng ETA đang ở giai đoạn đầu phát triển. Khi hệ sinh thái phát triển, các tiện ích, tính năng và tích hợp mới có thể được giới thiệu dựa trên hoạt động cộng đồng, sự phát triển của nền tảng và các hướng dẫn áp dụng.';

  @override
  String get pleaseWait => 'Vui lòng đợi...';

  @override
  String get save => 'Lưu';

  @override
  String createCoinFailed(String error) {
    return 'Tạo coin thất bại: $error';
  }

  @override
  String get coinNameLengthError => 'Tên coin phải từ 3-30 ký tự.';

  @override
  String get symbolRequiredError => 'Ký hiệu là bắt buộc.';

  @override
  String get symbolLengthError => 'Ký hiệu phải từ 2-6 chữ cái/số.';

  @override
  String get descriptionTooLongError => 'Mô tả quá dài.';

  @override
  String baseRateRangeError(String max) {
    return 'Tốc độ khai thác cơ bản phải từ 0.000000001 đến $max.';
  }

  @override
  String get coinNameExistsError =>
      'Tên coin đã tồn tại. Vui lòng chọn tên khác.';

  @override
  String get symbolExistsError =>
      'Ký hiệu đã tồn tại. Vui lòng chọn ký hiệu khác.';

  @override
  String get urlInvalidError => 'Một trong các URL không hợp lệ.';

  @override
  String get subscribeAndBoost => 'Đăng ký & Tăng tốc khai thác';

  @override
  String get autoCollect => 'Tự động thu thập';

  @override
  String autoMineCoins(int count) {
    return 'Tự động khai thác $count coin';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Tốc độ';
  }

  @override
  String get perHourSuffix => '/giờ';

  @override
  String get etaPerHourSuffix => 'ETA/giờ';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Không có mô tả.';

  @override
  String get unknownUser => 'Không xác định';

  @override
  String get streakLabel => 'CHUỖI';

  @override
  String get referralsLabel => 'GIỚI THIỆU';

  @override
  String get sessionsLabel => 'PHIÊN';

  @override
  String get accountInfoSection => 'Thông tin tài khoản';

  @override
  String get accountInfoTile => 'Thông tin tài khoản';

  @override
  String get invitedByPrompt => 'Được mời bởi ai đó?';

  @override
  String get enterReferralCode => 'Nhập mã giới thiệu';

  @override
  String get invitedStatus => 'Đã được mời';

  @override
  String get lockedStatus => 'Đã khóa';

  @override
  String get applyButton => 'Áp dụng';

  @override
  String get aboutPageTitle => 'Giới thiệu';

  @override
  String get faqTile => 'Câu hỏi thường gặp';

  @override
  String get whitePaperTile => 'Sách trắng';

  @override
  String get contactUsTile => 'Liên hệ với chúng tôi';

  @override
  String get securitySettingsTile => 'Cài đặt bảo mật';

  @override
  String get securitySettingsPageTitle => 'Cài đặt bảo mật';

  @override
  String get deleteAccountTile => 'Xóa tài khoản';

  @override
  String get deleteAccountSubtitle =>
      'Xóa vĩnh viễn tài khoản và dữ liệu của bạn';

  @override
  String get deleteAccountDialogTitle => 'Xóa tài khoản?';

  @override
  String get deleteAccountDialogContent =>
      'Hành động này sẽ xóa vĩnh viễn tài khoản, dữ liệu và các phiên của bạn. Hành động này không thể hoàn tác.';

  @override
  String get deleteButton => 'Xóa';

  @override
  String get kycVerificationTile => 'Xác minh KYC';

  @override
  String get kycVerificationDialogTitle => 'Xác minh KYC';

  @override
  String get kycComingSoonMessage =>
      'Sẽ được kích hoạt trong các giai đoạn tới.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Đăng xuất';

  @override
  String get confirmDeletionTitle => 'Xác nhận xóa';

  @override
  String get enterAccountPassword => 'Nhập mật khẩu tài khoản';

  @override
  String get confirmButton => 'Xác nhận';

  @override
  String get usernameLabel => 'Tên người dùng';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Tên';

  @override
  String get ageLabel => 'Tuổi';

  @override
  String get countryLabel => 'Quốc gia';

  @override
  String get addressLabel => 'Địa chỉ';

  @override
  String get genderLabel => 'Giới tính';

  @override
  String get enterUsernameHint => 'Nhập tên người dùng';

  @override
  String get enterNameHint => 'Nhập tên';

  @override
  String get enterAgeHint => 'Nhập tuổi';

  @override
  String get enterCountryHint => 'Nhập quốc gia';

  @override
  String get enterAddressHint => 'Nhập địa chỉ';

  @override
  String get enterGenderHint => 'Nhập giới tính';

  @override
  String get savingLabel => 'Đang lưu...';

  @override
  String get usernameEmptyError => 'Tên người dùng không được để trống';

  @override
  String get invalidAgeError => 'Giá trị tuổi không hợp lệ';

  @override
  String get saveError => 'Không thể lưu thay đổi';

  @override
  String get cancelButton => 'Hủy';
}
