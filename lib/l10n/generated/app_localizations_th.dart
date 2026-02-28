// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get totalBalance => 'ยอดรวม';

  @override
  String joinedDate(String link, Object date) {
    return 'เข้าร่วมเมื่อ $date';
  }

  @override
  String get inviteEarn => 'เชิญเพื่อน & รับรางวัล';

  @override
  String get shareCodeDescription =>
      'แบ่งปันรหัสของคุณกับเพื่อนเพื่อเพิ่มอัตราการขุดของคุณ';

  @override
  String get shareLink => 'แชร์ลิงก์';

  @override
  String get totalInvited => 'เชิญทั้งหมด';

  @override
  String get activeNow => 'ใช้งานอยู่ตอนนี้';

  @override
  String get viewAll => 'ดูทั้งหมด';

  @override
  String get createCoin => 'สร้างเหรียญ';

  @override
  String get mining => 'การขุด';

  @override
  String get settings => 'การตั้งค่า';

  @override
  String get language => 'ภาษา';

  @override
  String get languageSubtitle => 'เปลี่ยนภาษาของแอป';

  @override
  String get selectLanguage => 'เลือกภาษา';

  @override
  String get balanceTitle => 'ยอดคงเหลือ';

  @override
  String get home => 'หน้าแรก';

  @override
  String get referral => 'การแนะนำ';

  @override
  String get profile => 'โปรไฟล์';

  @override
  String get dayStreak => 'สตรีควัน';

  @override
  String dayStreakValue(int count) {
    return '$count วันต่อเนื่อง';
  }

  @override
  String get active => 'ใช้งานอยู่';

  @override
  String get inactive => 'ไม่ใช้งาน';

  @override
  String get sessionEndsIn => 'เซสชันสิ้นสุดใน';

  @override
  String get startEarning => 'เริ่มสร้างรายได้';

  @override
  String get loadingAd => 'กำลังโหลดโฆษณา...';

  @override
  String waitSeconds(int seconds) {
    return 'รอ $seconds วินาที';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'รางวัล +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'ไม่มีโฆษณารางวัล';

  @override
  String rateBoosted(String rate) {
    return 'เพิ่มอัตรา: +$rate ETA/ชม.';
  }

  @override
  String adBonusFailed(String message) {
    return 'โบนัสโฆษณาล้มเหลว: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'รายละเอียดอัตรา: ฐาน $base, สตรีค +$streak, ระดับ +$rank, การแนะนำ +$referrals = $total ETA/ชม.';
  }

  @override
  String get unableToStartMining =>
      'ไม่สามารถเริ่มขุดได้ โปรดตรวจสอบการเชื่อมต่ออินเทอร์เน็ตและลองอีกครั้ง';

  @override
  String get createCommunityCoin => 'สร้างเหรียญชุมชน';

  @override
  String get launchCoinDescription =>
      'เปิดตัวเหรียญของคุณเองบนเครือข่าย ETA ทันที';

  @override
  String get createYourOwnCoin => 'สร้างเหรียญของคุณเอง';

  @override
  String get launchCommunityCoinDescription =>
      'เปิดตัวเหรียญชุมชนของคุณเองที่ผู้ใช้ ETA คนอื่นสามารถขุดได้';

  @override
  String get editCoin => 'แก้ไขเหรียญ';

  @override
  String baseRate(String rate) {
    return 'อัตราพื้นฐาน: $rate เหรียญ/ชั่วโมง';
  }

  @override
  String createdBy(String username) {
    return 'สร้างโดย @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/ชม.';
  }

  @override
  String get noCoinsYet => 'ยังไม่มีเหรียญ เพิ่มจากเหรียญสด';

  @override
  String get mine => 'ขุด';

  @override
  String get remaining => 'เหลือ';

  @override
  String get holders => 'ผู้ถือ';

  @override
  String get close => 'ปิด';

  @override
  String get readMore => 'อ่านเพิ่มเติม';

  @override
  String get readLess => 'ย่อลง';

  @override
  String get projectLinks => 'ลิงก์โครงการ';

  @override
  String get verifyEmailTitle => 'ยืนยันอีเมลของคุณ';

  @override
  String get verifyEmailMessage =>
      'เราได้ส่งลิงก์ยืนยันไปยังอีเมลของคุณแล้ว โปรดยืนยันบัญชีของคุณเพื่อปลดล็อกคุณสมบัติทั้งหมด';

  @override
  String get resendEmail => 'ส่งอีเมลซ้ำ';

  @override
  String get iHaveVerified => 'ฉันได้ยืนยันแล้ว';

  @override
  String get logout => 'ออกจากระบบ';

  @override
  String get emailVerifiedSuccess => 'ยืนยันอีเมลสำเร็จ!';

  @override
  String get emailNotVerified =>
      'อีเมลยังไม่ได้รับการยืนยัน โปรดตรวจสอบกล่องจดหมายของคุณ';

  @override
  String get verificationEmailSent => 'ส่งอีเมลยืนยันแล้ว';

  @override
  String get startMining => 'เริ่มขุด';

  @override
  String get minedCoins => 'เหรียญที่ขุดได้';

  @override
  String get liveCoins => 'เหรียญสด';

  @override
  String get asset => 'สินทรัพย์';

  @override
  String get filterStatus => 'สถานะ';

  @override
  String get filterPopular => 'ยอดนิยม';

  @override
  String get filterNames => 'ชื่อ';

  @override
  String get filterOldNew => 'เก่า - ใหม่';

  @override
  String get filterNewOld => 'ใหม่ - เก่า';

  @override
  String startMiningWithCount(int count) {
    return 'เริ่มขุด ($count)';
  }

  @override
  String get clearSelection => 'ล้างการเลือก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get refreshStatus => 'รีเฟรชสถานะ';

  @override
  String get purchaseFailed => 'การซื้อล้มเหลว';

  @override
  String get securePaymentViaGooglePlay =>
      'การชำระเงินที่ปลอดภัยผ่าน Google Play';

  @override
  String get addedToMinedCoins => 'เพิ่มไปยังเหรียญที่ขุดได้';

  @override
  String failedToAdd(String message) {
    return 'ไม่สามารถเพิ่มได้: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'การสมัครสมาชิกใช้ได้เฉพาะบน Android/iOS';

  @override
  String get miningRate => 'อัตราการขุด';

  @override
  String get about => 'เกี่ยวกับ';

  @override
  String get yourMined => 'ที่คุณขุดได้';

  @override
  String get totalMined => 'ขุดได้ทั้งหมด';

  @override
  String get noReferrals => 'ยังไม่มีการแนะนำ';

  @override
  String get linkCopied => 'คัดลอกลิงก์แล้ว';

  @override
  String get copy => 'คัดลอก';

  @override
  String get howItWorks => 'วิธีการทำงาน';

  @override
  String get referralDescription =>
      'แบ่งปันรหัสของคุณกับเพื่อน เมื่อพวกเขาเข้าร่วมและใช้งาน คุณจะสร้างทีมและเพิ่มโอกาสในการสร้างรายได้';

  @override
  String get yourTeam => 'ทีมของคุณ';

  @override
  String get referralsTitle => 'การแนะนำ';

  @override
  String get shareLinkTitle => 'แชร์ลิงก์';

  @override
  String get copyLinkInstruction => 'คัดลอกลิงก์นี้เพื่อแชร์:';

  @override
  String get referralCodeCopied => 'คัดลอกรหัสแนะนำแล้ว';

  @override
  String joinMeText(String code, String link) {
    return 'เข้าร่วมกับฉันใน Eta Network! ใช้รหัสของฉัน: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Network';

  @override
  String get noLiveCommunityCoins => 'ไม่มีเหรียญชุมชนสด';

  @override
  String get rate => 'อัตรา';

  @override
  String get filterRandom => 'สุ่ม';

  @override
  String get baseRateLabel => 'อัตราพื้นฐาน';

  @override
  String startFailed(String error) {
    return 'เริ่มล้มเหลว: $error';
  }

  @override
  String get sessionProgress => 'ความคืบหน้าของเซสชัน';

  @override
  String get remainingLabel => 'เหลือ';

  @override
  String get boostRate => 'อัตราเพิ่ม';

  @override
  String get minedLabel => 'ขุดได้';

  @override
  String get noSubscriptionPlansAvailable => 'ไม่มีแผนการสมัครสมาชิก';

  @override
  String get subscriptionPlans => 'แผนการสมัครสมาชิก';

  @override
  String get recommended => 'แนะนำ';

  @override
  String get editCommunityCoin => 'แก้ไขเหรียญชุมชน';

  @override
  String get launchCoinEcosystemDescription =>
      'เปิดตัวเหรียญของคุณภายในระบบนิเวศ ETA สำหรับชุมชนของคุณ';

  @override
  String get upload => 'อัปโหลด';

  @override
  String get recommendedImageSize => 'แนะนำ 200×200px';

  @override
  String get coinNameLabel => 'ชื่อเหรียญ';

  @override
  String get symbolLabel => 'สัญลักษณ์';

  @override
  String get descriptionLabel => 'คำอธิบาย';

  @override
  String get baseMiningRateLabel => 'อัตราการขุดพื้นฐาน (เหรียญ/ชั่วโมง)';

  @override
  String maxAllowed(String max) {
    return 'สูงสุดที่อนุญาต : $max';
  }

  @override
  String get socialProjectLinksOptional => 'ลิงก์โซเชียลและโครงการ (ไม่บังคับ)';

  @override
  String get linkTypeWebsite => 'เว็บไซต์';

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
  String get linkTypeOther => 'อื่นๆ';

  @override
  String get pasteUrl => 'วาง URL';

  @override
  String get importantNoticeTitle => 'ประกาศสำคัญ';

  @override
  String get importantNoticeBody =>
      'เหรียญนี้เป็นส่วนหนึ่งของระบบนิเวศ ETA Network และแสดงถึงการมีส่วนร่วมในชุมชนดิจิทัลที่กำลังเติบโต เหรียญชุมชนถูกสร้างขึ้นโดยผู้ใช้เพื่อสร้าง ทดลอง และมีส่วนร่วมภายในเครือข่าย ETA Network อยู่ในช่วงเริ่มต้นของการพัฒนา เมื่อระบบนิเวศเติบโตขึ้น อาจมีการแนะนำยูทิลิตี้ คุณสมบัติ และการรวมระบบใหม่ตามกิจกรรมของชุมชน วิวัฒนาการของแพลตฟอร์ม และแนวทางที่เกี่ยวข้อง';

  @override
  String get pleaseWait => 'โปรดรอ...';

  @override
  String get save => 'บันทึก';

  @override
  String createCoinFailed(String error) {
    return 'สร้างเหรียญล้มเหลว: $error';
  }

  @override
  String get coinNameLengthError => 'ชื่อเหรียญต้องมี 3–30 ตัวอักษร';

  @override
  String get symbolRequiredError => 'จำเป็นต้องมีสัญลักษณ์';

  @override
  String get symbolLengthError => 'สัญลักษณ์ต้องมี 2–6 ตัวอักษร/ตัวเลข';

  @override
  String get descriptionTooLongError => 'คำอธิบายยาวเกินไป';

  @override
  String baseRateRangeError(String max) {
    return 'อัตราการขุดพื้นฐานต้องอยู่ระหว่าง 0.000000001 ถึง $max';
  }

  @override
  String get coinNameExistsError => 'ชื่อเหรียญมีอยู่แล้ว โปรดเลือกชื่ออื่น';

  @override
  String get symbolExistsError => 'สัญลักษณ์มีอยู่แล้ว โปรดเลือกสัญลักษณ์อื่น';

  @override
  String get urlInvalidError => 'หนึ่งใน URL ไม่ถูกต้อง';

  @override
  String get subscribeAndBoost => 'สมัครสมาชิกและเพิ่มการขุด';

  @override
  String get autoCollect => 'รวบรวมอัตโนมัติ';

  @override
  String autoMineCoins(int count) {
    return 'ขุดอัตโนมัติ $count เหรียญ';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% ความเร็ว';
  }

  @override
  String get perHourSuffix => '/ชม.';

  @override
  String get etaPerHourSuffix => 'ETA/ชม.';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'ไม่มีคำอธิบาย';

  @override
  String get unknownUser => 'ไม่ทราบ';

  @override
  String get streakLabel => 'สตรีค';

  @override
  String get referralsLabel => 'การแนะนำ';

  @override
  String get sessionsLabel => 'เซสชัน';

  @override
  String get accountInfoSection => 'ข้อมูลบัญชี';

  @override
  String get accountInfoTile => 'ข้อมูลบัญชี';

  @override
  String get invitedByPrompt => 'ได้รับเชิญจากใคร?';

  @override
  String get enterReferralCode => 'ป้อนรหัสแนะนำ';

  @override
  String get invitedStatus => 'ได้รับเชิญ';

  @override
  String get lockedStatus => 'ล็อค';

  @override
  String get applyButton => 'นำไปใช้';

  @override
  String get aboutPageTitle => 'เกี่ยวกับ';

  @override
  String get faqTile => 'คำถามที่พบบ่อย';

  @override
  String get whitePaperTile => 'สมุดปกขาว';

  @override
  String get contactUsTile => 'ติดต่อเรา';

  @override
  String get securitySettingsTile => 'การตั้งค่าความปลอดภัย';

  @override
  String get securitySettingsPageTitle => 'การตั้งค่าความปลอดภัย';

  @override
  String get deleteAccountTile => 'ลบบัญชี';

  @override
  String get deleteAccountSubtitle => 'ลบบัญชีและข้อมูลของคุณอย่างถาวร';

  @override
  String get deleteAccountDialogTitle => 'ลบบัญชี?';

  @override
  String get deleteAccountDialogContent =>
      'สิ่งนี้จะลบบัญชี ข้อมูล และเซสชันของคุณอย่างถาวร การดำเนินการนี้ไม่สามารถยกเลิกได้';

  @override
  String get deleteButton => 'ลบ';

  @override
  String get kycVerificationTile => 'การยืนยัน KYC';

  @override
  String get kycVerificationDialogTitle => 'การยืนยัน KYC';

  @override
  String get kycComingSoonMessage => 'จะเปิดใช้งานในขั้นตอนถัดไป';

  @override
  String get okButton => 'ตกลง';

  @override
  String get logOutLabel => 'ออกจากระบบ';

  @override
  String get confirmDeletionTitle => 'ยืนยันการลบ';

  @override
  String get enterAccountPassword => 'ป้อนรหัสผ่านบัญชี';

  @override
  String get confirmButton => 'ยืนยัน';

  @override
  String get usernameLabel => 'ชื่อผู้ใช้';

  @override
  String get emailLabel => 'อีเมล';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String get ageLabel => 'อายุ';

  @override
  String get countryLabel => 'ประเทศ';

  @override
  String get addressLabel => 'ที่อยู่';

  @override
  String get genderLabel => 'เพศ';

  @override
  String get enterUsernameHint => 'ป้อนชื่อผู้ใช้';

  @override
  String get enterNameHint => 'ป้อนชื่อ';

  @override
  String get enterAgeHint => 'ป้อนอายุ';

  @override
  String get enterCountryHint => 'ป้อนประเทศ';

  @override
  String get enterAddressHint => 'ป้อนที่อยู่';

  @override
  String get enterGenderHint => 'ป้อนเพศ';

  @override
  String get savingLabel => 'กำลังบันทึก...';

  @override
  String get usernameEmptyError => 'ชื่อผู้ใช้ต้องไม่ว่างเปล่า';

  @override
  String get invalidAgeError => 'ค่าอายุไม่ถูกต้อง';

  @override
  String get saveError => 'บันทึกการเปลี่ยนแปลงล้มเหลว';

  @override
  String get cancelButton => 'ยกเลิก';
}
