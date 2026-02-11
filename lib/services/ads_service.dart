import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/firestore_helper.dart';
import '../shared/firestore_constants.dart';

class AdsConfig {
  final bool enableRewarded;
  final bool enableBannerOnMiningPress;
  final int maxRewardedPerDay;
  final int maxRewardedPerMiningSession;
  final double rewardBonusPercent;
  final String bannerAdUnitIdAndroid;
  final String bannerAdUnitIdIos;
  final String rewardedAdUnitIdAndroid;
  final String rewardedAdUnitIdIos;

  const AdsConfig({
    required this.enableRewarded,
    required this.enableBannerOnMiningPress,
    required this.maxRewardedPerDay,
    required this.maxRewardedPerMiningSession,
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
    maxRewardedPerMiningSession: 5,
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
    int? maxRewardedPerMiningSession,
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
      maxRewardedPerMiningSession:
          maxRewardedPerMiningSession ?? this.maxRewardedPerMiningSession,
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

    final int maxPerSession =
        ((data[FirestoreAdsConfigFields.maxRewardedPerMiningSession] as num?)
                    ?.toInt() ??
                defaults.maxRewardedPerMiningSession)
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
      maxRewardedPerMiningSession: maxPerSession,
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

class AdsService extends ChangeNotifier with WidgetsBindingObserver {
  static final AdsService _instance = AdsService._internal();
  factory AdsService() => _instance;
  AdsService._internal();

  static const String _prefsKeyAds = 'app_config_ads_cache';
  static const String _prefsKeyAdsTs = 'app_config_ads_ts';
  static const Duration _cacheDuration = Duration(hours: 24);

  AdsConfig _config = AdsConfig.defaults;
  bool _initialized = false;
  RewardedAd? _cachedRewardedAd;
  bool _isPreloading = false;
  DateTime? _lastLoadAttempt;
  static const Duration _minLoadInterval = Duration(seconds: 10);

  bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  AdsConfig get config => _config;

  Future<void> init() async {
    if (_initialized) return;
    WidgetsBinding.instance.addObserver(this);
    if (!isSupportedPlatform) {
      _initialized = true;
      return;
    }
    await MobileAds.instance.initialize();
    await _fetchConfig();
    _initialized = true;
    _preloadRewardedAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if config needs refresh on resume
      _fetchConfig();
      _preloadRewardedAd();
    }
  }

  Future<void> _fetchConfig({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Check disk cache if not forcing refresh
      if (!forceRefresh) {
        final int? ts = prefs.getInt(_prefsKeyAdsTs);
        if (ts != null) {
          final cachedTime = DateTime.fromMillisecondsSinceEpoch(ts);
          if (DateTime.now().difference(cachedTime) < _cacheDuration) {
            final String? jsonStr = prefs.getString(_prefsKeyAds);
            if (jsonStr != null) {
              try {
                final Map<String, dynamic> data = jsonDecode(jsonStr);
                _config = AdsConfig.fromFirestore(data);
                notifyListeners();
                debugPrint('AdsService: Using cached config');
                return;
              } catch (e) {
                debugPrint('AdsService: Error decoding cached config: $e');
              }
            }
          }
        }
      }

      // 2. Fetch from Firestore
      debugPrint('AdsService: Fetching config from Firestore');
      final doc = await FirestoreHelper.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.ads)
          .get();

      final data = doc.data();
      if (data != null) {
        _config = AdsConfig.fromFirestore(data);

        // 3. Save to cache
        // Remove Timestamp fields before encoding to avoid JsonUnsupportedObjectError
        final cacheData = Map<String, dynamic>.from(data);
        cacheData.remove(FirestoreUserFields.updatedAt);

        await prefs.setString(_prefsKeyAds, jsonEncode(cacheData));
        await prefs.setInt(
          _prefsKeyAdsTs,
          DateTime.now().millisecondsSinceEpoch,
        );
        notifyListeners();

        // Config changed, reload ad if needed
        if (_config.enableRewarded) {
          _cachedRewardedAd?.dispose();
          _cachedRewardedAd = null;
          _preloadRewardedAd();
        }
      }
    } catch (e) {
      debugPrint('AdsService: Error fetching config: $e');
    }
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

  Future<void> _preloadRewardedAd() async {
    if (!isSupportedPlatform) return;
    if (!_config.enableRewarded) return;
    if (_cachedRewardedAd != null) return; // Already have one
    if (_isPreloading) return; // Already loading

    // Don't load in background
    final state = WidgetsBinding.instance.lifecycleState;
    if (state != null && state != AppLifecycleState.resumed) return;

    // Rate limit checks
    final now = DateTime.now();
    if (_lastLoadAttempt != null &&
        now.difference(_lastLoadAttempt!) < _minLoadInterval) {
      return;
    }

    _isPreloading = true;
    _lastLoadAttempt = now;

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _cachedRewardedAd = ad;
            _isPreloading = false;
            debugPrint('AdsService: Ad preloaded successfully');
          },
          onAdFailedToLoad: (error) {
            _cachedRewardedAd = null;
            _isPreloading = false;
            debugPrint('AdsService: Ad failed to preload: $error');
          },
        ),
      );
    } catch (e) {
      _isPreloading = false;
      debugPrint('AdsService: Ad preload exception: $e');
    }
  }

  Future<RewardedAd?> loadRewardedAd() async {
    if (!isSupportedPlatform) return null;
    if (!_config.enableRewarded) return null;

    // Return cached ad if available (Instant!)
    if (_cachedRewardedAd != null) {
      final ad = _cachedRewardedAd;
      _cachedRewardedAd = null;
      // Preload the next one in the background
      _preloadRewardedAd();
      return ad;
    }

    // Fallback: Load on demand if cache missed
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // Don't cache this one, return it immediately
          completer.complete(ad);
          // Start preloading the next one
          _preloadRewardedAd();
        },
        onAdFailedToLoad: (error) => completer.complete(null),
      ),
    );
    return completer.future;
  }

  @override
  void dispose() {
    // Singleton should not be disposed.
    // WidgetsBinding.instance.removeObserver(this);
    // super.dispose();
  }
}
