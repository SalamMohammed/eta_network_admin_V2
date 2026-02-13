import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';
import '../../utils/firestore_helper.dart';

class UsersPage extends StatefulWidget {
  final void Function(Map<String, dynamic> user) onOpenDetail;
  const UsersPage({super.key, required this.onOpenDetail});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final TextEditingController searchCtrl = TextEditingController();
  String rank = 'All';
  String country = 'All';
  String streak = 'All';
  RangeValues pointsRange = const RangeValues(0, 100000);
  DateTimeRange? dateRange;

  late List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    searchCtrl.addListener(_onSearchChanged);
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    try {
      final qs = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .limit(100)
          .get();

      allUsers = qs.docs.map((doc) {
        final data = doc.data();

        // Helper to extract data from consolidated or legacy structure
        dynamic getValue(String field) {
          if (data.containsKey(FirestoreUserFields.meta)) {
            final meta =
                data[FirestoreUserFields.meta] as Map<String, dynamic>?;
            if (meta != null && meta.containsKey(field)) return meta[field];
          }
          if (data.containsKey(FirestoreUserFields.stats)) {
            final stats =
                data[FirestoreUserFields.stats] as Map<String, dynamic>?;
            if (stats != null && stats.containsKey(field)) return stats[field];
          }
          if (data.containsKey(FirestoreUserFields.mining)) {
            final mining =
                data[FirestoreUserFields.mining] as Map<String, dynamic>?;
            if (mining != null && mining.containsKey(field))
              return mining[field];
          }
          if (data.containsKey(FirestoreUserFields.manager)) {
            final manager =
                data[FirestoreUserFields.manager] as Map<String, dynamic>?;
            if (manager != null && manager.containsKey(field))
              return manager[field];
          }
          if (data.containsKey(FirestoreUserFields.wallet)) {
            final wallet =
                data[FirestoreUserFields.wallet] as Map<String, dynamic>?;
            if (wallet != null && wallet.containsKey(field))
              return wallet[field];
          }
          return data[field];
        }

        return {
          'username': getValue(FirestoreUserFields.username) ?? '—',
          'uid': getValue(FirestoreUserFields.uid) ?? doc.id,
          'email': getValue(FirestoreUserFields.email) ?? '—',
          'country': getValue(FirestoreUserFields.country) ?? '—',
          'rank': getValue(FirestoreUserFields.rank) ?? 'Explorer',
          'totalPoints': getValue(FirestoreUserFields.totalPoints) ?? 0,
          'hourlyRate': getValue(FirestoreUserFields.hourlyRate) ?? 0.0,
          'streakDays': getValue(FirestoreUserFields.streakDays) ?? 0,
          'invitedCount': 0, // Would need separate query or aggregation
          'createdAt': getValue(FirestoreUserFields.createdAt) is Timestamp
              ? (getValue(FirestoreUserFields.createdAt) as Timestamp)
                    .toDate()
                    .toIso8601String()
              : getValue(FirestoreUserFields.createdAt)?.toString() ??
                    DateTime.now().toIso8601String(),
          'status': 'ACTIVE',
          // Keep raw data for detail page
          '_raw': data,
        };
      }).toList();

      _filterUsers();
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _filterUsers();
    });
  }

  void _filterUsers() {
    final query = searchCtrl.text.toLowerCase();

    filteredUsers = allUsers.where((user) {
      // 1. Text Search (username, uid, email)
      final username = (user['username'] ?? '').toString().toLowerCase();
      final uid = (user['uid'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
          username.contains(query) ||
          uid.contains(query) ||
          email.contains(query);

      if (!matchesSearch) return false;

      // 2. Rank Filter
      if (rank != 'All' && user['rank'] != rank) return false;

      // 3. Country Filter
      if (country != 'All' && user['country'] != country) return false;

      // 4. Streak Filter
      if (streak != 'All') {
        final s = user['streakDays'] as int;
        if (streak == '0' && s != 0) return false;
        if (streak == '1–3' && (s < 1 || s > 3)) return false;
        if (streak == '4–7' && (s < 4 || s > 7)) return false;
        if (streak == '8+' && s < 8) return false;
      }

      // 5. Points Range
      final pts = (user['totalPoints'] as int).toDouble();
      if (pts < pointsRange.start || pts > pointsRange.end) return false;

      // 6. Date Range (Created At)
      if (dateRange != null) {
        final created = DateTime.parse(user['createdAt']);
        if (created.isBefore(dateRange!.start) ||
            created.isAfter(dateRange!.end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Users',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.deepLayer,
                    hintText: 'Search username, uid, email',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.secondaryAccent,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primaryBackground.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primaryBackground.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () {}, child: const Text('Export CSV')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                child: const Text('Add Test User'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: rank,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('Rank: All')),
                  DropdownMenuItem(value: 'Explorer', child: Text('Explorer')),
                  DropdownMenuItem(value: 'Builder', child: Text('Builder')),
                  DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
                ],
                onChanged: (v) => setState(() {
                  rank = v ?? 'All';
                  _filterUsers();
                }),
              ),
              DropdownButton<String>(
                value: country,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('Country: All')),
                  DropdownMenuItem(value: 'US', child: Text('US')),
                  DropdownMenuItem(value: 'UK', child: Text('UK')),
                  DropdownMenuItem(value: 'NG', child: Text('NG')),
                  DropdownMenuItem(value: 'EG', child: Text('EG')),
                ],
                onChanged: (v) => setState(() {
                  country = v ?? 'All';
                  _filterUsers();
                }),
              ),
              DropdownButton<String>(
                value: streak,
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('Streak: All')),
                  DropdownMenuItem(value: '0', child: Text('0')),
                  DropdownMenuItem(value: '1–3', child: Text('1–3')),
                  DropdownMenuItem(value: '4–7', child: Text('4–7')),
                  DropdownMenuItem(value: '8+', child: Text('8+')),
                ],
                onChanged: (v) => setState(() {
                  streak = v ?? 'All';
                  _filterUsers();
                }),
              ),
              SizedBox(
                width: 240,
                child: Column(
                  children: [
                    const Text('Total Points Range'),
                    RangeSlider(
                      values: pointsRange,
                      min: 0,
                      max: 200000,
                      divisions: 20,
                      labels: RangeLabels(
                        pointsRange.start.round().toString(),
                        pointsRange.end.round().toString(),
                      ),
                      onChanged: (v) => setState(() {
                        pointsRange = v;
                        _filterUsers();
                      }),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year, now.month, now.day),
                  );
                  if (picked != null) {
                    setState(() {
                      dateRange = picked;
                      _filterUsers();
                    });
                  }
                },
                child: const Text('Pick Date Range'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.secondaryAccent.withValues(alpha: 0.3),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('uid')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Country')),
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Total Points')),
                  DataColumn(label: Text('Hourly Rate')),
                  DataColumn(label: Text('Streak Days')),
                  DataColumn(label: Text('Invited Count')),
                  DataColumn(label: Text('Created At')),
                  DataColumn(label: Text('Status')),
                ],
                rows: filteredUsers.map((u) {
                  return DataRow(
                    cells: [
                      DataCell(Text(u['username'])),
                      DataCell(Text((u['uid'] as String).substring(0, 8))),
                      DataCell(Text(u['email'] ?? '')),
                      DataCell(Text(u['country'])),
                      DataCell(Text(u['rank'])),
                      DataCell(Text('${u['totalPoints']}')),
                      DataCell(Text('${u['hourlyRate']}')),
                      DataCell(Text('${u['streakDays']}')),
                      DataCell(Text('${u['invitedCount']}')),
                      DataCell(
                        Text(u['createdAt'].toString().substring(0, 10)),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: u['status'] == 'BANNED'
                                  ? AppColors.vipAccent
                                  : AppColors.primaryAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              u['status'],
                              style: const TextStyle(
                                color: AppColors.deepLayer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    onSelectChanged: (_) => widget.onOpenDetail(u['_raw'] ?? u),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
