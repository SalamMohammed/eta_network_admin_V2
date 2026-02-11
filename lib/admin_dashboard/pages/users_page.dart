import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

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

  late List<Map<String, dynamic>> allUsers;
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _initData();
    _filterUsers();
    searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    searchCtrl.removeListener(_onSearchChanged);
    searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filterUsers();
    });
  }

  void _initData() {
    allUsers = List.generate(20, (i) {
      return {
        'username': 'user_$i',
        'uid': 'UID$i'.padRight(12, 'X'),
        'email': i.isEven ? 'user_$i@example.com' : '',
        'country': ['US', 'UK', 'NG', 'EG'][i % 4],
        'rank': ['Explorer', 'Builder', 'Guardian'][i % 3],
        'totalPoints': 5000 * (i + 1),
        'hourlyRate': 0.15 + (i % 5) * 0.01,
        'streakDays': (i * 2) % 12,
        'invitedCount': i % 7,
        'createdAt': DateTime(
          2025,
          11,
          1,
        ).add(Duration(days: i)).toIso8601String(),
        'status': ['ACTIVE', 'BANNED', 'TEST'][i % 3],
      };
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
                    onSelectChanged: (_) => widget.onOpenDetail(u),
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
