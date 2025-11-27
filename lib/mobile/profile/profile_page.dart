import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../auth/auth_gate.dart';
import '../../shared/firestore_constants.dart';
import '../../services/referral_engine.dart';
import '../../services/earnings_engine.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String username = '';
  String rank = '';
  String email = '';
  String uid = '';
  bool referralLocked = true;
  String? invitedBy;
  int streakDays = 0;
  int referralCount = 0;
  final _referralCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EarningsEngine.syncEarnings();
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    uid = u.uid;
    email = u.email ?? '';
    final snap = await FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .get();
    final d = snap.data() ?? {};
    setState(() {
      username = (d[FirestoreUserFields.username] as String?) ?? '';
      rank = (d[FirestoreUserFields.rank] as String?) ?? '';
      referralLocked = (d[FirestoreUserFields.referralLocked] as bool?) ?? true;
      invitedBy = d[FirestoreUserFields.invitedBy] as String?;
      streakDays = (d[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
    });
    final countAgg = await FirebaseFirestore.instance
        .collection(FirestoreConstants.referrals)
        .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
        .where(FirestoreReferralFields.isActive, isEqualTo: true)
        .count()
        .get();
    setState(() {
      referralCount = countAgg.count ?? 0;
    });
  }

  Future<void> _submitReferral() async {
    final code = _referralCtrl.text.trim();
    if (code.isEmpty ||
        referralLocked ||
        (invitedBy != null && invitedBy!.isNotEmpty)) {
      return;
    }
    await ReferralEngine.processReferralOnProfile(uid: uid, referralCode: code);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.secondaryAccent,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username.isNotEmpty ? username : '—'),
                      const SizedBox(height: 6),
                      Text(rank.isNotEmpty ? rank : '—'),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.qr_code_2_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section('Account Info', [
              _kv('Username', username.isNotEmpty ? username : '—'),
              _kv('Email', email.isNotEmpty ? email : '—'),
              _kv('UID', uid.isNotEmpty ? uid : '—'),
              _kv('Device ID', 'device-xyz'),
              _kv('Timezone', 'UTC+1'),
            ]),
            _section('Performance', [
              _kv('StreakDays', '$streakDays'),
              _kv('Referral count', '$referralCount'),
              _kv('Total mining sessions', '142'),
            ]),
            if (!referralLocked && (invitedBy == null || invitedBy!.isEmpty))
              _section('Add Referral Code', [
                TextField(
                  controller: _referralCtrl,
                  decoration: const InputDecoration(labelText: 'Referral code'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _submitReferral,
                  child: const Text('Confirm'),
                ),
              ]),
            _section('Notifications', [
              _toggle('Enable notifications', true),
              _toggle('Streak reminders', true),
            ]),
            _section('Legal', [
              _button(context, 'FAQ'),
              _button(context, 'Disclaimer'),
              _button(context, 'Terms & Privacy'),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vipAccent,
              ),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(title), const SizedBox(height: 8), ...children],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(value: value, onChanged: (_) {}),
      ],
    );
  }

  Widget _button(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(onPressed: () {}, child: Text(label)),
    );
  }
}
