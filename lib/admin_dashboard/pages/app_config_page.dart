import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';
import '../../utils/firestore_helper.dart';

class AppConfigPage extends StatefulWidget {
  const AppConfigPage({super.key});
  @override
  State<AppConfigPage> createState() => _AppConfigPageState();
}

class _AppConfigPageState extends State<AppConfigPage> {
  final baseRateCtrl = TextEditingController();
  final sessionHoursCtrl = TextEditingController();
  bool deviceSingleUser = false;
  // Subscription config
  final revenueCatApiKeyCtrl = TextEditingController();
  final revenueCatWebhookAuthCtrl = TextEditingController();
  bool enableSubscriptions = false;
  bool sandboxMode = false;
  // User coin config
  final minRateCtrl = TextEditingController();
  final maxRateCtrl = TextEditingController();
  final maxLinksCtrl = TextEditingController();
  final maxDescCtrl = TextEditingController();
  bool allowImageUpload = false;
  bool allowUserRateEdit = true;
  final inviteeFixedCtrl = TextEditingController();
  final percentPerRefCtrl = TextEditingController();
  final maxRefCountCtrl = TextEditingController();
  final rewardedReferralMaxCountCtrl = TextEditingController();
  final List<TextEditingController> referralTierThresholdCtrls = [];
  final List<TextEditingController> referralTierPercentCtrls = [];
  final maxStreakDaysCtrl = TextEditingController();
  final maxStreakMultCtrl = TextEditingController();
  final rankRulesJsonCtrl = TextEditingController();
  final rankMultsJsonCtrl = TextEditingController();
  final List<TextEditingController> streakKeyCtrls = [];
  final List<TextEditingController> streakMultCtrls = [];
  final List<TextEditingController> rankNameCtrls = [];
  final List<TextEditingController> rankMinRefsCtrls = [];
  final List<TextEditingController> rankMinStreakCtrls = [];
  final List<TextEditingController> rankMultCtrls = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final general = await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .get();
    final g = general.data() ?? {};
    baseRateCtrl.text =
        ((g[FirestoreAppConfigFields.baseRate] as num?)?.toDouble() ?? 0.2)
            .toString();
    final sessionHours =
        (g[FirestoreAppConfigFields.sessionDurationHours] as num?)
            ?.toDouble() ??
        24.0;
    sessionHoursCtrl.text = sessionHours == sessionHours.roundToDouble()
        ? sessionHours.toInt().toString()
        : sessionHours.toString();
    deviceSingleUser =
        ((g[FirestoreAppConfigFields.deviceSingleUserEnforced] as bool?) ??
        false);
    revenueCatApiKeyCtrl.text =
        (g[FirestoreAppConfigFields.revenueCatApiKey] as String?) ?? '';
    revenueCatWebhookAuthCtrl.text =
        (g[FirestoreAppConfigFields.revenueCatWebhookAuth] as String?) ?? '';
    enableSubscriptions =
        ((g[FirestoreAppConfigFields.enableSubscriptions] as bool?) ?? false);
    sandboxMode = ((g[FirestoreAppConfigFields.sandboxMode] as bool?) ?? false);

    final referrals = await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.referrals)
        .get();
    final r = referrals.data() ?? {};
    inviteeFixedCtrl.text =
        ((r[FirestoreReferralConfigFields.inviteeFixedBonusPoints] as num?)
                    ?.toDouble() ??
                0.0)
            .toString();
    percentPerRefCtrl.text =
        ((r[FirestoreReferralConfigFields.referrerPercentPerReferral] as num?)
                    ?.toDouble() ??
                0.0)
            .toString();
    maxRefCountCtrl.text =
        ((r[FirestoreReferralConfigFields.referrerMaxCount] as num?)?.toInt() ??
                100)
            .toString();
    rewardedReferralMaxCountCtrl.text =
        ((r[FirestoreReferralConfigFields.rewardedReferralMaxCount] as num?)
                    ?.toInt() ??
                (r[FirestoreReferralConfigFields.referrerMaxCount] as num?)
                    ?.toInt() ??
                100)
            .toString();

    final Map<String, dynamic> referralTiers =
        (r[FirestoreReferralConfigFields.referralBonusTiers]
            as Map<String, dynamic>?) ??
        {};
    referralTierThresholdCtrls.clear();
    referralTierPercentCtrls.clear();
    for (final e in referralTiers.entries) {
      referralTierThresholdCtrls.add(TextEditingController(text: e.key));
      referralTierPercentCtrls.add(
        TextEditingController(
          text: ((e.value as num?)?.toDouble() ?? 0.0).toString(),
        ),
      );
    }

    final streak = await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.streak)
        .get();
    final s = streak.data() ?? {};
    maxStreakDaysCtrl.text =
        ((s[FirestoreStreakConfigFields.maxStreakDays] as num?)?.toInt() ?? 15)
            .toString();
    maxStreakMultCtrl.text =
        ((s[FirestoreStreakConfigFields.maxStreakMultiplier] as num?)
                    ?.toDouble() ??
                2.0)
            .toString();
    final Map<String, dynamic> table =
        (s[FirestoreAppConfigFields.streakBonusTable]
            as Map<String, dynamic>?) ??
        {};
    streakKeyCtrls.clear();
    streakMultCtrls.clear();
    for (final e in table.entries) {
      streakKeyCtrls.add(TextEditingController(text: e.key));
      streakMultCtrls.add(
        TextEditingController(
          text: ((e.value as num?)?.toDouble() ?? 1.0).toString(),
        ),
      );
    }

    final ranks = await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.ranks)
        .get();
    final rk = ranks.data() ?? {};
    final Map<String, dynamic> rules =
        (rk[FirestoreRankConfigFields.rankRules] as Map<String, dynamic>?) ??
        {};
    final Map<String, dynamic> mults =
        (rk[FirestoreRankConfigFields.rankMultipliers]
            as Map<String, dynamic>?) ??
        {};
    final Set<String> allRanks = {...rules.keys, ...mults.keys};
    rankNameCtrls.clear();
    rankMinRefsCtrls.clear();
    rankMinStreakCtrls.clear();
    rankMultCtrls.clear();
    for (final name in allRanks) {
      final rule = (rules[name] as Map<String, dynamic>?) ?? {};
      rankNameCtrls.add(TextEditingController(text: name));
      rankMinRefsCtrls.add(
        TextEditingController(
          text: ((rule['minActiveReferrals'] as num?)?.toInt() ?? 0).toString(),
        ),
      );
      rankMinStreakCtrls.add(
        TextEditingController(
          text: ((rule['minStreakDays'] as num?)?.toInt() ?? 0).toString(),
        ),
      );
      rankMultCtrls.add(
        TextEditingController(
          text: ((mults[name] as num?)?.toDouble() ?? 1.0).toString(),
        ),
      );
    }
    setState(() {});
  }

  Future<void> _testApiKey(String apiKey) async {
    if (apiKey.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an API Key')),
        );
      }
      return;
    }

    // Determine platform hint
    String platform = 'android'; // Default
    if (apiKey.startsWith('appl_')) {
      platform = 'ios';
    } else if (apiKey.startsWith('rcb_')) {
      platform = 'web'; // Stripe
    }

    try {
      // We use a dummy user ID to check if the key is authorized.
      // 404 means user not found (Authorized), 401 means Unauthorized (Invalid Key).
      final uri = Uri.parse(
        'https://api.revenuecat.com/v1/subscribers/app_config_test_user',
      );
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'X-Platform': platform,
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 404) {
        // 200: User exists, 404: User doesn't exist but request was authorized
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection Successful: Valid API Key'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection Failed: Invalid API Key (401)'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection Error: Code ${response.statusCode}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGeneral() async {
    final parsedSessionHours = double.tryParse(sessionHoursCtrl.text.trim());
    final sessionHours =
        (parsedSessionHours != null && parsedSessionHours > 0.0)
        ? parsedSessionHours
        : 24.0;
    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.general)
        .set({
          FirestoreAppConfigFields.baseRate:
              double.tryParse(baseRateCtrl.text) ?? 0.2,
          FirestoreAppConfigFields.sessionDurationHours: sessionHours,
          FirestoreAppConfigFields.deviceSingleUserEnforced: deviceSingleUser,
          FirestoreAppConfigFields.revenueCatApiKey: revenueCatApiKeyCtrl.text
              .trim(),
          FirestoreAppConfigFields.revenueCatWebhookAuth:
              revenueCatWebhookAuthCtrl.text.trim(),
          FirestoreAppConfigFields.enableSubscriptions: enableSubscriptions,
          FirestoreAppConfigFields.sandboxMode: sandboxMode,
        }, SetOptions(merge: true));
  }

  Future<void> _saveUserCoinConfig() async {
    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.userCoin)
        .set({
          FirestoreAppConfigFields.minRatePerHour:
              double.tryParse(minRateCtrl.text) ?? 0.01,
          FirestoreAppConfigFields.maxRatePerHour:
              double.tryParse(maxRateCtrl.text) ?? 10.0,
          FirestoreAppConfigFields.maxSocialLinks:
              int.tryParse(maxLinksCtrl.text) ?? 6,
          FirestoreAppConfigFields.maxDescriptionLength:
              int.tryParse(maxDescCtrl.text) ?? 500,
          FirestoreAppConfigFields.allowImageUpload: allowImageUpload,
          FirestoreAppConfigFields.allowUserRateEdit: allowUserRateEdit,
        }, SetOptions(merge: true));
  }

  Future<void> _saveReferrals() async {
    final Map<String, dynamic> tiers = {};
    for (int i = 0; i < referralTierThresholdCtrls.length; i++) {
      final key = referralTierThresholdCtrls[i].text.trim();
      final percent =
          double.tryParse(referralTierPercentCtrls[i].text.trim()) ?? 0.0;
      if (key.isEmpty) continue;
      if (percent <= 0.0) continue;
      tiers[key] = percent;
    }

    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.referrals)
        .set({
          FirestoreReferralConfigFields.inviteeFixedBonusPoints:
              double.tryParse(inviteeFixedCtrl.text) ?? 0.0,
          FirestoreReferralConfigFields.referrerPercentPerReferral:
              double.tryParse(percentPerRefCtrl.text) ?? 0.0,
          FirestoreReferralConfigFields.referrerMaxCount:
              int.tryParse(maxRefCountCtrl.text) ?? 100,
          FirestoreReferralConfigFields.rewardedReferralMaxCount:
              int.tryParse(rewardedReferralMaxCountCtrl.text) ?? 100,
          if (tiers.isNotEmpty)
            FirestoreReferralConfigFields.referralBonusTiers: tiers,
        }, SetOptions(merge: true));
  }

  Future<void> _saveStreak() async {
    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.streak)
        .set({
          FirestoreStreakConfigFields.maxStreakDays:
              int.tryParse(maxStreakDaysCtrl.text) ?? 15,
          FirestoreStreakConfigFields.maxStreakMultiplier:
              double.tryParse(maxStreakMultCtrl.text) ?? 2.0,
        }, SetOptions(merge: true));
  }

  Future<void> _saveStreakTable() async {
    final Map<String, dynamic> table = {};
    for (int i = 0; i < streakKeyCtrls.length; i++) {
      final key = streakKeyCtrls[i].text.trim();
      final mult = double.tryParse(streakMultCtrls[i].text.trim()) ?? 1.0;
      if (key.isEmpty) continue;
      table[key] = mult;
    }
    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.streak)
        .set({
          FirestoreAppConfigFields.streakBonusTable: table,
        }, SetOptions(merge: true));
  }

  Future<void> _saveRanks() async {
    final Map<String, dynamic> rules = {};
    final Map<String, dynamic> mults = {};
    for (int i = 0; i < rankNameCtrls.length; i++) {
      final name = rankNameCtrls[i].text.trim();
      if (name.isEmpty) continue;
      final minRefs = int.tryParse(rankMinRefsCtrls[i].text.trim()) ?? 0;
      final minStreak = int.tryParse(rankMinStreakCtrls[i].text.trim()) ?? 0;
      final mult = double.tryParse(rankMultCtrls[i].text.trim()) ?? 1.0;
      rules[name] = {'minActiveReferrals': minRefs, 'minStreakDays': minStreak};
      mults[name] = mult;
    }
    await FirestoreHelper.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.ranks)
        .set({
          FirestoreRankConfigFields.rankRules: rules,
          FirestoreRankConfigFields.rankMultipliers: mults,
        }, SetOptions(merge: true));
  }

  void _addStreakRow() {
    streakKeyCtrls.add(TextEditingController());
    streakMultCtrls.add(TextEditingController(text: '1.0'));
    setState(() {});
  }

  void _removeStreakRow(int i) {
    streakKeyCtrls.removeAt(i);
    streakMultCtrls.removeAt(i);
    setState(() {});
  }

  void _addRankRow() {
    rankNameCtrls.add(TextEditingController());
    rankMinRefsCtrls.add(TextEditingController(text: '0'));
    rankMinStreakCtrls.add(TextEditingController(text: '0'));
    rankMultCtrls.add(TextEditingController(text: '1.0'));
    setState(() {});
  }

  void _removeRankRow(int i) {
    rankNameCtrls.removeAt(i);
    rankMinRefsCtrls.removeAt(i);
    rankMinStreakCtrls.removeAt(i);
    rankMultCtrls.removeAt(i);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Earning Configuration (app_config)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Base Rate & Limits',
            child: Row(
              children: [
                _field('Base rate per hour', baseRateCtrl),
                const SizedBox(width: 12),
                _field('Session duration hours', sessionHoursCtrl),
                const SizedBox(width: 12),
                Expanded(
                  child: CheckboxListTile(
                    value: deviceSingleUser,
                    onChanged: (v) =>
                        setState(() => deviceSingleUser = v ?? false),
                    title: const Text('Enforce single account per device'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveGeneral,
                  child: const Text('Save changes'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Subscription Settings',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _field('RevenueCat API Key', revenueCatApiKeyCtrl),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _testApiKey(revenueCatApiKeyCtrl.text.trim()),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Test Connection'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: revenueCatWebhookAuthCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Webhook Authorization Token',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: enableSubscriptions,
                        onChanged: (v) =>
                            setState(() => enableSubscriptions = v ?? false),
                        title: const Text('Enable Subscriptions'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        value: sandboxMode,
                        onChanged: (v) =>
                            setState(() => sandboxMode = v ?? false),
                        title: const Text('Sandbox Mode'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveGeneral,
                      child: const Text('Save General'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'User Coin Limits',
            child: Column(
              children: [
                Row(
                  children: [
                    _field('Min rate/hour', minRateCtrl),
                    const SizedBox(width: 12),
                    _field('Max rate/hour', maxRateCtrl),
                    const SizedBox(width: 12),
                    _field('Max social links', maxLinksCtrl),
                    const SizedBox(width: 12),
                    _field('Max description length', maxDescCtrl),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: allowImageUpload,
                        onChanged: (v) =>
                            setState(() => allowImageUpload = v ?? false),
                        title: const Text('Allow image upload'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        value: allowUserRateEdit,
                        onChanged: (v) =>
                            setState(() => allowUserRateEdit = v ?? true),
                        title: const Text('Allow user to edit rate'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveUserCoinConfig,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Referral Bonus Settings',
            child: Column(
              children: [
                Row(
                  children: [
                    _field('Invitee fixed bonus points', inviteeFixedCtrl),
                    const SizedBox(width: 12),
                    _field('Referrer % per referral', percentPerRefCtrl),
                    const SizedBox(width: 12),
                    _field('Max referrer count', maxRefCountCtrl),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _field(
                      'Rewarded referrals (global cap)',
                      rewardedReferralMaxCountCtrl,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < referralTierThresholdCtrls.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: referralTierThresholdCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Less than (active referrals)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: referralTierPercentCtrls[i],
                              decoration: const InputDecoration(
                                labelText: '% per referral',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                referralTierThresholdCtrls.removeAt(i);
                                referralTierPercentCtrls.removeAt(i);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              referralTierThresholdCtrls.add(
                                TextEditingController(),
                              );
                              referralTierPercentCtrls.add(
                                TextEditingController(text: '0'),
                              );
                            });
                          },
                          child: const Text('Add Tier'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saveReferrals,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Streak Bonus Settings',
            child: Column(
              children: [
                Row(
                  children: [
                    _field('Max streak days', maxStreakDaysCtrl),
                    const SizedBox(width: 12),
                    _field('Max streak multiplier', maxStreakMultCtrl),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    for (int i = 0; i < streakKeyCtrls.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: streakKeyCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Day or range (e.g., 5 or 4-7)',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: streakMultCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Multiplier',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _removeStreakRow(i),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addStreakRow,
                          child: const Text('Add Rule'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveStreakTable,
                          child: const Text('Save'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveStreak,
                          child: const Text('Save Caps'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            title: 'Rank Rules',
            child: Column(
              children: [
                Column(
                  children: [
                    for (int i = 0; i < rankNameCtrls.length; i++)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: rankNameCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Rank name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rankMinRefsCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Min active referrals',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rankMinStreakCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Min streak days',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: rankMultCtrls[i],
                              decoration: const InputDecoration(
                                labelText: 'Multiplier',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _removeRankRow(i),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _addRankRow,
                          child: const Text('Add Rank'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _saveRanks,
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Expanded(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
