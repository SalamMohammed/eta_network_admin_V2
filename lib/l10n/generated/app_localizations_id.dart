// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get totalBalance => 'Total Saldo';

  @override
  String joinedDate(String link, Object date) {
    return 'Bergabung $date';
  }

  @override
  String get inviteEarn => 'Undang & Hasilkan';

  @override
  String get shareCodeDescription =>
      'Bagikan kode unik Anda kepada teman untuk meningkatkan tingkat penambangan Anda.';

  @override
  String get shareLink => 'Bagikan Tautan';

  @override
  String get totalInvited => 'TOTAL DIUNDANG';

  @override
  String get activeNow => 'AKTIF SEKARANG';

  @override
  String get viewAll => 'Lihat Semua';

  @override
  String get createCoin => 'Buat Koin';

  @override
  String get mining => 'Menambang';

  @override
  String get settings => 'Pengaturan';

  @override
  String get language => 'Bahasa';

  @override
  String get languageSubtitle => 'Ubah bahasa aplikasi';

  @override
  String get selectLanguage => 'Pilih Bahasa';

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get home => 'Beranda';

  @override
  String get referral => 'Rujukan';

  @override
  String get profile => 'Profil';

  @override
  String get dayStreak => 'Hari Beruntun';

  @override
  String dayStreakValue(int count) {
    return '$count Hari Beruntun';
  }

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Tidak Aktif';

  @override
  String get sessionEndsIn => 'Sesi berakhir dalam';

  @override
  String get startEarning => 'Mulai Menghasilkan';

  @override
  String get loadingAd => 'Memuat iklan...';

  @override
  String waitSeconds(int seconds) {
    return 'Tunggu ${seconds}d';
  }

  @override
  String rewardPlusPercent(String percent) {
    return 'Hadiah +$percent%';
  }

  @override
  String get rewardedAdNotAvailable => 'Iklan berhadiah tidak tersedia';

  @override
  String rateBoosted(String rate) {
    return 'Kecepatan ditingkatkan: +$rate ETA/jam';
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
    return 'Rincian kecepatan: Dasar $base, Beruntun +$streak, Peringkat +$rank, Rujukan +$referrals = $total ETA/jam';
  }

  @override
  String get unableToStartMining =>
      'Tidak dapat memulai penambangan. Silakan periksa koneksi internet Anda dan coba lagi.';

  @override
  String get createCommunityCoin => 'Buat Koin Komunitas';

  @override
  String get launchCoinDescription =>
      'Luncurkan koin Anda sendiri di Jaringan ETA secara instan.';

  @override
  String get createYourOwnCoin => 'Buat koin Anda sendiri';

  @override
  String get launchCommunityCoinDescription =>
      'Luncurkan koin komunitas Anda sendiri yang dapat ditambang oleh pengguna ETA lainnya.';

  @override
  String get editCoin => 'Edit koin';

  @override
  String baseRate(String rate) {
    return 'Kecepatan dasar: $rate koin/jam';
  }

  @override
  String createdBy(String username) {
    return 'Dibuat oleh @$username';
  }

  @override
  String etaPerHr(String rate) {
    return '+$rate ETA/jam';
  }

  @override
  String get noCoinsYet => 'Belum ada koin. Tambahkan dari Koin Langsung.';

  @override
  String get mine => 'Tambang';

  @override
  String get remaining => 'tersisa';

  @override
  String get holders => 'Pemegang';

  @override
  String get close => 'Tutup';

  @override
  String get readMore => 'Baca Selengkapnya';

  @override
  String get readLess => 'Baca Lebih Sedikit';

  @override
  String get projectLinks => 'Tautan Proyek';

  @override
  String get verifyEmailTitle => 'Verifikasi Email Anda';

  @override
  String get verifyEmailMessage =>
      'Kami telah mengirim tautan verifikasi ke alamat email Anda. Harap verifikasi akun Anda untuk membuka kunci semua fitur.';

  @override
  String get resendEmail => 'Kirim Ulang Email';

  @override
  String get iHaveVerified => 'Saya sudah verifikasi';

  @override
  String get logout => 'Keluar';

  @override
  String get emailVerifiedSuccess => 'Email berhasil diverifikasi!';

  @override
  String get emailNotVerified =>
      'Email belum diverifikasi. Silakan periksa kotak masuk Anda.';

  @override
  String get verificationEmailSent => 'Email verifikasi terkirim';

  @override
  String get startMining => 'Mulai Menambang';

  @override
  String get minedCoins => 'Koin Ditambang';

  @override
  String get liveCoins => 'Koin Langsung';

  @override
  String get asset => 'Aset';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterPopular => 'Populer';

  @override
  String get filterNames => 'Nama';

  @override
  String get filterOldNew => 'Lama - Baru';

  @override
  String get filterNewOld => 'Baru - Lama';

  @override
  String startMiningWithCount(int count) {
    return 'Mulai Menambang ($count)';
  }

  @override
  String get clearSelection => 'Hapus Pilihan';

  @override
  String get cancel => 'Batal';

  @override
  String get refreshStatus => 'Segarkan Status';

  @override
  String get purchaseFailed => 'Pembelian gagal';

  @override
  String get securePaymentViaGooglePlay =>
      'Pembayaran aman melalui Google Play';

  @override
  String get addedToMinedCoins => 'Ditambahkan ke Koin Ditambang';

  @override
  String failedToAdd(String message) {
    return 'Gagal menambahkan: $message';
  }

  @override
  String get subscriptionsUnavailable =>
      'Langganan hanya tersedia di Android/iOS.';

  @override
  String get miningRate => 'Kecepatan penambangan';

  @override
  String get about => 'Tentang';

  @override
  String get yourMined => 'Ditambang Anda';

  @override
  String get totalMined => 'Total Ditambang';

  @override
  String get noReferrals => 'Belum ada rujukan';

  @override
  String get linkCopied => 'Tautan disalin';

  @override
  String get copy => 'Salin';

  @override
  String get howItWorks => 'Cara kerjanya';

  @override
  String get referralDescription =>
      'Bagikan kode Anda kepada teman. Saat mereka bergabung dan aktif, tim Anda berkembang dan potensi penghasilan Anda meningkat.';

  @override
  String get yourTeam => 'Tim Anda';

  @override
  String get referralsTitle => 'Rujukan';

  @override
  String get shareLinkTitle => 'Bagikan Tautan';

  @override
  String get copyLinkInstruction => 'Salin tautan ini untuk berbagi:';

  @override
  String get referralCodeCopied => 'Kode rujukan disalin';

  @override
  String joinMeText(String code, String link) {
    return 'Bergabunglah dengan saya di Jaringan Eta! Gunakan kode saya: $code $link';
  }

  @override
  String get etaNetwork => 'Jaringan ETA';

  @override
  String get noLiveCommunityCoins => 'Tidak ada koin komunitas langsung';

  @override
  String get rate => 'KECEPATAN';

  @override
  String get filterRandom => 'Acak';

  @override
  String get baseRateLabel => 'Kecepatan Dasar';

  @override
  String startFailed(String error) {
    return 'Gagal memulai: $error';
  }

  @override
  String get sessionProgress => 'Kemajuan Sesi';

  @override
  String get remainingLabel => 'tersisa';

  @override
  String get boostRate => 'Kecepatan Peningkatan';

  @override
  String get minedLabel => 'Ditambang';

  @override
  String get noSubscriptionPlansAvailable =>
      'Tidak ada paket langganan yang tersedia';

  @override
  String get subscriptionPlans => 'Paket Langganan';

  @override
  String get recommended => 'Direkomendasikan';

  @override
  String get editCommunityCoin => 'Edit Koin Komunitas';

  @override
  String get launchCoinEcosystemDescription =>
      'Luncurkan koin Anda sendiri di dalam ekosistem ETA untuk komunitas Anda.';

  @override
  String get upload => 'Unggah';

  @override
  String get recommendedImageSize => 'Disarankan 200x200px';

  @override
  String get coinNameLabel => 'Nama koin';

  @override
  String get symbolLabel => 'Simbol';

  @override
  String get descriptionLabel => 'Deskripsi';

  @override
  String get baseMiningRateLabel => 'Kecepatan penambangan dasar (koin/jam)';

  @override
  String maxAllowed(String max) {
    return 'Maksimum Diizinkan : $max';
  }

  @override
  String get socialProjectLinksOptional => 'Tautan sosial & proyek (opsional)';

  @override
  String get linkTypeWebsite => 'Situs Web';

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
  String get linkTypeOther => 'Lainnya';

  @override
  String get pasteUrl => 'Tempel URL';

  @override
  String get importantNoticeTitle => 'Pemberitahuan Penting';

  @override
  String get importantNoticeBody =>
      'Koin ini adalah bagian dari ekosistem Jaringan ETA dan mewakili partisipasi dalam komunitas digital yang sedang berkembang. Koin komunitas dibuat oleh pengguna untuk membangun, bereksperimen, dan terlibat dalam jaringan. Jaringan ETA sedang dalam tahap awal pengembangan. Seiring berkembangnya ekosistem, utilitas, fitur, dan integrasi baru dapat diperkenalkan berdasarkan aktivitas komunitas, evolusi platform, dan pedoman yang berlaku.';

  @override
  String get pleaseWait => 'Mohon tunggu...';

  @override
  String get save => 'Simpan';

  @override
  String createCoinFailed(String error) {
    return 'Gagal membuat koin: $error';
  }

  @override
  String get coinNameLengthError => 'Nama koin harus 3-30 karakter.';

  @override
  String get symbolRequiredError => 'Simbol diperlukan.';

  @override
  String get symbolLengthError => 'Simbol harus 2-6 huruf/angka.';

  @override
  String get descriptionTooLongError => 'Deskripsi terlalu panjang.';

  @override
  String baseRateRangeError(String max) {
    return 'Kecepatan penambangan dasar harus antara 0.000000001 dan $max.';
  }

  @override
  String get coinNameExistsError =>
      'Nama koin sudah ada. Silakan pilih yang lain.';

  @override
  String get symbolExistsError => 'Simbol sudah ada. Silakan pilih yang lain.';

  @override
  String get urlInvalidError => 'Salah satu URL tidak valid.';

  @override
  String get subscribeAndBoost => 'Berlangganan & Tingkatkan Penambangan';

  @override
  String get autoCollect => 'Kumpulkan otomatis';

  @override
  String autoMineCoins(int count) {
    return 'Tambang otomatis $count koin';
  }

  @override
  String speedBoost(String percent) {
    return '+$percent% Kecepatan';
  }

  @override
  String get perHourSuffix => '/jam';

  @override
  String get etaPerHourSuffix => 'ETA/jam';

  @override
  String get eta => 'ETA';

  @override
  String get noDescriptionAvailable => 'Tidak ada deskripsi tersedia.';

  @override
  String get unknownUser => 'Tidak diketahui';

  @override
  String get streakLabel => 'BERUNTUN';

  @override
  String get referralsLabel => 'RUJUKAN';

  @override
  String get sessionsLabel => 'SESI';

  @override
  String get accountInfoSection => 'Info Akun';

  @override
  String get accountInfoTile => 'Info Akun';

  @override
  String get invitedByPrompt => 'Diundang oleh seseorang?';

  @override
  String get enterReferralCode => 'Masukkan kode rujukan';

  @override
  String get invitedStatus => 'Diundang';

  @override
  String get lockedStatus => 'Terkunci';

  @override
  String get applyButton => 'Terapkan';

  @override
  String get aboutPageTitle => 'Tentang';

  @override
  String get faqTile => 'FAQ';

  @override
  String get whitePaperTile => 'Kertas Putih';

  @override
  String get contactUsTile => 'Hubungi Kami';

  @override
  String get securitySettingsTile => 'Pengaturan Keamanan';

  @override
  String get securitySettingsPageTitle => 'Pengaturan Keamanan';

  @override
  String get deleteAccountTile => 'Hapus Akun';

  @override
  String get deleteAccountSubtitle =>
      'Hapus akun dan data Anda secara permanen';

  @override
  String get deleteAccountDialogTitle => 'Hapus akun?';

  @override
  String get deleteAccountDialogContent =>
      'Ini akan menghapus akun, data, dan sesi Anda secara permanen. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get deleteButton => 'Hapus';

  @override
  String get kycVerificationTile => 'Verifikasi KYC';

  @override
  String get kycVerificationDialogTitle => 'Verifikasi KYC';

  @override
  String get kycComingSoonMessage => 'Akan diaktifkan pada tahap mendatang.';

  @override
  String get okButton => 'OKE';

  @override
  String get logOutLabel => 'Keluar';

  @override
  String get confirmDeletionTitle => 'Konfirmasi penghapusan';

  @override
  String get enterAccountPassword => 'Masukkan kata sandi akun';

  @override
  String get confirmButton => 'Konfirmasi';

  @override
  String get usernameLabel => 'Nama Pengguna';

  @override
  String get emailLabel => 'Email';

  @override
  String get nameLabel => 'Nama';

  @override
  String get ageLabel => 'Usia';

  @override
  String get countryLabel => 'Negara';

  @override
  String get addressLabel => 'Alamat';

  @override
  String get genderLabel => 'Jenis Kelamin';

  @override
  String get enterUsernameHint => 'Masukkan nama pengguna';

  @override
  String get enterNameHint => 'Masukkan nama';

  @override
  String get enterAgeHint => 'Masukkan usia';

  @override
  String get enterCountryHint => 'Masukkan negara';

  @override
  String get enterAddressHint => 'Masukkan alamat';

  @override
  String get enterGenderHint => 'Masukkan jenis kelamin';

  @override
  String get savingLabel => 'Menyimpan...';

  @override
  String get usernameEmptyError => 'Nama pengguna tidak boleh kosong';

  @override
  String get invalidAgeError => 'Nilai usia tidak valid';

  @override
  String get saveError => 'Gagal menyimpan perubahan';

  @override
  String get cancelButton => 'Batal';
}
