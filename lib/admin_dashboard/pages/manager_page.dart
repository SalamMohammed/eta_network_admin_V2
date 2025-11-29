import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';

class ManagerPage extends StatefulWidget {
  const ManagerPage({super.key});
  @override
  State<ManagerPage> createState() => _ManagerPageState();
}

class _ManagerPageState extends State<ManagerPage> {
  bool enabledGlobally = true;
  bool enableEtaAuto = true;
  bool enableUserCoinAuto = true;
  final maxCommunityCtrl = TextEditingController(text: '3');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.manager)
        .get();
    final d = snap.data() ?? {};
    enabledGlobally = (d[FirestoreManagerConfigFields.enabledGlobally] as bool?) ?? true;
    enableEtaAuto = (d[FirestoreManagerConfigFields.enableEtaAuto] as bool?) ?? true;
    enableUserCoinAuto = (d[FirestoreManagerConfigFields.enableUserCoinAuto] as bool?) ?? true;
    maxCommunityCtrl.text = ((d[FirestoreManagerConfigFields.maxCommunityCoinsManaged] as num?)?.toInt() ?? 3).toString();
    setState(() {});
  }

  Future<void> _save() async {
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.manager)
        .set({
          FirestoreManagerConfigFields.enabledGlobally: enabledGlobally,
          FirestoreManagerConfigFields.enableEtaAuto: enableEtaAuto,
          FirestoreManagerConfigFields.enableUserCoinAuto: enableUserCoinAuto,
          FirestoreManagerConfigFields.maxCommunityCoinsManaged:
              int.tryParse(maxCommunityCtrl.text.trim()) ?? 3,
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Manager System', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: enabledGlobally,
                  onChanged: (v) => setState(() => enabledGlobally = v ?? true),
                  title: const Text('Enable manager globally'),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        value: enableEtaAuto,
                        onChanged: (v) => setState(() => enableEtaAuto = v ?? true),
                        title: const Text('Auto-mine ETA'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CheckboxListTile(
                        value: enableUserCoinAuto,
                        onChanged: (v) => setState(() => enableUserCoinAuto = v ?? true),
                        title: const Text('Auto-mine user coin'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: maxCommunityCtrl,
                        decoration: const InputDecoration(labelText: 'Max managed community coins'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
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
