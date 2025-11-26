import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  bool enableSessionEnd = true;
  bool enableStreakReminders = true;
  bool disableAll = false;

  final List<Map<String, dynamic>> templates = [
    {
      'name': 'Session End',
      'title': 'Your session ended',
      'body': 'Hi {username}, your mining session has ended.',
      'active': true,
    },
    {
      'name': 'Streak Warning',
      'title': 'Keep your streak',
      'body': 'You are at {streakDays} days. Don\'t miss today!',
      'active': true,
    },
  ];
  int tmplPage = 0;

  final List<Map<String, String>> logs = List.generate(
    50,
    (i) => {
      'timestamp': '2025-11-25 10:${(i % 60).toString().padLeft(2, '0')}',
      'type': i.isEven ? 'Session End' : 'Streak Warning',
      'username': 'user_$i',
      'status': i % 3 == 0 ? 'Delivered' : 'Queued',
    },
  );
  int logsPage = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Checkbox(
                value: disableAll,
                onChanged: (v) => setState(() => disableAll = v ?? false),
              ),
              const Text('Disable all notifications'),
            ],
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
                    Tab(text: 'System Rules'),
                    Tab(text: 'Templates'),
                    Tab(text: 'Logs'),
                  ],
                ),
                SizedBox(
                  height: 520,
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _buildSystemRules(context),
                      _buildTemplates(context),
                      _buildLogs(context),
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

  Widget _buildSystemRules(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: enableSessionEnd,
                onChanged: (v) => setState(() => enableSessionEnd = v),
              ),
              const SizedBox(width: 8),
              const Text('Enable session end reminders'),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Send push ~24 hours after a mining session starts.'),
          const SizedBox(height: 16),
          Row(
            children: [
              Switch(
                value: enableStreakReminders,
                onChanged: (v) => setState(() => enableStreakReminders = v),
              ),
              const SizedBox(width: 8),
              const Text('Enable streak reminders'),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Send a reminder a few hours before a streak would break.',
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System rules saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplates(BuildContext context) {
    final pageSize = 10;
    final start = tmplPage * pageSize;
    final slice = templates.skip(start).take(pageSize).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Templates'),
              const Spacer(),
              Text('Page ${tmplPage + 1}'),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () =>
                    setState(() => tmplPage = tmplPage > 0 ? tmplPage - 1 : 0),
                child: const Text('Prev'),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  final maxPage = (templates.length / pageSize).ceil() - 1;
                  setState(
                    () =>
                        tmplPage = tmplPage < maxPage ? tmplPage + 1 : maxPage,
                  );
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Title')),
                DataColumn(label: Text('Body')),
                DataColumn(label: Text('Active')),
              ],
              rows: slice.map((t) {
                return DataRow(
                  cells: [
                    DataCell(Text(t['name'])),
                    DataCell(Text(t['title'])),
                    DataCell(Text(t['body'])),
                    DataCell(
                      Switch(value: t['active'] as bool, onChanged: (_) {}),
                    ),
                  ],
                  onSelectChanged: (_) => _openTemplateEditor(context, t),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs(BuildContext context) {
    final pageSize = 10;
    final start = logsPage * pageSize;
    final slice = logs.skip(start).take(pageSize).toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Logs (last 50)'),
              const Spacer(),
              Text('Page ${logsPage + 1}'),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () =>
                    setState(() => logsPage = logsPage > 0 ? logsPage - 1 : 0),
                child: const Text('Prev'),
              ),
              const SizedBox(width: 6),
              ElevatedButton(
                onPressed: () {
                  final maxPage = (logs.length / pageSize).ceil() - 1;
                  setState(
                    () =>
                        logsPage = logsPage < maxPage ? logsPage + 1 : maxPage,
                  );
                },
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Type')),
                DataColumn(label: Text('Username')),
                DataColumn(label: Text('Delivery status')),
              ],
              rows: slice.map((l) {
                return DataRow(
                  cells: [
                    DataCell(Text(l['timestamp']!)),
                    DataCell(Text(l['type']!)),
                    DataCell(Text(l['username']!)),
                    DataCell(Text(l['status']!)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openTemplateEditor(
    BuildContext context,
    Map<String, dynamic> t,
  ) async {
    final titleCtrl = TextEditingController(text: t['title']);
    final bodyCtrl = TextEditingController(text: t['body']);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.primaryBackground,
          title: Text('Edit Template: ${t['name']}'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Body (placeholders: {username}, {streakDays})',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Template saved')));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
