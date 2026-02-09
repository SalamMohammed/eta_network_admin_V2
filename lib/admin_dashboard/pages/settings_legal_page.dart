import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../shared/firestore_constants.dart';
import '../../shared/theme/colors.dart';
import '../../utils/firestore_helper.dart';

class SettingsLegalPage extends StatefulWidget {
  const SettingsLegalPage({super.key});

  @override
  State<SettingsLegalPage> createState() => _SettingsLegalPageState();
}

class _SettingsLegalPageState extends State<SettingsLegalPage> {
  final _appNameCtrl = TextEditingController();
  final _taglineCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _faqCtrl = TextEditingController();
  final _whitePaperCtrl = TextEditingController();
  final _contactUsCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final doc = await FirestoreHelper.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.legal)
          .get();
      if (doc.exists) {
        final d = doc.data()!;
        _appNameCtrl.text = (d[FirestoreLegalFields.appName] as String?) ?? '';
        _taglineCtrl.text = (d[FirestoreLegalFields.tagline] as String?) ?? '';
        _aboutCtrl.text = (d[FirestoreLegalFields.about] as String?) ?? '';
        _faqCtrl.text = (d[FirestoreLegalFields.faq] as String?) ?? '';
        _whitePaperCtrl.text =
            (d[FirestoreLegalFields.whitePaper] as String?) ?? '';
        _contactUsCtrl.text =
            (d[FirestoreLegalFields.contactUs] as String?) ?? '';
      } else {
        // Defaults
        _appNameCtrl.text = 'ETA Network';
        _taglineCtrl.text = 'Earn points, build ranks';
        _aboutCtrl.text = 'ETA Network is a points-earning ecosystem.';
        _faqCtrl.text = 'FAQ section...';
        _whitePaperCtrl.text = 'White Paper content...';
        _contactUsCtrl.text = 'Contact Us info...';
      }
    } catch (e) {
      debugPrint('Error loading legal settings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await FirestoreHelper.instance
          .collection(FirestoreConstants.appConfig)
          .doc(FirestoreAppConfigDocs.legal)
          .set({
            FirestoreLegalFields.appName: _appNameCtrl.text.trim(),
            FirestoreLegalFields.tagline: _taglineCtrl.text.trim(),
            FirestoreLegalFields.about: _aboutCtrl.text.trim(),
            FirestoreLegalFields.faq: _faqCtrl.text.trim(),
            FirestoreLegalFields.whitePaper: _whitePaperCtrl.text.trim(),
            FirestoreLegalFields.contactUs: _contactUsCtrl.text.trim(),
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Legal content saved')));
      }
    } catch (e) {
      debugPrint('Error saving legal settings: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error saving content')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
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
                        controller: _appNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'App Name',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _taglineCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Short Tagline',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _aboutCtrl,
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
                        _appNameCtrl.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(_taglineCtrl.text),
                      Text(_aboutCtrl.text),
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
                  controller: _faqCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(labelText: 'FAQ content'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _whitePaperCtrl,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'White Paper content',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contactUsCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Contact Us info',
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
                      onPressed: _save,
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
