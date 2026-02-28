// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get totalBalance => 'Toplam Bakiye';

  @override
  String joinedDate(String link, Object date) {
    return 'Katılma Tarihi $date';
  }

  @override
  String get inviteEarn => 'Davet Et & Kazan';

  @override
  String get shareCodeDescription =>
      'Madencilik hızınızı artırmak için benzersiz kodunuzu arkadaşlarınızla paylaşın.';

  @override
  String get shareLink => 'Bağlantıyı Paylaş';

  @override
  String get totalInvited => 'TOPLAM DAVET';

  @override
  String get activeNow => 'ŞU AN AKTİF';

  @override
  String get viewAll => 'Hepsini Gör';

  @override
  String get createCoin => 'Coin Oluştur';

  @override
  String get mining => 'Madencilik';

  @override
  String get settings => 'Ayarlar';

  @override
  String get language => 'Dil';

  @override
  String get languageSubtitle => 'Uygulama dilini değiştir';

  @override
  String get selectLanguage => 'Dil Seçin';

  @override
  String get balanceTitle => 'Bakiye';

  @override
  String get home => 'Ana Sayfa';

  @override
  String get referral => 'Referans';

  @override
  String get profile => 'Profil';

  @override
  String get dayStreak => 'Gün Serisi';

  @override
  String dayStreakValue(int count) {
    return '$count Gün Serisi';
  }

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Pasif';

  @override
  String get sessionEndsIn => 'Oturum bitiş süresi';

  @override
  String get startEarning => 'Kazanmaya Başla';

  @override
  String get loadingAd => 'Reklam yükleniyor...';

  @override
  String waitSeconds(int seconds) {
    return '${seconds}s bekle';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Ödül +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Ödüllü reklam mevcut değil';

  @override
  String rateBoosted(String rate) {
    return 'Hız artırıldı: +$rate ETA/saat';
  }

  @override
  String adBonusFailed(String message) {
    return 'Reklam bonusu başarısız: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Hız dökümü: Temel $base, Seri +$streak, Rütbe +$rank, Referanslar +$referrals = $total ETA/saat';
  }

  @override
  String get unableToStartMining =>
      'Madencilik başlatılamıyor. Lütfen internet bağlantınızı kontrol edip tekrar deneyin.';

  @override
  String get createCommunityCoin => 'Topluluk Coini Oluştur';

  @override
  String get launchCoinDescription =>
      'Kendi coin\'inizi ETA Ağında anında başlatın.';

  @override
  String get createYourOwnCoin => 'Kendi coin\'inizi oluşturun';

  @override
  String get launchCommunityCoinDescription =>
      'Diğer ETA kullanıcılarının kazabileceği kendi topluluk coin\'inizi başlatın.';

  @override
  String get editCoin => 'Coin\'i düzenle';

  @override
  String baseRate(String rate) {
    return 'Temel hız: $rate coin/saat';
  }

  @override
  String createdBy(String username) {
    return '@$username tarafından oluşturuldu';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/saat';
  }

  @override
  String get noCoinsYet => 'Henüz coin yok. Canlı Coinlerden ekleyin.';

  @override
  String get mine => 'Kaz';

  @override
  String get remaining => 'kalan';

  @override
  String get holders => 'Sahipler';

  @override
  String get close => 'Kapat';

  @override
  String get readMore => 'Daha Fazla Oku';

  @override
  String get readLess => 'Daha Az Oku';

  @override
  String get projectLinks => 'Proje Bağlantıları';

  @override
  String get verifyEmailTitle => 'E-postanızı Doğrulayın';

  @override
  String get verifyEmailMessage =>
      'E-posta adresinize bir doğrulama bağlantısı gönderdik. Tüm özelliklerin kilidini açmak için lütfen hesabınızı doğrulayın.';

  @override
  String get resendEmail => 'E-postayı Tekrar Gönder';

  @override
  String get iHaveVerified => 'Doğruladım';

  @override
  String get logout => 'Çıkış Yap';

  @override
  String get emailVerifiedSuccess => 'E-posta başarıyla doğrulandı!';

  @override
  String get emailNotVerified =>
      'E-posta henüz doğrulanmadı. Lütfen gelen kutunuzu kontrol edin.';

  @override
  String get verificationEmailSent => 'Doğrulama e-postası gönderildi';

  @override
  String get startMining => 'Madenciliği Başlat';

  @override
  String get minedCoins => 'Kazılan Coinler';

  @override
  String get liveCoins => 'Canlı Coinler';

  @override
  String get asset => 'Varlık';

  @override
  String get filterStatus => 'Durum';

  @override
  String get filterPopular => 'Popüler';

  @override
  String get filterNames => 'İsimler';

  @override
  String get filterOldNew => 'Eski - Yeni';

  @override
  String get filterNewOld => 'Yeni - Eski';

  @override
  String startMiningWithCount(int count) {
    return 'Madenciliği Başlat ($count)';
  }

  @override
  String get clearSelection => 'Seçimi Temizle';

  @override
  String get cancel => 'İptal';

  @override
  String get refreshStatus => 'Durumu Yenile';

  @override
  String get purchaseFailed => 'Satın alma başarısız';

  @override
  String get securePaymentViaGooglePlay => 'Google Play ile güvenli ödeme';

  @override
  String get addedToMinedCoins => 'Kazılan Coinlere Eklendi';

  @override
  String failedToAdd(String message) {
    return 'Ekleme başarısız: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Abonelikler yalnızca Android/iOS\'ta mevcuttur.';

  @override
  String get miningRate => 'Madencilik hızı';

  @override
  String get about => 'Hakkında';

  @override
  String get yourMined => 'Sizin Kazdığınız';

  @override
  String get totalMined => 'Toplam Kazılan';

  @override
  String get noReferrals => 'Henüz referans yok';

  @override
  String get linkCopied => 'Bağlantı kopyalandı';

  @override
  String get copy => 'Kopyala';

  @override
  String get howItWorks => 'Nasıl çalışır';

  @override
  String get referralDescription =>
      'Kodunuzu arkadaşlarınızla paylaşın. Katılıp aktif olduklarında ekibiniz büyür ve kazanç potansiyeliniz artar.';

  @override
  String get yourTeam => 'Ekibiniz';

  @override
  String get referralsTitle => 'Referanslar';

  @override
  String get shareLinkTitle => 'Bağlantıyı Paylaş';

  @override
  String get copyLinkInstruction => 'Paylaşmak için bu bağlantıyı kopyalayın:';

  @override
  String get referralCodeCopied => 'Referans kodu kopyalandı';

  @override
  String joinMeText(String code, String link) {
    return 'Eta Network\'te bana katıl! Kodumu kullan: $code $link';
  }

  @override
  String get etaNetwork => 'ETA Ağı';

  @override
  String get noLiveCommunityCoins => 'Canlı topluluk coini yok';

  @override
  String get rate => 'HIZ';

  @override
  String get filterRandom => 'Rastgele';

  @override
  String get baseRateLabel => 'Temel Hız';

  @override
  String startFailed(String error) {
    return 'Başlatma başarısız: $error';
  }

  @override
  String get sessionProgress => 'Oturum İlerlemesi';

  @override
  String get remainingLabel => 'kalan';

  @override
  String get boostRate => 'Hız Artışı';

  @override
  String get minedLabel => 'Kazıldı';

  @override
  String get noSubscriptionPlansAvailable => 'Mevcut abonelik planı yok';

  @override
  String get subscriptionPlans => 'Abonelik Planları';

  @override
  String get recommended => 'Önerilen';

  @override
  String get editCommunityCoin => 'Topluluk Coinini Düzenle';

  @override
  String get launchCoinEcosystemDescription =>
      'Topluluğunuz için ETA ekosistemi içinde kendi coin\'inizi başlatın.';

  @override
  String get upload => 'Yükle';

  @override
  String get recommendedImageSize => 'Önerilen 200x200px';

  @override
  String get coinNameLabel => 'Coin adı';

  @override
  String get symbolLabel => 'Sembol';

  @override
  String get descriptionLabel => 'Açıklama';

  @override
  String get baseMiningRateLabel => 'Temel madencilik hızı (coin/saat)';

  @override
  String maxAllowed(String max) {
    return 'İzin Verilen Maksimum : $max';
  }

  @override
  String get socialProjectLinksOptional =>
      'Sosyal & proje bağlantıları (isteğe bağlı)';

  @override
  String get linkTypeWebsite => 'Web Sitesi';

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
  String get linkTypeOther => 'Diğer';

  @override
  String get pasteUrl => 'URL Yapıştır';

  @override
  String get importantNoticeTitle => 'Önemli Duyuru';

  @override
  String get importantNoticeBody =>
      'Bu coin ETA Network ekosisteminin bir parçasıdır ve büyüyen bir dijital topluluğa katılımı temsil eder. Topluluk coinleri, kullanıcılar tarafından ağ içinde inşa etmek, denemek ve etkileşimde bulunmak için oluşturulur. ETA Network geliştirme aşamasının başındadır. Ekosistem büyüdükçe, topluluk etkinliğine, platform evrimine ve geçerli yönergelere dayalı olarak yeni araçlar, özellikler ve entegrasyonlar sunulabilir.';

  @override
  String get pleaseWait => 'Lütfen bekleyin...';

  @override
  String get save => 'Kaydet';

  @override
  String createCoinFailed(String error) {
    return 'Coin oluşturma başarısız: $error';
  }

  @override
  String get coinNameLengthError => 'Coin adı 3-30 karakter olmalıdır.';

  @override
  String get symbolRequiredError => 'Sembol gereklidir.';

  @override
  String get symbolLengthError => 'Sembol 2-6 harf/rakam olmalıdır.';

  @override
  String get descriptionTooLongError => 'Açıklama çok uzun.';

  @override
  String baseRateRangeError(String max) {
    return 'Temel madencilik hızı 0.000000001 ile $max arasında olmalıdır.';
  }

  @override
  String get coinNameExistsError =>
      'Coin adı zaten mevcut. Lütfen başka bir tane seçin.';

  @override
  String get symbolExistsError =>
      'Sembol zaten mevcut. Lütfen başka bir tane seçin.';

  @override
  String get urlInvalidError => 'URL\'lerden biri geçersiz.';

  @override
  String get subscribeAndBoost => 'Abone Ol & Madenciliği Hızlandır';

  @override
  String get autoCollect => 'Otomatik topla';

  @override
  String autoMineCoins(int count) {
    return '$count coin otomatik kaz';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Hız';
  }

  @override
  String get perHourSuffix => '/saat';

  @override
  String get etaPerHourSuffix => 'ETA/saat';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Açıklama mevcut değil.';

  @override
  String get unknownUser => 'Bilinmeyen';

  @override
  String get streakLabel => 'SERİ';

  @override
  String get referralsLabel => 'REFERANSLAR';

  @override
  String get sessionsLabel => 'OTURUMLAR';

  @override
  String get accountInfoSection => 'Hesap Bilgileri';

  @override
  String get accountInfoTile => 'Hesap Bilgileri';

  @override
  String get invitedByPrompt => 'Biri tarafından mı davet edildin?';

  @override
  String get enterReferralCode => 'Referans kodunu girin';

  @override
  String get invitedStatus => 'Davet Edildi';

  @override
  String get lockedStatus => 'Kilitli';

  @override
  String get applyButton => 'Uygula';

  @override
  String get aboutPageTitle => 'Hakkında';

  @override
  String get faqTile => 'SSS';

  @override
  String get whitePaperTile => 'Beyaz Kitap';

  @override
  String get contactUsTile => 'Bize Ulaşın';

  @override
  String get securitySettingsTile => 'Güvenlik Ayarları';

  @override
  String get securitySettingsPageTitle => 'Güvenlik Ayarları';

  @override
  String get deleteAccountTile => 'Hesabı Sil';

  @override
  String get deleteAccountSubtitle =>
      'Hesabınızı ve verilerinizi kalıcı olarak silin';

  @override
  String get deleteAccountDialogTitle => 'Hesabı sil?';

  @override
  String get deleteAccountDialogContent =>
      'Bu işlem hesabınızı, verilerinizi ve oturumlarınızı kalıcı olarak silecektir. Bu işlem geri alınamaz.';

  @override
  String get deleteButton => 'Sil';

  @override
  String get kycVerificationTile => 'KYC Doğrulama';

  @override
  String get kycVerificationDialogTitle => 'KYC Doğrulama';

  @override
  String get kycComingSoonMessage => 'Önümüzdeki aşamalarda aktif edilecektir.';

  @override
  String get okButton => 'Tamam';

  @override
  String get logOutLabel => 'Çıkış Yap';

  @override
  String get confirmDeletionTitle => 'Silme işlemini onayla';

  @override
  String get enterAccountPassword => 'Hesap şifresini girin';

  @override
  String get confirmButton => 'Onayla';

  @override
  String get usernameLabel => 'Kullanıcı Adı';

  @override
  String get emailLabel => 'E-posta';

  @override
  String get nameLabel => 'Ad';

  @override
  String get ageLabel => 'Yaş';

  @override
  String get countryLabel => 'Ülke';

  @override
  String get addressLabel => 'Adres';

  @override
  String get genderLabel => 'Cinsiyet';

  @override
  String get enterUsernameHint => 'Kullanıcı adını girin';

  @override
  String get enterNameHint => 'Adı girin';

  @override
  String get enterAgeHint => 'Yaşı girin';

  @override
  String get enterCountryHint => 'Ülkeyi girin';

  @override
  String get enterAddressHint => 'Adresi girin';

  @override
  String get enterGenderHint => 'Cinsiyeti girin';

  @override
  String get savingLabel => 'Kaydediliyor...';

  @override
  String get usernameEmptyError => 'Kullanıcı adı boş olamaz';

  @override
  String get invalidAgeError => 'Geçersiz yaş değeri';

  @override
  String get saveError => 'Değişiklikler kaydedilemedi';

  @override
  String get cancelButton => 'İptal';
}
