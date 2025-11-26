import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class SettingsLegalPage extends StatelessWidget {
  const SettingsLegalPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appNameCtrl = TextEditingController(text: 'ETA Network');
    final taglineCtrl = TextEditingController(text: 'Earn points, build ranks');
    final aboutCtrl = TextEditingController(
      text: 'ETA Network is a points-earning ecosystem.',
    );
    final disclaimerCtrl = TextEditingController(
      text:
          'These are loyalty points, not a real cryptocurrency yet. No guaranteed future value.',
    );
    final faqCtrl = TextEditingController(text: 'FAQ section...');
    final termsCtrl = TextEditingController(text: 'Terms of Service...');
    final privacyCtrl = TextEditingController(text: 'Privacy Policy...');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('App Identity'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: appNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'App Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: taglineCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Short Tagline',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: aboutCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'About'),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.deepLayer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preview'),
                      const SizedBox(height: 6),
                      Text(
                        appNameCtrl.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(taglineCtrl.text),
                      Text(aboutCtrl.text),
                    ],
                  ),
                ),
              ],
            ),
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
                const Text('Legal & Disclaimers'),
                const SizedBox(height: 8),
                TextField(
                  controller: disclaimerCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Disclaimer text',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: faqCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'FAQ content'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: termsCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Terms of Service',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: privacyCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Privacy Policy',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Preview ready')),
                        );
                      },
                      child: const Text('Preview in App'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Legal content saved')),
                        );
                      },
                      child: const Text('Save legal content'),
                    ),
                  ],
                ),
              ],
            ),
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
                const Text('Admin Accounts'),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Role')),
                      DataColumn(label: Text('Last login')),
                    ],
                    rows: const [
                      DataRow(
                        cells: [
                          DataCell(Text('admin@example.com')),
                          DataCell(Text('owner')),
                          DataCell(Text('2025-11-24 12:00')),
                        ],
                      ),
                      DataRow(
                        cells: [
                          DataCell(Text('mod1@example.com')),
                          DataCell(Text('moderator')),
                          DataCell(Text('2025-11-24 09:10')),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        final emailCtrl = TextEditingController();
                        return AlertDialog(
                          backgroundColor: AppColors.primaryBackground,
                          title: const Text('Invite new admin'),
                          content: SizedBox(
                            width: 420,
                            child: TextField(
                              controller: emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Invite sent')),
                                );
                              },
                              child: const Text('Send Invite'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Invite new admin'),
                ),
              ],
            ),
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
                const Text('Settings'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(value: true, onChanged: (_) {}),
                    const Text('Enable app'),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(value: false, onChanged: (_) {}),
                    const Text('Maintenance mode'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
