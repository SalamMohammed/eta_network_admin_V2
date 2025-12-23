import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../shared/firestore_constants.dart';

class AdsConfig {
  final bool enableRewarded;
  final bool enableBannerOnMiningPress;
  final int maxRewardedPerDay;
  final double rewardBonusPercent;
  final String bannerAdUnitIdAndroid;
  final String bannerAdUnitIdIos;
  final String rewardedAdUnitIdAndroid;
  final String rewardedAdUnitIdIos;

  const AdsConfig({
    required this.enableRewarded,
    required this.enableBannerOnMiningPress,
    required this.maxRewardedPerDay,
    required this.rewardBonusPercent,
    required this.bannerAdUnitIdAndroid,
    required this.bannerAdUnitIdIos,
    required this.rewardedAdUnitIdAndroid,
    required this.rewardedAdUnitIdIos,
  });

  static const AdsConfig defaults = AdsConfig(
    enableRewarded: true,
    enableBannerOnMiningPress: true,
    maxRewardedPerDay: 5,
    rewardBonusPercent: 2,
    bannerAdUnitIdAndroid: 'ca-app-pub-3940256099942544/6300978111',
    bannerAdUnitIdIos: 'ca-app-pub-3940256099942544/2934735716',
    rewardedAdUnitIdAndroid: 'ca-app-pub-3940256099942544/5224354917',
    rewardedAdUnitIdIos: 'ca-app-pub-3940256099942544/1712485313',
  );

  AdsConfig copyWith({
    bool? enableRewarded,
    bool? enableBannerOnMiningPress,
    int? maxRewardedPerDay,
    double? rewardBonusPercent,
    String? bannerAdUnitIdAndroid,
    String? bannerAdUnitIdIos,
    String? rewardedAdUnitIdAndroid,
    String? rewardedAdUnitIdIos,
  }) {
    return AdsConfig(
      enableRewarded: enableRewarded ?? this.enableRewarded,
      enableBannerOnMiningPress:
          enableBannerOnMiningPress ?? this.enableBannerOnMiningPress,
      maxRewardedPerDay: maxRewardedPerDay ?? this.maxRewardedPerDay,
      rewardBonusPercent: rewardBonusPercent ?? this.rewardBonusPercent,
      bannerAdUnitIdAndroid:
          bannerAdUnitIdAndroid ?? this.bannerAdUnitIdAndroid,
      bannerAdUnitIdIos: bannerAdUnitIdIos ?? this.bannerAdUnitIdIos,
      rewardedAdUnitIdAndroid:
          rewardedAdUnitIdAndroid ?? this.rewardedAdUnitIdAndroid,
      rewardedAdUnitIdIos: rewardedAdUnitIdIos ?? this.rewardedAdUnitIdIos,
    );
  }

  factory AdsConfig.fromFirestore(Map<String, dynamic> data) {
    final int maxPerDay =
        ((data[FirestoreAdsConfigFields.maxRewardedPerDay] as num?)?.toInt() ??
                defaults.maxRewardedPerDay)
            .clamp(0, 1000);

    final double rewardPercent =
        ((data[FirestoreAdsConfigFields.rewardBonusPercent] as num?)
                    ?.toDouble() ??
                defaults.rewardBonusPercent)
            .clamp(0, 100000);

    final String bannerAndroid =
        (data[FirestoreAdsConfigFields.bannerAdUnitIdAndroid] as String?)
            ?.trim() ??
        defaults.bannerAdUnitIdAndroid;

    final String bannerIos =
        (data[FirestoreAdsConfigFields.bannerAdUnitIdIos] as String?)?.trim() ??
        defaults.bannerAdUnitIdIos;

    final String rewardedAndroid =
        (data[FirestoreAdsConfigFields.rewardedAdUnitIdAndroid] as String?)
            ?.trim() ??
        defaults.rewardedAdUnitIdAndroid;

    final String rewardedIos =
        (data[FirestoreAdsConfigFields.rewardedAdUnitIdIos] as String?)
            ?.trim() ??
        defaults.rewardedAdUnitIdIos;

    return AdsConfig(
      enableRewarded:
          (data[FirestoreAdsConfigFields.enableRewarded] as bool?) ??
          defaults.enableRewarded,
      enableBannerOnMiningPress:
          (data[FirestoreAdsConfigFields.enableBannerOnMiningPress] as bool?) ??
          defaults.enableBannerOnMiningPress,
      maxRewardedPerDay: maxPerDay,
      rewardBonusPercent: rewardPercent,
      bannerAdUnitIdAndroid: bannerAndroid.isEmpty
          ? defaults.bannerAdUnitIdAndroid
          : bannerAndroid,
      bannerAdUnitIdIos: bannerIos.isEmpty
          ? defaults.bannerAdUnitIdIos
          : bannerIos,
      rewardedAdUnitIdAndroid: rewardedAndroid.isEmpty
          ? defaults.rewardedAdUnitIdAndroid
          : rewardedAndroid,
      rewardedAdUnitIdIos: rewardedIos.isEmpty
          ? defaults.rewardedAdUnitIdIos
          : rewardedIos,
    );
  }
}

class AdsService extends ChangeNotifier {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  AdsConfig _config = AdsConfig.defaults;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _configSub;
  bool _initialized = false;

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  AdsConfig get config => _config;

  Future<void> init() async {
    if (_initialized) return;
    if (!isSupportedPlatform) {
      _initialized = true;
      return;
    }
    await MobileAds.instance.initialize();
    _startConfigListener();
    _initialized = true;
  }

  void _startConfigListener() {
    _configSub?.cancel();
    _configSub = FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.ads)
        .snapshots()
        .listen((snap) {
          final data = snap.data();
          _config = data == null
              ? AdsConfig.defaults
              : AdsConfig.fromFirestore(data);
          notifyListeners();
        });
  }

  String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _config.bannerAdUnitIdIos;
    }
    return _config.bannerAdUnitIdAndroid;
  }

  String get rewardedAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _config.rewardedAdUnitIdIos;
    }
    return _config.rewardedAdUnitIdAndroid;
  }

  Future<RewardedAd?> loadRewardedAd() async {
    if (!isSupportedPlatform) return null;
    if (!_config.enableRewarded) return null;
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => completer.complete(ad),
        onAdFailedToLoad: (error) => completer.complete(null),
      ),
    );
    return completer.future;
  }

  @override
  void dispose() {
    _configSub?.cancel();
    _configSub = null;
    super.dispose();
  }
}
