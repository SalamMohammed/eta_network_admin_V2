import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';

class UserDetailPage extends StatefulWidget {
  final Map<String, dynamic>? user;
  const UserDetailPage({super.key, this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> rawData = widget.user ?? {};

    // Helper to extract data from consolidated or legacy structure
    dynamic getValue(String field) {
      if (rawData.containsKey(FirestoreUserFields.meta)) {
        final meta = rawData[FirestoreUserFields.meta] as Map<String, dynamic>?;
        if (meta != null && meta.containsKey(field)) return meta[field];
      }
      if (rawData.containsKey(FirestoreUserFields.stats)) {
        final stats =
            rawData[FirestoreUserFields.stats] as Map<String, dynamic>?;
        if (stats != null && stats.containsKey(field)) return stats[field];
      }
      if (rawData.containsKey(FirestoreUserFields.mining)) {
        final mining =
            rawData[FirestoreUserFields.mining] as Map<String, dynamic>?;
        if (mining != null && mining.containsKey(field)) return mining[field];
      }
      if (rawData.containsKey(FirestoreUserFields.manager)) {
        final manager =
            rawData[FirestoreUserFields.manager] as Map<String, dynamic>?;
        if (manager != null && manager.containsKey(field))
          return manager[field];
      }
      if (rawData.containsKey(FirestoreUserFields.wallet)) {
        final wallet =
            rawData[FirestoreUserFields.wallet] as Map<String, dynamic>?;
        if (wallet != null && wallet.containsKey(field)) return wallet[field];
      }
      return rawData[field];
    }

    final u = {
      'username': getValue(FirestoreUserFields.username) ?? '—',
      'uid': getValue(FirestoreUserFields.uid) ?? '—',
      'email': getValue(FirestoreUserFields.email) ?? '—',
      'country': getValue(FirestoreUserFields.country) ?? '—',
      'rank': getValue(FirestoreUserFields.rank) ?? 'Explorer',
      'streakDays': getValue(FirestoreUserFields.streakDays) ?? 0,
      'totalPoints': getValue(FirestoreUserFields.totalPoints) ?? 0,
      'hourlyRate': getValue(FirestoreUserFields.hourlyRate) ?? 0.0,
      'createdAt': getValue(FirestoreUserFields.createdAt)?.toString() ?? '—',
      'updatedAt': getValue(FirestoreUserFields.updatedAt)?.toString() ?? '—',
      'deviceId': getValue(FirestoreUserFields.deviceId) ?? '—',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u['username'],
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          Text('uid: ${u['uid']}'),
                          Text('email: ${u['email']}'),
                          Text('country: ${u['country']}'),
                          Text('deviceId: ${u['deviceId']}'),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.vipAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              u['rank'],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          Text('Streak: ${u['streakDays']}'),
                          Text('TotalPoints: ${u['totalPoints']}'),
                          Text('HourlyRate: ${u['hourlyRate']}'),
                          Text('Joined: ${u['createdAt']}'),
                          Text('Last activity: ${u['updatedAt']}'),
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showAdjustBalance(context),
                      child: const Text('Adjust Balance'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Change Rank'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Reset Streak'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Ban / Unban'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Send Test Notification'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                TabBar(
                  controller: _tab,
                  tabs: const [
                    Tab(text: 'Mining Sessions & Earnings'),
                    Tab(text: 'Point Logs'),
                    Tab(text: 'Referrals'),
                    Tab(text: 'Notifications & Tokens'),
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildMiningSessions(),
                      _buildPointLogs(),
                      _buildReferrals(),
                      _buildNotifications(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiningSessions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Latest Sessions'),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.deepLayer,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.deepLayer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Current session status: Active'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointLogs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Point Logs'),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Timestamp')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Amount')),
                  DataColumn(label: Text('Description')),
                ],
                rows: List.generate(10, (i) {
                  return const DataRow(
                    cells: [
                      DataCell(Text('2025-11-25 10:00')),
                      DataCell(Text('tap')),
                      DataCell(Text('+10')),
                      DataCell(Text('Tap mine')),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferrals() {
    final Map<String, dynamic> rawData = widget.user ?? {};
    
    // Get inviter
    String inviterId = '—';
    if (rawData.containsKey(FirestoreUserFields.stats)) {
      inviterId = (rawData[FirestoreUserFields.stats] as Map<String, dynamic>?)?[FirestoreUserFields.invitedBy] ?? '—';
    } else {
      inviterId = rawData[FirestoreUserFields.invitedBy] ?? '—';
    }

    // Get consolidated referrals
    List<dynamic> recent = [];
    int total = 0;
    int active = 0;

    if (rawData.containsKey(FirestoreUserFields.referrals)) {
      final refMap = rawData[FirestoreUserFields.referrals] as Map<String, dynamic>?;
      if (refMap != null) {
        recent = refMap[FirestoreUserFields.recentReferrals] ?? [];
        total = refMap[FirestoreUserFields.totalReferrals] ?? 0;
        active = refMap[FirestoreUserFields.activeReferrals] ?? 0;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Invited By: $inviterId', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Total Referrals: $total • Active: $active'),
          const SizedBox(height: 16),
          const Text('Recent Referrals (Consolidated)', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No consolidated referral data found.'),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Username')),
                    DataColumn(label: Text('Joined At')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: recent.map((r) {
                    final data = r as Map<String, dynamic>;
                    final bool isActive = data['isActive'] ?? false;
                    return DataRow(
                      cells: [
                        DataCell(Text(data['username'] ?? '—')),
                        DataCell(Text(data['timestamp']?.toString().split('T').first ?? '—')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primaryAccent : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: isActive ? AppColors.deepLayer : Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('FCM Tokens'),
          const SizedBox(height: 8),
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.deepLayer,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(value: false, onChanged: (_) {}),
              const Text('Disable all notifications for this user.'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showAdjustBalance(BuildContext context) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    String type = 'bonus';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: const Text('Adjust Balance'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(labelText: 'Amount (+/-)'),
                ),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(labelText: 'Reason'),
                ),
                DropdownButton<String>(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: 'bonus', child: Text('bonus')),
                    DropdownMenuItem(
                      value: 'correction',
                      child: Text('correction'),
                    ),
                    DropdownMenuItem(value: 'penalty', child: Text('penalty')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'bonus'),
                ),
                const SizedBox(height: 8),
                const Text('This will create a point_logs entry.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
