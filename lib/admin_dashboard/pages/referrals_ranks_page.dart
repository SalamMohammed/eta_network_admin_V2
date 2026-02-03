import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../widgets/chart_placeholder.dart';
import '../../shared/firestore_constants.dart';
import '../../services/rank_engine.dart';

class _ReferrerRow {
  final String uid;
  final String name;
  final String rank;
  final int totalInvited;
  final int activeInvited;

  _ReferrerRow({
    required this.uid,
    required this.name,
    required this.rank,
    required this.totalInvited,
    required this.activeInvited,
  });
}

class ReferralsRanksPage extends StatefulWidget {
  const ReferralsRanksPage({super.key});

  @override
  State<ReferralsRanksPage> createState() => _ReferralsRanksPageState();
}

class _ReferralsRanksPageState extends State<ReferralsRanksPage> {
  bool _loading = true;
  List<_ReferrerRow> _rows = [];
  String _status = '';

  // Metrics
  int _totalUsers = 0;
  // We can add more metrics later

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadTopReferrers(),
      _loadGlobalMetrics(),
    ]);
  }

  Future<void> _loadGlobalMetrics() async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .count()
          .get();
      if (mounted) {
        setState(() {
          _totalUsers = agg.count ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error loading metrics: $e');
    }
  }

  Future<void> _loadTopReferrers() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _status = 'Loading top referrers...';
    });

    try {
      // 1. Get top referrers from stats
      // Note: This requires an index on referral_stats.totalInvited descending
      final statsSnap = await FirebaseFirestore.instance
          .collection(FirestoreConstants.referralStats)
          .orderBy('totalInvited', descending: true)
          .limit(20)
          .get();

      final List<_ReferrerRow> loadedRows = [];

      // 2. For each, get user doc and calculate active count
      for (final doc in statsSnap.docs) {
        final uid = doc.id;
        final statsData = doc.data();
        final totalInvited = (statsData['totalInvited'] as num?)?.toInt() ?? 0;

        // Parallel fetch: User Doc + Active Count
        final userDocFuture = FirebaseFirestore.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .get();

        final activeThreshold = DateTime.now().subtract(const Duration(hours: 48));
        final activeCountFuture = FirebaseFirestore.instance
            .collection(FirestoreConstants.users)
            .where(FirestoreUserFields.invitedBy, isEqualTo: uid)
            .where(FirestoreUserFields.lastMiningEnd, isGreaterThan: Timestamp.fromDate(activeThreshold))
            .count()
            .get();

        final results = await Future.wait([userDocFuture, activeCountFuture]);
        final userSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
        final activeAgg = results[1] as AggregateQuerySnapshot;

        final userData = userSnap.data() ?? {};
        final name = (userData[FirestoreUserFields.username] as String?) ?? uid;
        final rank = (userData[FirestoreUserFields.rank] as String?) ?? 'Explorer';

        loadedRows.add(_ReferrerRow(
          uid: uid,
          name: name,
          rank: rank,
          totalInvited: totalInvited,
          activeInvited: activeAgg.count ?? 0,
        ));
      }

      if (mounted) {
        setState(() {
          _rows = loadedRows;
          _loading = false;
          _status = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = 'Error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateRanksBatch({int limit = 50}) async {
    setState(() => _status = 'Updating ranks...');
    try {
      final qs = await FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .orderBy(FirestoreUserFields.createdAt, descending: true)
          .limit(limit)
          .get();
      
      int count = 0;
      for (final d in qs.docs) {
        await RankEngine.updateUserRank(d.id);
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Updated $count users')));
        // Reload table
        _loadTopReferrers();
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _status = '');
    }
  }

  Widget _metric(String label, String value) {
    return SizedBox(
      width: 240,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 16, runSpacing: 16, children: [
          _metric('Total Users', _totalUsers > 0 ? '$_totalUsers' : 'Loading...'),
          _metric('Average referrals per active user', '—'),
          _metric('Builders', '—'),
          _metric('Guardians', '—'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Top Referrers (Realtime Active Count)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (_loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),
            if (_status.isNotEmpty) Text(_status, style: const TextStyle(color: Colors.orange)),
            const SizedBox(height: 8),
            Row(children: [
              ElevatedButton(
                onPressed: _loading ? null : () async {
                  await _updateRanksBatch(limit: 50);
                },
                child: const Text('Update Ranks (Recent 50 Users)'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _loading ? null : _loadTopReferrers,
                child: const Text('Refresh Table'),
              ),
            ]),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Total Invited')),
                  DataColumn(label: Text('Active Invited (48h)')),
                ], 
                rows: _rows.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row.name)),
                    DataCell(Text(row.rank)),
                    DataCell(Text(row.totalInvited.toString())),
                    DataCell(Text(row.activeInvited.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                  ]);
                }).toList(),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const ChartPlaceholder(title: 'Users per rank'),
      ]),
    );
  }
}
