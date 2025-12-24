import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../shared/firestore_constants.dart';
import '../../shared/theme/colors.dart';

class AdsMonetizationPage extends StatefulWidget {
  const AdsMonetizationPage({super.key});

  @override
  State<AdsMonetizationPage> createState() => _AdsMonetizationPageState();
}

class _AdsMonetizationPageState extends State<AdsMonetizationPage> {
  final rewardBonusCtrl = TextEditingController();
  final maxRewardsCtrl = TextEditingController();
  final maxRewardsPerSessionCtrl = TextEditingController();
  final bannerAndroidUnitIdCtrl = TextEditingController();
  final bannerIosUnitIdCtrl = TextEditingController();
  final rewardedAndroidUnitIdCtrl = TextEditingController();
  final rewardedIosUnitIdCtrl = TextEditingController();

  bool enableRewarded = true;
  bool enableBannerOnMiningPress = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    rewardBonusCtrl.dispose();
    maxRewardsCtrl.dispose();
    maxRewardsPerSessionCtrl.dispose();
    bannerAndroidUnitIdCtrl.dispose();
    bannerIosUnitIdCtrl.dispose();
    rewardedAndroidUnitIdCtrl.dispose();
    rewardedIosUnitIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.ads)
          .get();
      final d = doc.data() ?? {};

      enableRewarded =
          (d[FirestoreAdsConfigFields.enableRewarded] as bool?) ?? true;
      enableBannerOnMiningPress =
          (d[FirestoreAdsConfigFields.enableBannerOnMiningPress] as bool?) ??
          true;

      rewardBonusCtrl.text =
          ((d[FirestoreAdsConfigFields.rewardBonusPercent] as num?)
                      ?.toDouble() ??
                  2)
              .toString();
      maxRewardsCtrl.text =
          ((d[FirestoreAdsConfigFields.maxRewardedPerDay] as num?)?.toInt() ??
                  5)
              .toString();
      maxRewardsPerSessionCtrl.text =
          ((d[FirestoreAdsConfigFields.maxRewardedPerMiningSession] as num?)
                      ?.toInt() ??
                  5)
              .toString();

      bannerAndroidUnitIdCtrl.text =
          (d[FirestoreAdsConfigFields.bannerAdUnitIdAndroid] as String?) ?? '';
      bannerIosUnitIdCtrl.text =
          (d[FirestoreAdsConfigFields.bannerAdUnitIdIos] as String?) ?? '';
      rewardedAndroidUnitIdCtrl.text =
          (d[FirestoreAdsConfigFields.rewardedAdUnitIdAndroid] as String?) ??
          '';
      rewardedIosUnitIdCtrl.text =
          (d[FirestoreAdsConfigFields.rewardedAdUnitIdIos] as String?) ?? '';
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ads config: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.ads)
          .set({
            FirestoreAdsConfigFields.enableRewarded: enableRewarded,
            FirestoreAdsConfigFields.enableBannerOnMiningPress:
                enableBannerOnMiningPress,
            FirestoreAdsConfigFields.rewardBonusPercent:
                double.tryParse(rewardBonusCtrl.text.trim()) ?? 2,
            FirestoreAdsConfigFields.maxRewardedPerDay:
                int.tryParse(maxRewardsCtrl.text.trim()) ?? 5,
            FirestoreAdsConfigFields.maxRewardedPerMiningSession:
                int.tryParse(maxRewardsPerSessionCtrl.text.trim()) ?? 5,
            FirestoreAdsConfigFields.bannerAdUnitIdAndroid:
                bannerAndroidUnitIdCtrl.text.trim(),
            FirestoreAdsConfigFields.bannerAdUnitIdIos: bannerIosUnitIdCtrl.text
                .trim(),
            FirestoreAdsConfigFields.rewardedAdUnitIdAndroid:
                rewardedAndroidUnitIdCtrl.text.trim(),
            FirestoreAdsConfigFields.rewardedAdUnitIdIos: rewardedIosUnitIdCtrl
                .text
                .trim(),
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ads config saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _metric('Impressions Today', '—'),
              _metric('Earnings Today', '—'),
              _metric('Rewarded Ads Watched Today', '—'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 240,
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: Text('Ad performance chart')),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuration'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: enableRewarded,
                  onChanged: _loading
                      ? null
                      : (v) => setState(() => enableRewarded = v ?? true),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Enable rewarded ads'),
                ),
                CheckboxListTile(
                  value: enableBannerOnMiningPress,
                  onChanged: _loading
                      ? null
                      : (v) => setState(
                          () => enableBannerOnMiningPress = v ?? true,
                        ),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Show banner after mining start press'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rewardBonusCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ad reward percentage (%)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxRewardsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max rewarded per day per user',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: maxRewardsPerSessionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Max rewarded per mining session',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: bannerAndroidUnitIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Banner Ad Unit ID (Android)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: bannerIosUnitIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Banner Ad Unit ID (iOS)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: rewardedAndroidUnitIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Rewarded Ad Unit ID (Android)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rewardedIosUnitIdCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Rewarded Ad Unit ID (iOS)',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: Text(_loading ? 'Saving…' : 'Save'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
