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
  List<QueryDocumentSnapshot<Map<String, dynamic>>> managers = const [];
  Map<String, dynamic>? legacyManagerCfg;

  @override
  void initState() {
    super.initState();
    _loadManagers();
  }

  Future<void> _loadManagers() async {
    final qs = await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .orderBy(FirestoreManagerFields.createdAt, descending: true)
        .get();
    managers = qs.docs;
    final legacySnap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.manager)
        .get();
    legacyManagerCfg = legacySnap.data();
    setState(() {});
  }

  Future<void> _createManager() async {
    await showDialog(
      context: context,
      builder: (_) => const _CreateManagerDialog(),
    );
    await _loadManagers();
  }

  Future<void> _deleteManager(String id) async {
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .doc(id)
        .delete();
    await _loadManagers();
  }

  Future<void> _migrateLegacyManager() async {
    final cfg = legacyManagerCfg ?? {};
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .add({
          FirestoreManagerFields.name: 'Default Manager',
          FirestoreManagerFields.thumbnailUrl: '',
          FirestoreManagerFields.enableEtaAuto:
              (cfg[FirestoreManagerConfigFields.enableEtaAuto] as bool?) ??
              true,
          FirestoreManagerFields.enableUserCoinAuto:
              (cfg[FirestoreManagerConfigFields.enableUserCoinAuto] as bool?) ??
              true,
          FirestoreManagerFields.globalCommunity: true,
          FirestoreManagerFields.maxCommunityCoinsManaged:
              (cfg[FirestoreManagerConfigFields.maxCommunityCoinsManaged]
                      as num?)
                  ?.toInt() ??
              0,
          FirestoreManagerFields.isActive: true,
          FirestoreManagerFields.createdAt: FieldValue.serverTimestamp(),
          FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
        });
    await _deleteLegacyManager();
  }

  Future<void> _deleteLegacyManager() async {
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.appConfig)
        .doc(FirestoreAppConfigDocs.manager)
        .delete();
    legacyManagerCfg = null;
    setState(() {});
    await _loadManagers();
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
                'Managers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _createManager,
                child: const Text('Create Manager'),
              ),
            ],
          ),
          if ((legacyManagerCfg ?? {}).isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legacy Manager (app_config/manager)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ETA: ' +
                        (((legacyManagerCfg?[FirestoreManagerConfigFields
                                        .enableEtaAuto]
                                    as bool?) ??
                                true)
                            ? 'on'
                            : 'off') +
                        ' • Coin: ' +
                        (((legacyManagerCfg?[FirestoreManagerConfigFields
                                        .enableUserCoinAuto]
                                    as bool?) ??
                                true)
                            ? 'on'
                            : 'off') +
                        ' • Max community: ' +
                        (((legacyManagerCfg?[FirestoreManagerConfigFields
                                            .maxCommunityCoinsManaged]
                                        as num?)
                                    ?.toInt() ??
                                0)
                            .toString()),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _migrateLegacyManager,
                        child: const Text('Migrate to managers'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _deleteLegacyManager,
                        child: const Text('Delete legacy'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBackground,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (managers.isEmpty)
                  const Text('No managers yet. Create one.'),
                for (final doc in managers)
                  _ManagerRow(
                    id: doc.id,
                    data: doc.data(),
                    onDelete: () => _deleteManager(doc.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManagerRow extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _ManagerRow({
    required this.id,
    required this.data,
    required this.onDelete,
  });
  @override
  Widget build(BuildContext context) {
    final name = (data[FirestoreManagerFields.name] as String?) ?? '—';
    final thumb = (data[FirestoreManagerFields.thumbnailUrl] as String?) ?? '';
    final eta = (data[FirestoreManagerFields.enableEtaAuto] as bool?) ?? true;
    final coin =
        (data[FirestoreManagerFields.enableUserCoinAuto] as bool?) ?? true;
    final global =
        (data[FirestoreManagerFields.globalCommunity] as bool?) ?? true;
    final maxCoins =
        (data[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
            ?.toInt() ??
        0;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: thumb.isNotEmpty ? NetworkImage(thumb) : null,
            child: thumb.isEmpty ? const Icon(Icons.auto_mode_rounded) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$name • ETA:${eta ? 'on' : 'off'} • Coin:${coin ? 'on' : 'off'} • Global:${global ? 'yes' : 'no'} • Max:$maxCoins',
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _CreateManagerDialog extends StatefulWidget {
  const _CreateManagerDialog();
  @override
  State<_CreateManagerDialog> createState() => _CreateManagerDialogState();
}

class _CreateManagerDialogState extends State<_CreateManagerDialog> {
  final nameCtrl = TextEditingController();
  final thumbCtrl = TextEditingController();
  bool eta = true;
  bool coin = true;
  bool global = true;
  final maxCtrl = TextEditingController(text: '3');
  bool submitting = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Create Manager',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: thumbCtrl,
                decoration: const InputDecoration(labelText: 'Thumbnail URL'),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: eta,
                onChanged: (v) => setState(() => eta = v ?? true),
                title: const Text('Enable ETA'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: coin,
                onChanged: (v) => setState(() => coin = v ?? true),
                title: const Text('Enable Coin'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: global,
                onChanged: (v) => setState(() => global = v ?? true),
                title: const Text('Global community'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: maxCtrl,
                decoration: const InputDecoration(
                  labelText: 'Max managed community coins',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: submitting ? null : _submit,
                    child: const Text('Create'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = nameCtrl.text.trim();
    if (name.length < 2) return;
    setState(() => submitting = true);
    await FirebaseFirestore.instance
        .collection(FirestoreConstants.managers)
        .add({
          FirestoreManagerFields.name: name,
          FirestoreManagerFields.thumbnailUrl: thumbCtrl.text.trim(),
          FirestoreManagerFields.enableEtaAuto: eta,
          FirestoreManagerFields.enableUserCoinAuto: coin,
          FirestoreManagerFields.globalCommunity: global,
          FirestoreManagerFields.maxCommunityCoinsManaged:
              int.tryParse(maxCtrl.text.trim()) ?? 0,
          FirestoreManagerFields.isActive: true,
          FirestoreManagerFields.createdAt: FieldValue.serverTimestamp(),
          FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
        });
    if (mounted) Navigator.pop(context);
  }
}
