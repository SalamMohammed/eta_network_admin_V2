import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../shared/firestore_constants.dart';
import '../../shared/theme/colors.dart';

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralItem {
  final String username;
  final String status;
  final String joined;

  _ReferralItem({
    required this.username,
    required this.status,
    required this.joined,
  });
}

class _ReferralsPageState extends State<ReferralsPage> {
  String? _referralCode;
  bool _loading = true;
  int _totalInvited = 0;
  int _activeInvited = 0;
  List<_ReferralItem> _referrals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // 1. Get User Doc (Referral Code)
      final userDocFuture = FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .get();

      // 2. Prepare Referrals Query
      final referralsRef = FirebaseFirestore.instance
          .collection(FirestoreConstants.referrals)
          .where(FirestoreReferralFields.inviterId, isEqualTo: uid);

      // 3. Count Aggregations (Economic)
      final countTotalFuture = referralsRef.count().get();
      final countActiveFuture = referralsRef
          .where(FirestoreReferralFields.isActive, isEqualTo: true)
          .count()
          .get();

      // 4. Fetch Recent Referrals (Economic Limit)
      final recentReferralsFuture = referralsRef
          .orderBy(FirestoreReferralFields.timestamp, descending: true)
          .limit(20)
          .get();

      final results = await Future.wait([
        userDocFuture,
        countTotalFuture,
        countActiveFuture,
        recentReferralsFuture,
      ]);

      final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final countTotalAgg = results[1] as AggregateQuerySnapshot;
      final countActiveAgg = results[2] as AggregateQuerySnapshot;
      final recentSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;

      // Process User Doc
      String? code;
      if (userDoc.exists) {
        code = userDoc.data()?[FirestoreUserFields.referralCode] as String?;
      }

      // Process Referrals List
      final List<_ReferralItem> items = [];
      final List<String> missingUserIds = [];
      final Map<String, _ReferralItem> tempItems = {};

      for (final doc in recentSnap.docs) {
        final data = doc.data();
        final inviteeId =
            data[FirestoreReferralFields.inviteeId] as String? ?? '';
        final ts =
            (data[FirestoreReferralFields.timestamp] as Timestamp?)?.toDate() ??
            DateTime.now();
        final dateStr =
            '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
        final isActive =
            (data[FirestoreReferralFields.isActive] as bool?) ?? false;
        final status = isActive ? 'Active' : 'Not Started';

        // Check if username is already in referral doc (Optimization)
        final savedUsername =
            data[FirestoreReferralFields.inviteeUsername] as String?;

        if (savedUsername != null && savedUsername.isNotEmpty) {
          items.add(
            _ReferralItem(
              username: savedUsername,
              status: status,
              joined: dateStr,
            ),
          );
        } else if (inviteeId.isNotEmpty) {
          // Need to fetch username
          missingUserIds.add(inviteeId);
          tempItems[inviteeId] = _ReferralItem(
            username: 'Loading...', // Placeholder
            status: status,
            joined: dateStr,
          );
        }
      }

      // Fetch missing usernames if any
      if (missingUserIds.isNotEmpty) {
        // We can't do whereIn for > 10 easily, but for 20 items it's max 2 batches or simple loop
        // Since we limited to 20, we can just do individual fetches or batches.
        // For simplicity and "economic" (read count is same), let's use Future.wait
        // Note: whereIn is cheaper on latency but same on billable reads.
        final userFutures = missingUserIds
            .map(
              (id) => FirebaseFirestore.instance
                  .collection(FirestoreConstants.users)
                  .doc(id)
                  .get(),
            )
            .toList();
        final userDocs = await Future.wait(userFutures);

        for (final uDoc in userDocs) {
          if (!uDoc.exists) continue;
          final uData = uDoc.data();
          final uName =
              (uData?[FirestoreUserFields.username] as String?) ?? 'Unknown';
          final id = uDoc.id;
          if (tempItems.containsKey(id)) {
            final old = tempItems[id]!;
            tempItems[id] = _ReferralItem(
              username: uName,
              status: old.status,
              joined: old.joined,
            );
          }
        }
      }

      // Combine items (those with saved username + fetched ones)
      // We want to maintain order from recentSnap (timestamp desc)
      final List<_ReferralItem> finalOrderedItems = [];
      for (final doc in recentSnap.docs) {
        final inviteeId =
            doc.data()[FirestoreReferralFields.inviteeId] as String? ?? '';
        final savedUsername =
            doc.data()[FirestoreReferralFields.inviteeUsername] as String?;

        if (savedUsername != null && savedUsername.isNotEmpty) {
          final ts =
              (doc.data()[FirestoreReferralFields.timestamp] as Timestamp?)
                  ?.toDate() ??
              DateTime.now();
          final dateStr =
              '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
          final isActive =
              (doc.data()[FirestoreReferralFields.isActive] as bool?) ?? false;
          final status = isActive ? 'Active' : 'Not Started';
          finalOrderedItems.add(
            _ReferralItem(
              username: savedUsername,
              status: status,
              joined: dateStr,
            ),
          );
        } else if (tempItems.containsKey(inviteeId)) {
          finalOrderedItems.add(tempItems[inviteeId]!);
        }
      }

      if (mounted) {
        setState(() {
          _referralCode = code;
          _totalInvited = countTotalAgg.count ?? 0;
          _activeInvited = countActiveAgg.count ?? 0;
          _referrals = finalOrderedItems;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading referrals: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _copyCode() async {
    if (_referralCode == null) return;
    await Clipboard.setData(ClipboardData(text: _referralCode!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied to clipboard')),
    );
  }

  Future<void> _shareLink() async {
    if (_referralCode == null) return;
    final text =
        'Join me on Eta Network! Use my code: $_referralCode https://eta.network/join';
    try {
      // ignore: deprecated_member_use
      await Share.share(text);
    } catch (e) {
      debugPrint('Share error: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy this link to share:'),
              const SizedBox(height: 8),
              SelectableText(text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard')),
                );
                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Referrals'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Grow Your Team. Earn More.'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (_loading && _referralCode == null)
                    const SizedBox(
                      height: 40,
                      width: 40,
                      child: CircularProgressIndicator(),
                    )
                  else
                    Text(
                      _referralCode ?? '—',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _loading || _referralCode == null
                            ? null
                            : _shareLink,
                        child: const Text('Share Link'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _loading || _referralCode == null
                            ? null
                            : _copyCode,
                        child: const Text('Copy Code'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    'Total Invited',
                    _loading ? '...' : '$_totalInvited',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _metric(
                    'Active Invited',
                    _loading ? '...' : '$_activeInvited',
                  ),
                ),
                // Removed Team Power as requested
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _referrals.isEmpty && !_loading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No referrals yet')),
                    )
                  : Column(
                      children: [
                        for (final u in _referrals)
                          ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.secondaryAccent,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            title: Text(u.username),
                            subtitle: Text('Joined: ${u.joined}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (u.status == 'Active')
                                    ? AppColors.primaryAccent
                                    : AppColors.vipAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                u.status,
                                style: const TextStyle(
                                  color: AppColors.deepLayer,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('How It Works'),
              children: const [
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Invite friends to grow your team. Each active invite boosts your rank and earning potential.',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
