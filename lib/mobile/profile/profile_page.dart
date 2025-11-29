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
  bool managerEnabled = false;
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
      managerEnabled =
          (d[FirestoreUserFields.managerEnabled] as bool?) ?? false;
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
            _section('Manager', [
              Row(
                children: [
                  const Expanded(child: Text('Enable Manager (auto-mining)')),
                  Switch(
                    value: managerEnabled,
                    onChanged: (v) async {
                      setState(() => managerEnabled = v);
                      await FirebaseFirestore.instance
                          .collection(FirestoreConstants.users)
                          .doc(uid)
                          .set({
                            FirestoreUserFields.managerEnabled: v,
                            FirestoreUserFields.updatedAt:
                                FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));
                    },
                  ),
                ],
              ),
            ]),
            _section('Legal', [
              _button(context, 'FAQ'),
              _button(context, 'Disclaimer'),
              _button(context, 'Terms & Privacy'),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  barrierDismissible: true,
                  builder: (ctx) {
                    return AlertDialog(
                      title: const Text('Delete account?'),
                      content: const Text(
                        'This will permanently delete your account, data, and sessions. This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                );
                if (ok != true) return;
                await _deleteAccount();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete Account'),
            ),
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

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uidLocal = user?.uid;
      if (uidLocal == null || uidLocal.isEmpty) return;

      // Stop local activity: no-op here (handled by navigation), but ensure sign-out at end.

      // Delete Firestore data (cascade)
      final db = FirebaseFirestore.instance;
      final users = db.collection(FirestoreConstants.users);
      final referrals = db.collection(FirestoreConstants.referrals);
      final points = db.collection(FirestoreConstants.pointLogs);
      final userCoins = db.collection(FirestoreConstants.userCoins);

      // Delete user subcollection coins
      final coinsRef = users
          .doc(uidLocal)
          .collection(FirestoreUserSubCollections.coins);
      final coinsSnap = await coinsRef.get();
      final batch1 = db.batch();
      for (final d in coinsSnap.docs) {
        batch1.delete(d.reference);
      }
      await batch1.commit();

      // Delete referrals where inviter or invitee is this user
      final inviterQs = await referrals
          .where(FirestoreReferralFields.inviterId, isEqualTo: uidLocal)
          .get();
      final inviteeQs = await referrals
          .where(FirestoreReferralFields.inviteeId, isEqualTo: uidLocal)
          .get();
      final batch2 = db.batch();
      for (final d in inviterQs.docs) {
        batch2.delete(d.reference);
      }
      for (final d in inviteeQs.docs) {
        batch2.delete(d.reference);
      }
      await batch2.commit();

      // Delete point logs for this user
      final pointsQs = await points
          .where(FirestorePointLogFields.userId, isEqualTo: uidLocal)
          .get();
      final batch3 = db.batch();
      for (final d in pointsQs.docs) {
        batch3.delete(d.reference);
      }
      await batch3.commit();

      // Delete owned user coin (if any)
      final ownCoinRef = userCoins.doc(uidLocal);
      final ownCoinSnap = await ownCoinRef.get();
      if (ownCoinSnap.exists) {
        await ownCoinRef.delete();
      }

      await users.doc(uidLocal).delete();

      try {
        await user!.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login' && mounted) {
          final pwd = await _promptPassword();
          if (pwd != null && pwd.isNotEmpty) {
            final u2 = FirebaseAuth.instance.currentUser;
            final em = u2?.email ?? '';
            if (em.isNotEmpty && u2 != null) {
              final cred = EmailAuthProvider.credential(
                email: em,
                password: pwd,
              );
              await u2.reauthenticateWithCredential(cred);
              await u2.delete();
            }
          }
        }
      }

      // Final sign-out and redirect
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (_) {
      // Swallow errors to avoid leaking details; optionally show a toast/snackbar
    }
  }

  Future<String?> _promptPassword() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm deletion'),
          content: TextField(
            controller: ctrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter account password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
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
