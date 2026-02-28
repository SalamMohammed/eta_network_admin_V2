// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Malay (`ms`).
class AppLocalizationsMs extends AppLocalizations {
  AppLocalizationsMs([String locale = 'ms']) : super(locale);

  @override
  String get totalBalance => 'Jumlah Baki';

  @override
  String joinedDate(String link, Object date) {
    return 'Menyertai $date';
  }

  @override
  String get inviteEarn => 'Jemput & Peroleh';

  @override
  String get shareCodeDescription =>
      'Kongsi kod unik anda dengan rakan untuk meningkatkan kadar perlombongan anda.';

  @override
  String get shareLink => 'Kongsi Pautan';

  @override
  String get totalInvited => 'JUMLAH DIJEMPUT';

  @override
  String get activeNow => 'AKTIF SEKARANG';

  @override
  String get viewAll => 'Lihat Semua';

  @override
  String get createCoin => 'Cipta Syiling';

  @override
  String get mining => 'Melombong';

  @override
  String get settings => 'Tetapan';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSubtitle => 'Tukar bahasa aplikasi';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get balanceTitle => 'Baki';

  @override
  String get home => 'Laman Utama';

  @override
  String get referral => 'Rujukan';

  @override
  String get profile => 'Profil';

  @override
  String get dayStreak => 'Hari Berturut-turut';

  @override
  String dayStreakValue(int count) {
    return '$count Hari Berturut-turut';
  }

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Tidak Aktif';

  @override
  String get sessionEndsIn => 'Sesi tamat dalam';

  @override
  String get startEarning => 'Mula Peroleh';

  @override
  String get loadingAd => 'Memuatkan iklan...';

  @override
  String waitSeconds(int seconds) {
    return 'Tunggu ${seconds}s';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Ganjaran +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Iklan ganjaran tidak tersedia';

  @override
  String rateBoosted(String rate) {
    return 'Kadar ditingkatkan: +$rate ETA/jam';
  }

  @override
  String adBonusFailed(String message) {
    return 'Bonus iklan gagal: $message';
  }

  @override
  String rateBreakdown(
    String base,
    String streak,
    String rank,
    String referrals,
    String total,
  ) {
    return 'Pecahan kadar: Asas $base, Berturut-turut +$streak, Pangkat +$rank, Rujukan +$referrals = $total ETA/jam';
  }

  @override
  String get unableToStartMining =>
      'Tidak dapat memulakan perlombongan. Sila semak sambungan internet anda dan cuba lagi.';

  @override
  String get createCommunityCoin => 'Cipta Syiling Komuniti';

  @override
  String get launchCoinDescription =>
      'Lancarkan syiling anda sendiri di Rangkaian ETA serta-merta.';

  @override
  String get createYourOwnCoin => 'Cipta syiling anda sendiri';

  @override
  String get launchCommunityCoinDescription =>
      'Lancarkan syiling komuniti anda sendiri yang boleh dilombong oleh pengguna ETA lain.';

  @override
  String get editCoin => 'Edit syiling';

  @override
  String baseRate(String rate) {
    return 'Kadar asas: $rate syiling/jam';
  }

  @override
  String createdBy(String username) {
    return 'Dicipta oleh @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/jam';
  }

  @override
  String get noCoinsYet => 'Tiada syiling lagi. Tambah dari Syiling Langsung.';

  @override
  String get mine => 'Lombong';

  @override
  String get remaining => 'baki';

  @override
  String get holders => 'Pemegang';

  @override
  String get close => 'Tutup';

  @override
  String get readMore => 'Baca Lebih Lanjut';

  @override
  String get readLess => 'Baca Kurang';

  @override
  String get projectLinks => 'Pautan Projek';

  @override
  String get verifyEmailTitle => 'Sahkan Emel Anda';

  @override
  String get verifyEmailMessage =>
      'Kami telah menghantar pautan pengesahan ke alamat emel anda. Sila sahkan akaun anda untuk membuka kunci semua ciri.';

  @override
  String get resendEmail => 'Hantar Semula Emel';

  @override
  String get iHaveVerified => 'Saya telah sahkan';

  @override
  String get logout => 'Log Keluar';

  @override
  String get emailVerifiedSuccess => 'Emel berjaya disahkan!';

  @override
  String get emailNotVerified =>
      'Emel belum disahkan. Sila semak peti masuk anda.';

  @override
  String get verificationEmailSent => 'Emel pengesahan dihantar';

  @override
  String get startMining => 'Mula Perlombongan';

  @override
  String get minedCoins => 'Syiling Dilombong';

  @override
  String get liveCoins => 'Syiling Langsung';

  @override
  String get asset => 'Aset';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Popular';

  @override
  String get filterNames => 'Nama';

  @override
  String get filterOldNew => 'Lama - Baru';

  @override
  String get filterNewOld => 'Baru - Lama';

  @override
  String startMiningWithCount(int count) {
    return 'Mula Perlombongan ($count)';
  }

  @override
  String get clearSelection => 'Kosongkan Pilihan';

  @override
  String get cancel => 'Batal';

  @override
  String get refreshStatus => 'Segarkan Status';

  @override
  String get purchaseFailed => 'Pembelian gagal';

  @override
  String get securePaymentViaGooglePlay =>
      'Pembayaran selamat melalui Google Play';

  @override
  String get addedToMinedCoins => 'Ditambah ke Syiling Dilombong';

  @override
  String failedToAdd(String message) {
    return 'Gagal menambah: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Langganan hanya tersedia pada Android/iOS.';

  @override
  String get miningRate => 'Kadar perlombongan';

  @override
  String get about => 'Tentang';

  @override
  String get yourMined => 'Dilombong Anda';

  @override
  String get totalMined => 'Jumlah Dilombong';

  @override
  String get noReferrals => 'Tiada rujukan lagi';

  @override
  String get linkCopied => 'Pautan disalin';

  @override
  String get copy => 'Salin';

  @override
  String get howItWorks => 'Cara ia berfungsi';

  @override
  String get referralDescription =>
      'Kongsi kod anda dengan rakan. Apabila mereka menyertai dan menjadi aktif, anda mengembangkan pasukan anda dan meningkatkan potensi pendapatan anda.';

  @override
  String get yourTeam => 'Pasukan Anda';

  @override
  String get referralsTitle => 'Rujukan';

  @override
  String get shareLinkTitle => 'Kongsi Pautan';

  @override
  String get copyLinkInstruction => 'Salin pautan ini untuk berkongsi:';

  @override
  String get referralCodeCopied => 'Kod rujukan disalin';

  @override
  String joinMeText(String code, String link) {
    return 'Sertai saya di Rangkaian Eta! Gunakan kod saya: $code $link';
  }

  @override
  String get etaNetwork => 'Rangkaian ETA';

  @override
  String get noLiveCommunityCoins => 'Tiada syiling komuniti langsung';

  @override
  String get rate => 'KADAR';

  @override
  String get filterRandom => 'Rawak';

  @override
  String get baseRateLabel => 'Kadar Asas';

  @override
  String startFailed(String error) {
    return 'Gagal memulakan: $error';
  }

  @override
  String get sessionProgress => 'Kemajuan Sesi';

  @override
  String get remainingLabel => 'baki';

  @override
  String get boostRate => 'Kadar Peningkatan';

  @override
  String get minedLabel => 'Dilombong';

  @override
  String get noSubscriptionPlansAvailable => 'Tiada pelan langganan tersedia';

  @override
  String get subscriptionPlans => 'Pelan Langganan';

  @override
  String get recommended => 'Disyorkan';

  @override
  String get editCommunityCoin => 'Edit Syiling Komuniti';

  @override
  String get launchCoinEcosystemDescription =>
      'Lancarkan syiling anda sendiri dalam ekosistem ETA untuk komuniti anda.';

  @override
  String get upload => 'Muat Naik';

  @override
  String get recommendedImageSize => 'Disyorkan 200x200px';

  @override
  String get coinNameLabel => 'Nama syiling';

  @override
  String get symbolLabel => 'Simbol';

  @override
  String get descriptionLabel => 'Penerangan';

  @override
  String get baseMiningRateLabel => 'Kadar perlombongan asas (syiling/jam)';

  @override
  String maxAllowed(String max) {
    return 'Maksimum Dibenarkan : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Pautan sosial & projek (pilihan)';

  @override
  String get linkTypeWebsite => 'Laman Web';

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
  String get linkTypeOther => 'Lain-lain';

  @override
  String get pasteUrl => 'Tampal URL';

  @override
  String get importantNoticeTitle => 'Notis Penting';

  @override
  String get importantNoticeBody =>
      'Syiling ini adalah sebahagian daripada ekosistem Rangkaian ETA dan mewakili penyertaan dalam komuniti digital yang berkembang. Syiling komuniti dicipta oleh pengguna untuk membina, bereksperimen, dan terlibat dalam rangkaian. Rangkaian ETA berada di peringkat awal pembangunan. Apabila ekosistem berkembang, utiliti, ciri, dan integrasi baharu mungkin diperkenalkan berdasarkan aktiviti komuniti, evolusi platform, dan garis panduan yang berkenaan.';

  @override
  String get pleaseWait => 'Sila tunggu...';

  @override
  String get save => 'Simpan';

  @override
  String createCoinFailed(String error) {
    return 'Gagal mencipta syiling: $error';
  }

  @override
  String get coinNameLengthError => 'Nama syiling mesti 3–30 aksara.';

  @override
  String get symbolRequiredError => 'Simbol diperlukan.';

  @override
  String get symbolLengthError => 'Simbol mesti 2–6 huruf/nombor.';

  @override
  String get descriptionTooLongError => 'Penerangan terlalu panjang.';

  @override
  String baseRateRangeError(String max) {
    return 'Kadar perlombongan asas mesti antara 0.000000001 dan $max.';
  }

  @override
  String get coinNameExistsError =>
      'Nama syiling sudah wujud. Sila pilih yang lain.';

  @override
  String get symbolExistsError => 'Simbol sudah wujud. Sila pilih yang lain.';

  @override
  String get urlInvalidError => 'Salah satu URL tidak sah.';

  @override
  String get subscribeAndBoost => 'Langgan & Tingkatkan Perlombongan';

  @override
  String get autoCollect => 'Kumpul automatik';

  @override
  String autoMineCoins(int count) {
    return 'Lombong automatik $count syiling';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Kelajuan';
  }

  @override
  String get perHourSuffix => '/jam';

  @override
  String get etaPerHourSuffix => 'ETA/jam';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Tiada penerangan tersedia.';

  @override
  String get unknownUser => 'Tidak diketahui';

  @override
  String get streakLabel => 'BERTURUT';

  @override
  String get referralsLabel => 'RUJUKAN';

  @override
  String get sessionsLabel => 'SESI';

  @override
  String get accountInfoSection => 'Maklumat Akaun';

  @override
  String get accountInfoTile => 'Maklumat Akaun';

  @override
  String get invitedByPrompt => 'Di jemput oleh seseorang?';

  @override
  String get enterReferralCode => 'Masukkan kod rujukan';

  @override
  String get invitedStatus => 'Dijemput';

  @override
  String get lockedStatus => 'Dikunci';

  @override
  String get applyButton => 'Mohon';

  @override
  String get aboutPageTitle => 'Tentang';

  @override
  String get faqTile => 'Soalan Lazim';

  @override
  String get whitePaperTile => 'Kertas Putih';

  @override
  String get contactUsTile => 'Hubungi Kami';

  @override
  String get securitySettingsTile => 'Tetapan Keselamatan';

  @override
  String get securitySettingsPageTitle => 'Tetapan Keselamatan';

  @override
  String get deleteAccountTile => 'Padam Akaun';

  @override
  String get deleteAccountSubtitle => 'Padam akaun dan data anda secara kekal';

  @override
  String get deleteAccountDialogTitle => 'Padam akaun?';

  @override
  String get deleteAccountDialogContent =>
      'Ini akan memadam akaun, data, dan sesi anda secara kekal. Tindakan ini tidak boleh dibatalkan.';

  @override
  String get deleteButton => 'Padam';

  @override
  String get kycVerificationTile => 'Pengesahan KYC';

  @override
  String get kycVerificationDialogTitle => 'Pengesahan KYC';

  @override
  String get kycComingSoonMessage =>
      'Akan diaktifkan dalam peringkat akan datang.';

  @override
  String get okButton => 'OK';

  @override
  String get logOutLabel => 'Log Keluar';

  @override
  String get confirmDeletionTitle => 'Sahkan pemadaman';

  @override
  String get enterAccountPassword => 'Masukkan kata laluan akaun';

  @override
  String get confirmButton => 'Sahkan';

  @override
  String get usernameLabel => 'Nama Pengguna';

  @override
  String get emailLabel => 'Emel';

  @override
  String get nameLabel => 'Nama';

  @override
  String get ageLabel => 'Umur';

  @override
  String get countryLabel => 'Negara';

  @override
  String get addressLabel => 'Alamat';

  @override
  String get genderLabel => 'Jantina';

  @override
  String get enterUsernameHint => 'Masukkan nama pengguna';

  @override
  String get enterNameHint => 'Masukkan nama';

  @override
  String get enterAgeHint => 'Masukkan umur';

  @override
  String get enterCountryHint => 'Masukkan negara';

  @override
  String get enterAddressHint => 'Masukkan alamat';

  @override
  String get enterGenderHint => 'Masukkan jantina';

  @override
  String get savingLabel => 'Menyimpan...';

  @override
  String get usernameEmptyError => 'Nama pengguna tidak boleh kosong';

  @override
  String get invalidAgeError => 'Nilai umur tidak sah';

  @override
  String get saveError => 'Gagal menyimpan perubahan';

  @override
  String get cancelButton => 'Batal';
}
