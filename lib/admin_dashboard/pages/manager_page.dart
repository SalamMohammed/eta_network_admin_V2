import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';
import '../../utils/firestore_helper.dart';

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
    final qs = await FirestoreHelper.instance
        .collection(FirestoreConstants.managers)
        .orderBy(FirestoreManagerFields.createdAt, descending: true)
        .get();
    managers = qs.docs;
    final legacySnap = await FirestoreHelper.instance
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
    await FirestoreHelper.instance
        .collection(FirestoreConstants.managers)
        .doc(id)
        .delete();
    await _loadManagers();
  }

  Future<void> _editManager(String id, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (_) => _EditManagerDialog(id: id, data: data),
    );
    await _loadManagers();
  }

  Future<void> _migrateLegacyManager() async {
    final cfg = legacyManagerCfg ?? {};
    await FirestoreHelper.instance.collection(FirestoreConstants.managers).add({
      FirestoreManagerFields.name: 'Default Manager',
      FirestoreManagerFields.thumbnailUrl: '',
      FirestoreManagerFields.enableEtaAuto:
          (cfg[FirestoreManagerConfigFields.enableEtaAuto] as bool?) ?? true,
      FirestoreManagerFields.enableUserCoinAuto:
          (cfg[FirestoreManagerConfigFields.enableUserCoinAuto] as bool?) ??
          true,
      FirestoreManagerFields.globalCommunity: true,
      FirestoreManagerFields.maxCommunityCoinsManaged:
          (cfg[FirestoreManagerConfigFields.maxCommunityCoinsManaged] as num?)
              ?.toInt() ??
          0,
      FirestoreManagerFields.managerMultiplier: 2.0,
      FirestoreManagerFields.isActive: true,
      FirestoreManagerFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
    });
    await _deleteLegacyManager();
  }

  Future<void> _deleteLegacyManager() async {
    await FirestoreHelper.instance
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
                    'ETA: ${(((legacyManagerCfg?[FirestoreManagerConfigFields.enableEtaAuto] as bool?) ?? true) ? 'on' : 'off')} • Coin: ${(((legacyManagerCfg?[FirestoreManagerConfigFields.enableUserCoinAuto] as bool?) ?? true) ? 'on' : 'off')} • Max community: ${((legacyManagerCfg?[FirestoreManagerConfigFields.maxCommunityCoinsManaged] as num?)?.toInt() ?? 0)}',
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
                    onEdit: () => _editManager(doc.id, doc.data()),
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
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _ManagerRow({
    required this.id,
    required this.data,
    required this.onEdit,
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
    final multiplier =
        (data[FirestoreManagerFields.managerMultiplier] as num?)?.toDouble() ??
        1.0;
    final maxCoins =
        (data[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
            ?.toInt() ??
        0;
    final storeId =
        (data[FirestoreManagerFields.storeProductId] as String?) ?? '';
    final bestValue =
        (data[FirestoreManagerFields.bestValue] as bool?) ?? false;

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
              '$name • ETA:${eta ? 'on' : 'off'} • Coin:${coin ? 'on' : 'off'} • Global:${global ? 'yes' : 'no'} • Mult:${multiplier.toStringAsFixed(2)} • Max:$maxCoins${bestValue ? ' • Best Value' : ''}${storeId.isNotEmpty ? ' • ID:$storeId' : ''}',
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
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
  final storeProductIdCtrl = TextEditingController();
  bool eta = true;
  bool coin = true;
  bool global = true;
  bool bestValue = false;
  final multiplierCtrl = TextEditingController(text: '2');
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
              TextField(
                controller: storeProductIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'RevenueCat Product ID',
                  hintText: 'e.g. manager_monthly',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: multiplierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manager multiplier',
                  hintText: 'e.g. 2',
                ),
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
              CheckboxListTile(
                value: bestValue,
                onChanged: (v) => setState(() => bestValue = v ?? false),
                title: const Text('Best value'),
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
    final storeProductId = storeProductIdCtrl.text.trim();
    final multiplier = double.tryParse(multiplierCtrl.text.trim()) ?? 0.0;
    if (name.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (storeProductId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RevenueCat Product ID is required')),
      );
      return;
    }
    if (multiplier < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Multiplier must be ≥ 1')));
      return;
    }
    setState(() => submitting = true);
    final col = FirestoreHelper.instance.collection(
      FirestoreConstants.managers,
    );
    final newRef = col.doc();
    final batch = FirestoreHelper.instance.batch();
    if (bestValue) {
      final qs = await col
          .where(FirestoreManagerFields.bestValue, isEqualTo: true)
          .get();
      for (final d in qs.docs) {
        batch.set(d.reference, {
          FirestoreManagerFields.bestValue: false,
          FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    batch.set(newRef, {
      FirestoreManagerFields.name: name,
      FirestoreManagerFields.thumbnailUrl: thumbCtrl.text.trim(),
      FirestoreManagerFields.storeProductId: storeProductId,
      FirestoreManagerFields.enableEtaAuto: eta,
      FirestoreManagerFields.enableUserCoinAuto: coin,
      FirestoreManagerFields.globalCommunity: global,
      FirestoreManagerFields.bestValue: bestValue,
      FirestoreManagerFields.maxCommunityCoinsManaged:
          int.tryParse(maxCtrl.text.trim()) ?? 0,
      FirestoreManagerFields.managerMultiplier: multiplier,
      FirestoreManagerFields.isActive: true,
      FirestoreManagerFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
    });
    await batch.commit();
    if (mounted) Navigator.pop(context);
  }
}

class _EditManagerDialog extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  const _EditManagerDialog({required this.id, required this.data});

  @override
  State<_EditManagerDialog> createState() => _EditManagerDialogState();
}

class _EditManagerDialogState extends State<_EditManagerDialog> {
  late final TextEditingController nameCtrl;
  late final TextEditingController thumbCtrl;
  late final TextEditingController storeProductIdCtrl;
  late final TextEditingController multiplierCtrl;
  late final TextEditingController maxCtrl;
  bool eta = true;
  bool coin = true;
  bool global = true;
  bool bestValue = false;
  bool isActive = true;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    nameCtrl = TextEditingController(
      text: (d[FirestoreManagerFields.name] as String?) ?? '',
    );
    thumbCtrl = TextEditingController(
      text: (d[FirestoreManagerFields.thumbnailUrl] as String?) ?? '',
    );
    storeProductIdCtrl = TextEditingController(
      text: (d[FirestoreManagerFields.storeProductId] as String?) ?? '',
    );
    multiplierCtrl = TextEditingController(
      text:
          ((d[FirestoreManagerFields.managerMultiplier] as num?)?.toDouble() ??
                  2.0)
              .toString(),
    );
    maxCtrl = TextEditingController(
      text:
          ((d[FirestoreManagerFields.maxCommunityCoinsManaged] as num?)
                  ?.toInt())
              ?.toString() ??
          '0',
    );
    eta = (d[FirestoreManagerFields.enableEtaAuto] as bool?) ?? true;
    coin = (d[FirestoreManagerFields.enableUserCoinAuto] as bool?) ?? true;
    global = (d[FirestoreManagerFields.globalCommunity] as bool?) ?? true;
    bestValue = (d[FirestoreManagerFields.bestValue] as bool?) ?? false;
    isActive = (d[FirestoreManagerFields.isActive] as bool?) ?? true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    thumbCtrl.dispose();
    storeProductIdCtrl.dispose();
    multiplierCtrl.dispose();
    maxCtrl.dispose();
    super.dispose();
  }

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
                'Edit Manager',
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
              TextField(
                controller: storeProductIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'RevenueCat Product ID',
                  hintText: 'e.g. manager_monthly',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: multiplierCtrl,
                decoration: const InputDecoration(
                  labelText: 'Manager multiplier',
                  hintText: 'e.g. 2',
                ),
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
              CheckboxListTile(
                value: bestValue,
                onChanged: (v) => setState(() => bestValue = v ?? false),
                title: const Text('Best value'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: isActive,
                onChanged: (v) => setState(() => isActive = v ?? true),
                title: const Text('Active'),
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
                    child: const Text('Save'),
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
    final storeProductId = storeProductIdCtrl.text.trim();
    final multiplier = double.tryParse(multiplierCtrl.text.trim()) ?? 0.0;
    if (name.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (storeProductId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('RevenueCat Product ID is required')),
      );
      return;
    }
    if (multiplier < 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Multiplier must be ≥ 1')));
      return;
    }
    setState(() => submitting = true);
    final col = FirestoreHelper.instance.collection(
      FirestoreConstants.managers,
    );
    final batch = FirestoreHelper.instance.batch();
    if (bestValue) {
      final qs = await col
          .where(FirestoreManagerFields.bestValue, isEqualTo: true)
          .get();
      for (final d in qs.docs) {
        if (d.id == widget.id) continue;
        batch.set(d.reference, {
          FirestoreManagerFields.bestValue: false,
          FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    batch.set(col.doc(widget.id), {
      FirestoreManagerFields.name: name,
      FirestoreManagerFields.thumbnailUrl: thumbCtrl.text.trim(),
      FirestoreManagerFields.storeProductId: storeProductId,
      FirestoreManagerFields.enableEtaAuto: eta,
      FirestoreManagerFields.enableUserCoinAuto: coin,
      FirestoreManagerFields.globalCommunity: global,
      FirestoreManagerFields.bestValue: bestValue,
      FirestoreManagerFields.maxCommunityCoinsManaged:
          int.tryParse(maxCtrl.text.trim()) ?? 0,
      FirestoreManagerFields.managerMultiplier: multiplier,
      FirestoreManagerFields.isActive: isActive,
      FirestoreManagerFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    if (mounted) Navigator.pop(context);
  }
}
