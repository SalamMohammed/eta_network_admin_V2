import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../auth/auth_gate.dart';
import '../../shared/firestore_constants.dart';
import '../../services/referral_engine.dart';
import '../../services/earnings_engine.dart';
import '../../services/mining_state_service.dart';
import '../../services/sql_api_service.dart';
import '../../services/user_service.dart';
import '../../services/offline_mining_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/pick_image_io.dart'
    if (dart.library.html) '../../shared/pick_image_web.dart'
    as picker;
import 'legal_content_page.dart';

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
  int totalInvited = 0;
  int totalSessions = 0;
  String? thumbnailUrl;
  final _referralCtrl = TextEditingController();
  final _miningService = MiningStateService();

  @override
  void initState() {
    super.initState();
    _miningService.addListener(_handleMiningUpdate);
    // MiningService is auto-initialized by Auth listener
    _load();
  }

  @override
  void dispose() {
    _miningService.removeListener(_handleMiningUpdate);
    _referralCtrl.dispose();
    super.dispose();
  }

  void _handleMiningUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _load() async {
    // OPTIMIZATION: Use the result from syncEarnings to avoid redundant user doc read
    final syncRes = await EarningsEngine.syncEarnings();
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    uid = u.uid;
    email = u.email ?? '';

    // Use synced data directly
    final d = (syncRes['userData'] as Map<String, dynamic>?) ?? {};

    // If syncRes didn't return user data (unlikely), fallback to UserService cache
    final Map<String, dynamic> userData = d.isNotEmpty
        ? d
        : (await UserService().getUser(uid))?.data() ?? {};

    if (mounted) {
      setState(() {
        username = (userData[FirestoreUserFields.username] as String?) ?? '';
        rank = (userData[FirestoreUserFields.rank] as String?) ?? '';
        referralLocked =
            (userData[FirestoreUserFields.referralLocked] as bool?) ?? true;
        invitedBy = userData[FirestoreUserFields.invitedBy] as String?;
        streakDays =
            (userData[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
        thumbnailUrl =
            (userData[FirestoreUserFields.thumbnailUrl] as String?) ?? '';
        totalSessions =
            (userData[FirestoreUserFields.totalSessions] as num?)?.toInt() ?? 0;
        totalInvited =
            (userData[FirestoreUserFields.totalInvited] as num?)?.toInt() ?? 0;
      });
    }

    // Referral Stats - Optimized to use cache or specific field fetch if possible
    // For now, we still fetch the doc but use FirestoreHelper
    final statsSnap = await FirestoreHelper.instance
        .collection(FirestoreConstants.referralStats)
        .doc(uid)
        .get();
    final statsData = statsSnap.data() ?? {};
    if (mounted) {
      setState(() {
        referralCount = (statsData['active48hCount'] as num?)?.toInt() ?? 0;
      });
    }
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
    const pageBgTop = Color(0xFF0B1620);
    const pageBgBottom = Color(0xFF0E1618);
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    const buttonBlue = Color(0xFF1677FF);

    final canEnterReferral =
        !referralLocked && (invitedBy == null || invitedBy!.isEmpty);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [pageBgTop, pageBgBottom],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = (constraints.maxWidth / 380).clamp(0.78, 1.0);
            double s(double v) => v * scale;

            final displayName = username.isNotEmpty ? username : '—';
            final displayRank = rank.isNotEmpty ? rank : '—';

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        SizedBox(height: s(6)),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: s(92),
                              height: s(92),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: GestureDetector(
                                      onTap: _uploadProfileImage,
                                      child: ClipOval(
                                        child:
                                            (thumbnailUrl != null &&
                                                thumbnailUrl!.isNotEmpty)
                                            ? Image.network(
                                                thumbnailUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (context, error, stack) {
                                                      return Container(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.10,
                                                            ),
                                                        alignment:
                                                            Alignment.center,
                                                        child: Icon(
                                                          Icons.person_rounded,
                                                          size: s(44),
                                                          color: Colors.white70,
                                                        ),
                                                      );
                                                    },
                                              )
                                            : Container(
                                                color: Colors.white.withValues(
                                                  alpha: 0.10,
                                                ),
                                                alignment: Alignment.center,
                                                child: Icon(
                                                  Icons.person_rounded,
                                                  size: s(44),
                                                  color: Colors.white70,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                          width: s(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: s(0),
                              bottom: s(0),
                              child: Container(
                                width: s(32),
                                height: s(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: buttonBlue,
                                  border: Border.all(
                                    color: const Color(0xFF0E1618),
                                    width: s(2),
                                  ),
                                ),
                                child: Icon(
                                  Icons.photo_camera_rounded,
                                  size: s(16),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: s(12)),
                        Text(
                          displayName,
                          style: TextStyle(
                            fontSize: s(22),
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: s(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: s(12),
                            vertical: s(7),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.emoji_events_rounded,
                                size: s(16),
                                color: const Color(0xFFFFC44D),
                              ),
                              SizedBox(width: s(8)),
                              Text(
                                displayRank,
                                style: TextStyle(
                                  fontSize: s(12.5),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(16)),
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.local_fire_department_rounded,
                          value: '$streakDays',
                          label: 'STREAK',
                          scale: s,
                          cardBg: cardBg,
                          cardBg2: cardBg2,
                          accent: const Color(0xFFFF8A00),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _statCard(
                          icon: Icons.groups_rounded,
                          value: '$totalInvited',
                          label: 'REFERRALS',
                          scale: s,
                          cardBg: cardBg,
                          cardBg2: cardBg2,
                          accent: buttonBlue,
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _statCard(
                          icon: Icons.bolt_rounded,
                          value: '$totalSessions',
                          label: 'SESSIONS',
                          scale: s,
                          cardBg: cardBg,
                          cardBg2: cardBg2,
                          accent: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(18)),
                  _sectionTitle('Account Info', scale: s),
                  SizedBox(height: s(10)),
                  _settingsCard(
                    scale: s,
                    cardBg: cardBg,
                    cardBg2: cardBg2,
                    child: _settingsTile(
                      scale: s,
                      icon: Icons.person_rounded,
                      title: 'Account Info',
                      subtitle: null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white54,
                        size: s(24),
                      ),
                      onTap: () => _showAccountInfoSheet(
                        context,
                        scale: s,
                        cardBg: cardBg,
                        cardBg2: cardBg2,
                      ),
                    ),
                  ),
                  // SizedBox(height: s(18)),
                  // _sectionTitle('Preferences', scale: s),
                  // SizedBox(height: s(10)),
                  // _settingsCard(
                  //   scale: s,
                  //   cardBg: cardBg,
                  //   cardBg2: cardBg2,
                  //   child: Column(
                  //     children: [
                  //       _settingsTile(
                  //         scale: s,
                  //         icon: Icons.admin_panel_settings_rounded,
                  //         title: 'Manager Mode',
                  //         subtitle: 'Access advanced mining tools',
                  //         trailing: Theme(
                  //           data: Theme.of(context).copyWith(
                  //             switchTheme: SwitchThemeData(
                  //               trackColor: WidgetStateProperty.resolveWith((
                  //                 states,
                  //               ) {
                  //                 final selected = states.contains(
                  //                   WidgetState.selected,
                  //                 );
                  //                 if (selected) return buttonBlue;
                  //                 return Colors.white24;
                  //               }),
                  //               thumbColor: WidgetStateProperty.resolveWith((
                  //                 states,
                  //               ) {
                  //                 final selected = states.contains(
                  //                   WidgetState.selected,
                  //                 );
                  //                 if (selected) return Colors.white;
                  //                 return Colors.white70;
                  //               }),
                  //             ),
                  //           ),
                  //           child: Switch(
                  //             value: _miningService.managerEnabled,
                  //             onChanged: null,
                  //           ),
                  //         ),
                  //         onTap: null,
                  //       ),
                  //       Padding(
                  //         padding: EdgeInsets.symmetric(horizontal: s(14)),
                  //         child: Container(
                  //           height: 1,
                  //           color: Colors.white.withValues(alpha: 0.06),
                  //         ),
                  //       ),
                  //       _settingsTile(
                  //         scale: s,
                  //         icon: Icons.notifications_rounded,
                  //         title: 'Notifications',
                  //         subtitle: null,
                  //         trailing: Icon(
                  //           Icons.chevron_right_rounded,
                  //           color: Colors.white54,
                  //           size: s(24),
                  //         ),
                  //         onTap: () {},
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: s(18)),
                  _sectionTitle('Invited by someone?', scale: s),
                  SizedBox(height: s(10)),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: s(12)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(s(14)),
                            color: Colors.white.withValues(alpha: 0.06),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _referralCtrl,
                            enabled: canEnterReferral,
                            decoration: InputDecoration(
                              hintText: canEnterReferral
                                  ? 'Enter referral code'
                                  : (invitedBy != null && invitedBy!.isNotEmpty)
                                  ? 'Invited'
                                  : 'Locked',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: s(12)),
                      SizedBox(
                        height: s(46),
                        child: ElevatedButton(
                          onPressed: canEnterReferral ? _submitReferral : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonBlue,
                            disabledBackgroundColor: buttonBlue.withValues(
                              alpha: 0.30,
                            ),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(s(14)),
                            ),
                          ),
                          child: Text(
                            'Apply',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: s(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(18)),
                  _settingsCard(
                    scale: s,
                    cardBg: cardBg,
                    cardBg2: cardBg2,
                    child: Column(
                      children: [
                        _settingsTile(
                          scale: s,
                          icon: Icons.info_outline_rounded,
                          title: 'About',
                          subtitle: null,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                            size: s(24),
                          ),
                          onTap: () =>
                              _openAboutPage(context, s, cardBg, cardBg2),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: s(14)),
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        _settingsTile(
                          scale: s,
                          icon: Icons.security_rounded,
                          title: 'Security Settings',
                          subtitle: null,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                            size: s(24),
                          ),
                          onTap: () =>
                              _openSecurityPage(context, s, cardBg, cardBg2),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: s(14)),
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                        _settingsTile(
                          scale: s,
                          icon: Icons.qr_code_rounded,
                          title: 'KYC Verification',
                          subtitle: null,
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white54,
                            size: s(24),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1B2632),
                                title: const Text(
                                  'KYC Verification',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Will be activated in the coming stages.',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: s(14)),
                          child: Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(18)),
                  SizedBox(
                    height: s(52),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        MiningStateService().reset();
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove(
                            'referral_code_${FirebaseAuth.instance.currentUser?.uid ?? ''}',
                          );
                        } catch (_) {}
                        try {
                          await GoogleSignIn().signOut();
                        } catch (_) {}
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthGate()),
                            (route) => false,
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(s(14)),
                        ),
                      ),
                      icon: Icon(Icons.logout_rounded, size: s(18)),
                      label: Text(
                        'Log Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: s(15),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: s(18)),
                  Center(
                    child: Text(
                      '© ${DateTime.now().year} ETA Network',
                      style: TextStyle(
                        fontSize: s(12),
                        color: Colors.white38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: s(10)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openAboutPage(
    BuildContext context,
    double Function(double) s,
    Color cardBg,
    Color cardBg2,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('About'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1620), Color(0xFF0E1618)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.all(s(16)),
              children: [
                _settingsCard(
                  scale: s,
                  cardBg: cardBg,
                  cardBg2: cardBg2,
                  child: Column(
                    children: [
                      _settingsTile(
                        scale: s,
                        icon: Icons.help_outline_rounded,
                        title: 'FAQ',
                        subtitle: null,
                        trailing: Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white54,
                          size: s(18),
                        ),
                        onTap: () => _openLegal(context, 'FAQ', [
                          FirestoreLegalFields.faq,
                        ]),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s(14)),
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      _settingsTile(
                        scale: s,
                        icon: Icons.description_rounded,
                        title: 'White Paper',
                        subtitle: null,
                        trailing: Icon(
                          Icons.description_outlined,
                          color: Colors.white54,
                          size: s(18),
                        ),
                        onTap: () => _openLegal(context, 'White Paper', [
                          FirestoreLegalFields.whitePaper,
                        ]),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: s(14)),
                        child: Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      _settingsTile(
                        scale: s,
                        icon: Icons.mail_outline_rounded,
                        title: 'Contact Us',
                        subtitle: null,
                        trailing: Icon(
                          Icons.mail_outline_rounded,
                          color: Colors.white54,
                          size: s(18),
                        ),
                        onTap: () => _openLegal(context, 'Contact Us', [
                          FirestoreLegalFields.contactUs,
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSecurityPage(
    BuildContext context,
    double Function(double) s,
    Color cardBg,
    Color cardBg2,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Security Settings'),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B1620), Color(0xFF0E1618)],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.all(s(16)),
              children: [
                _settingsCard(
                  scale: s,
                  cardBg: cardBg,
                  cardBg2: cardBg2,
                  child: _settingsTile(
                    scale: s,
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account and data',
                    textColor: Colors.redAccent,
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white54,
                      size: s(24),
                    ),
                    onTap: () async {
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
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (ok != true) return;
                      await _deleteAccount();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage() async {
    final u = FirebaseAuth.instance.currentUser;
    final uidLocal = u?.uid;
    if (uidLocal == null || uidLocal.isEmpty) return;
    final picked = await picker.pickImage();
    final bytes = picked?.bytes;
    final ct = picked?.contentType;
    if (bytes == null || bytes.isEmpty) return;
    final r = FirebaseStorage.instance.ref().child('users/$uidLocal/thumbnail');
    await r.putData(bytes, SettableMetadata(contentType: ct ?? 'image/png'));
    final url = await r.getDownloadURL();
    await FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(uidLocal)
        .set({
          FirestoreUserFields.thumbnailUrl: url,
          FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
    await OfflineMiningEngine(
      FirestoreHelper.instance,
    ).reloadFromRemote(uidLocal);
    setState(() {
      thumbnailUrl = url;
    });
  }

  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uidLocal = user?.uid;
      if (uidLocal == null || uidLocal.isEmpty) return;

      // Stop local activity: no-op here (handled by navigation), but ensure sign-out at end.

      // Delete Firestore data (cascade)
      final db = FirestoreHelper.instance;
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

      // Delete from SQL backend
      try {
        await SqlApiService.deleteUserCoin(uidLocal);
      } catch (e) {
        debugPrint('Failed to delete user coin from SQL: $e');
      }

      // Delete images from Storage
      try {
        final storageRef = FirebaseStorage.instance.ref();
        // Delete profile thumbnail
        await storageRef.child('users/$uidLocal/thumbnail').delete();
        // Delete coin thumbnail
        await storageRef.child('user_coins/$uidLocal/thumbnail').delete();
      } catch (e) {
        debugPrint('Failed to delete images from Storage: $e');
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
      MiningStateService().reset();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(
          'referral_code_${FirebaseAuth.instance.currentUser?.uid ?? ''}',
        );
      } catch (_) {}
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

  void _openLegal(BuildContext context, String title, List<String> keys) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LegalContentPage(title: title, fieldKeys: keys),
      ),
    );
  }

  Widget _sectionTitle(String title, {required double Function(double) scale}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: scale(14),
        fontWeight: FontWeight.w800,
        color: Colors.white70,
      ),
    );
  }

  Widget _settingsCard({
    required Widget child,
    required double Function(double) scale,
    required Color cardBg,
    required Color cardBg2,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale(18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg, cardBg2],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _settingsTile({
    required double Function(double) scale,
    required IconData icon,
    required String title,
    required String? subtitle,
    required Widget trailing,
    required VoidCallback? onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(scale(18)),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: scale(14),
          vertical: scale(12),
        ),
        child: Row(
          children: [
            Container(
              width: scale(40),
              height: scale(40),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(scale(12)),
                border: Border.all(color: Colors.white12),
              ),
              child: Icon(icon, color: Colors.white70, size: scale(20)),
            ),
            SizedBox(width: scale(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: scale(14.5),
                      fontWeight: FontWeight.w800,
                      color: textColor ?? Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: scale(2)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: scale(12.5),
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required double Function(double) scale,
    required Color cardBg,
    required Color cardBg2,
    required Color accent,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: scale(12), vertical: scale(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale(18)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardBg, cardBg2],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: scale(34),
            height: scale(34),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(scale(12)),
              border: Border.all(color: Colors.white12),
            ),
            child: Icon(icon, color: accent, size: scale(18)),
          ),
          SizedBox(height: scale(10)),
          SizedBox(
            height: scale(24),
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: scale(22),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
          SizedBox(height: scale(4)),
          SizedBox(
            height: scale(14),
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: scale(11.5),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountInfoSheet(
    BuildContext context, {
    required double Function(double) scale,
    required Color cardBg,
    required Color cardBg2,
  }) {
    final uidLocal = FirebaseAuth.instance.currentUser?.uid;
    if (uidLocal == null || uidLocal.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF141E28),
      isScrollControlled: true,
      builder: (context) {
        return _AccountInfoSheet(
          uid: uidLocal,
          initialUsername: username,
          email: email,
          cardBg: cardBg,
          cardBg2: cardBg2,
          scale: scale,
          onUsernameUpdated: (v) {
            if (!mounted) return;
            setState(() {
              username = v;
            });
          },
        );
      },
    );
  }
}

class _AccountInfoSheet extends StatefulWidget {
  final String uid;
  final String initialUsername;
  final String email;
  final Color cardBg;
  final Color cardBg2;
  final double Function(double) scale;
  final ValueChanged<String> onUsernameUpdated;

  const _AccountInfoSheet({
    required this.uid,
    required this.initialUsername,
    required this.email,
    required this.cardBg,
    required this.cardBg2,
    required this.scale,
    required this.onUsernameUpdated,
  });

  @override
  State<_AccountInfoSheet> createState() => _AccountInfoSheetState();
}

class _AccountInfoSheetState extends State<_AccountInfoSheet> {
  late final DocumentReference<Map<String, dynamic>> _userRef;

  late final TextEditingController _usernameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _genderCtrl;

  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _userRef = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(widget.uid);

    _usernameCtrl = TextEditingController(text: widget.initialUsername);
    _emailCtrl = TextEditingController(text: widget.email);
    _nameCtrl = TextEditingController();
    _ageCtrl = TextEditingController();
    _countryCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _genderCtrl = TextEditingController();

    _load();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _countryCtrl.dispose();
    _addressCtrl.dispose();
    _genderCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final snap = await _userRef.get();
      final d = snap.data() ?? {};
      _usernameCtrl.text =
          (d[FirestoreUserFields.username] as String?) ?? _usernameCtrl.text;
      _nameCtrl.text = (d[FirestoreUserFields.name] as String?) ?? '';
      _ageCtrl.text =
          (d[FirestoreUserFields.age] as num?)?.toInt().toString() ?? '';
      _countryCtrl.text = (d[FirestoreUserFields.country] as String?) ?? '';
      _addressCtrl.text = (d[FirestoreUserFields.address] as String?) ?? '';
      _genderCtrl.text = (d[FirestoreUserFields.gender] as String?) ?? '';
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white38,
        fontSize: widget.scale(13),
        fontWeight: FontWeight.w700,
      ),
      border: InputBorder.none,
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool enabled = true,
    int maxLines = 1,
  }) {
    final fieldBg = enabled
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.03);
    final fieldFg = enabled ? Colors.white : Colors.white54;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: widget.scale(12.5),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: widget.scale(6)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.scale(12),
            vertical: maxLines > 1 ? widget.scale(10) : widget.scale(0),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.scale(14)),
            color: fieldBg,
            border: Border.all(color: Colors.white12),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(
              color: fieldFg,
              fontSize: widget.scale(14.5),
              fontWeight: FontWeight.w700,
            ),
            decoration: _inputDecoration(hint),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final newUsername = _usernameCtrl.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    final ageStr = _ageCtrl.text.trim();
    final ageNum = ageStr.isEmpty ? null : int.tryParse(ageStr);
    if (ageStr.isNotEmpty && (ageNum == null || ageNum < 0 || ageNum > 150)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid age value')));
      return;
    }

    Map<String, Object?> upd(String key, String value) {
      final v = value.trim();
      if (v.isEmpty) return {key: FieldValue.delete()};
      return {key: v};
    }

    setState(() {
      _saving = true;
    });

    try {
      final payload = <String, Object?>{
        FirestoreUserFields.username: newUsername,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
        ...upd(FirestoreUserFields.name, _nameCtrl.text),
        ...upd(FirestoreUserFields.country, _countryCtrl.text),
        ...upd(FirestoreUserFields.address, _addressCtrl.text),
        ...upd(FirestoreUserFields.gender, _genderCtrl.text),
      };

      if (ageNum == null) {
        payload[FirestoreUserFields.age] = FieldValue.delete();
      } else {
        payload[FirestoreUserFields.age] = ageNum;
      }

      await _userRef.set(payload, SetOptions(merge: true));
      await OfflineMiningEngine(
        FirestoreHelper.instance,
      ).reloadFromRemote(_userRef.id);

      widget.onUsernameUpdated(newUsername);
      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save changes')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    Widget content() {
      if (_loading) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.cardBg, widget.cardBg2],
          ),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Account Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _isEditing = !_isEditing;
                        }),
                  icon: Icon(
                    _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                    size: widget.scale(18),
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            SizedBox(height: widget.scale(8)),
            if (!_isEditing) ...[
              Text(
                'Username',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: widget.scale(12.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: widget.scale(6)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _usernameCtrl.text.trim().isNotEmpty
                          ? _usernameCtrl.text.trim()
                          : '—',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.scale(15.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: widget.scale(12)),
              Text(
                'Email',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: widget.scale(12.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: widget.scale(6)),
              Text(
                widget.email.isNotEmpty ? widget.email : '—',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: widget.scale(15.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: widget.scale(14)),
              _labelValue('Name', _nameCtrl.text),
              SizedBox(height: widget.scale(12)),
              _labelValue('Age', _ageCtrl.text),
              SizedBox(height: widget.scale(12)),
              _labelValue('Country', _countryCtrl.text),
              SizedBox(height: widget.scale(12)),
              _labelValue('Address', _addressCtrl.text),
              SizedBox(height: widget.scale(12)),
              _labelValue('Gender', _genderCtrl.text),
            ] else ...[
              _field(
                label: 'Username',
                controller: _usernameCtrl,
                hint: 'Enter username',
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Email',
                controller: _emailCtrl,
                hint: '—',
                enabled: false,
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Name (optional)',
                controller: _nameCtrl,
                hint: 'Enter name',
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Age (optional)',
                controller: _ageCtrl,
                hint: 'Enter age',
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Country (optional)',
                controller: _countryCtrl,
                hint: 'Enter country',
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Address (optional)',
                controller: _addressCtrl,
                hint: 'Enter address',
                maxLines: 2,
              ),
              SizedBox(height: widget.scale(12)),
              _field(
                label: 'Gender (optional)',
                controller: _genderCtrl,
                hint: 'Enter gender',
              ),
              SizedBox(height: widget.scale(14)),
              SizedBox(
                height: widget.scale(46),
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(widget.scale(14)),
                    ),
                  ),
                  child: Text(
                    _saving ? 'Saving...' : 'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: widget.scale(15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1677FF),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _labelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: widget.scale(12.5),
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: widget.scale(6)),
        Text(
          value.trim().isNotEmpty ? value.trim() : '—',
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.scale(15.5),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
