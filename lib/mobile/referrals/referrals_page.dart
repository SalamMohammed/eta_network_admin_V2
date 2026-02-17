import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/firestore_constants.dart';
import '../../shared/constants.dart';
import '../../utils/firestore_helper.dart';

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralItem {
  final String username;
  final String status;
  final String joined;

  _ReferralItem({
    required this.username,
    required this.status,
    required this.joined,
  });
}

enum _ReferralFilter { all, active }

class _ReferralsPageState extends State<ReferralsPage> {
  String? _referralCode;
  bool _loading = true;
  int _totalInvited = 0;
  int _activeInvited = 0;
  List<_ReferralItem> _referrals = [];
  _ReferralFilter _filter = _ReferralFilter.all;

  SnackBar _themedSnack(String message) {
    const bg = Color(0xFF141E28);
    const blue = Color(0xFF1677FF);
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: bg,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: blue, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCode(String? code) {
    final v = (code ?? '').trim();
    if (v.isEmpty) return '—';
    final normalized = v.replaceAll(' ', '').toUpperCase();
    final idx = normalized.indexOf('-');
    if (idx <= 0) return normalized;
    final left = normalized.substring(0, idx);
    final right = normalized.substring(idx + 1);
    if (right.isEmpty) return left;
    return '$left - $right';
  }

  void _showHowItWorks() {
    showDialog(
      context: context,
      builder: (context) {
        const cardBg = Color(0xFF1B2632);
        const cardBg2 = Color(0xFF141E28);
        const buttonBlue = Color(0xFF1677FF);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cardBg, cardBg2],
              ),
              border: Border.all(color: Colors.white12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 22,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'How it works',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Share your code with friends. When they join and become active, you grow your team and improve your earning potential.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: buttonBlue),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllTeam() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF141E28),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your Team',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                if (_referrals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: Text('No referrals yet')),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _referrals.length,
                      separatorBuilder: (_, __) =>
                          Container(height: 1, color: Colors.white12),
                      itemBuilder: (context, i) {
                        final u = _referrals[i];
                        final isMining = u.status == 'Active';
                        final statusLabel = isMining ? 'Mining' : 'Inactive';
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white12,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            u.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Joined ${u.joined}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isMining
                                  ? const Color(
                                      0xFF1677FF,
                                    ).withValues(alpha: 0.20)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: isMining
                                    ? const Color(0xFF1677FF)
                                    : Colors.white54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    // PHASE 1: LOAD REFERRAL CODE (CRITICAL)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'referral_code_$uid';
      String? cachedCode = prefs.getString(cacheKey);

      // Try to load from Firestore (Source of Truth)
      // We do this separately so that if stats/team queries fail,
      // the user still gets their code.
      final userDoc = await FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .get();

      String? code;
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null &&
            data.containsKey(FirestoreUserFields.referralCode)) {
          code = data[FirestoreUserFields.referralCode]?.toString();
        }
      }

      // Fallback to cache
      if (code == null || code.isEmpty) {
        code = cachedCode;
      }

      // Generate if missing
      if (code == null || code.isEmpty) {
        code = _generateReferralCode();
        await FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .set({
              FirestoreUserFields.referralCode: code,
            }, SetOptions(merge: true));
      }

      // Update Cache
      if (code.isNotEmpty) {
        await prefs.setString(cacheKey, code);
      }

      // Update UI with Code immediately
      if (mounted) {
        setState(() {
          _referralCode = code;
        });
      }
    } catch (e) {
      debugPrint('Error loading referral code: $e');
      // If critical failure, we might stop here or try to show cached
    }

    // PHASE 2: LOAD STATS & TEAM (SECONDARY)
    try {
      final sharedDocFuture = FirestoreHelper.instance
          .collection(FirestoreConstants.referrals)
          .doc(uid)
          .get();

      final statsDocFuture = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .get();

      final results = await Future.wait([sharedDocFuture, statsDocFuture]);

      final sharedDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final statsDoc = results[1] as DocumentSnapshot<Map<String, dynamic>>;

      final List<_ReferralItem> finalOrderedItems = [];
      int activeInvited = 0;

      if (sharedDoc.exists) {
        final data = sharedDoc.data() ?? {};
        final inviteesRaw = data['invitees'];
        if (inviteesRaw is Map<String, dynamic>) {
          inviteesRaw.forEach((_, value) {
            if (value is! Map<String, dynamic>) {
              return;
            }
            final ts =
                (value[FirestoreReferralFields.timestamp] as Timestamp?)
                    ?.toDate() ??
                DateTime.now();
            final dateStr =
                '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';

            final savedUsername =
                value[FirestoreReferralFields.inviteeUsername] as String?;
            final username = (savedUsername ?? '').trim().isEmpty
                ? 'Unknown'
                : savedUsername!;

            final isActive =
                (value[FirestoreReferralFields.isActive] as bool?) ?? false;
            final status = isActive ? 'Active' : 'Not Started';
            if (isActive) {
              activeInvited++;
            }

            finalOrderedItems.add(
              _ReferralItem(
                username: username,
                status: status,
                joined: dateStr,
              ),
            );
          });

          finalOrderedItems.sort((a, b) => b.joined.compareTo(a.joined));
          if (finalOrderedItems.length > 20) {
            finalOrderedItems.removeRange(20, finalOrderedItems.length);
          }
        } else {
          debugPrint('Referrals shared doc has invalid invitees map for $uid');
        }
      } else {
        debugPrint('Referrals shared doc missing for $uid');
      }

      final statsData = statsDoc.data() ?? {};
      int totalInvited =
          (statsData[FirestoreUserFields.totalInvited] as num?)?.toInt() ?? 0;

      if (finalOrderedItems.isEmpty && totalInvited > 0) {
        try {
          final legacyQs = await FirestoreHelper.instance
              .collection(FirestoreConstants.referrals)
              .where(FirestoreReferralFields.inviterId, isEqualTo: uid)
              .orderBy(FirestoreReferralFields.timestamp, descending: true)
              .limit(20)
              .get();

          for (final d in legacyQs.docs) {
            final data = d.data();
            final ts =
                (data[FirestoreReferralFields.timestamp] as Timestamp?)
                    ?.toDate() ??
                DateTime.now();
            final dateStr =
                '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';

            final savedUsername =
                data[FirestoreReferralFields.inviteeUsername] as String?;
            final username = (savedUsername ?? '').trim().isEmpty
                ? 'Unknown'
                : savedUsername!;

            final isActive =
                (data[FirestoreReferralFields.isActive] as bool?) ?? false;
            final status = isActive ? 'Active' : 'Not Started';
            if (isActive) {
              activeInvited++;
            }

            finalOrderedItems.add(
              _ReferralItem(
                username: username,
                status: status,
                joined: dateStr,
              ),
            );
          }
        } catch (e) {
          debugPrint('Referrals legacy fallback failed for $uid: $e');
        }
      }

      if (mounted) {
        setState(() {
          _totalInvited = totalInvited;
          _activeInvited = activeInvited;
          _referrals = finalOrderedItems;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading referral stats: $e');
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _copyCode() async {
    if (_referralCode == null) return;
    await Clipboard.setData(ClipboardData(text: _referralCode!));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(_themedSnack('Referral code copied'));
  }

  Future<void> _shareLink() async {
    if (_referralCode == null) return;

    // Google Play Store link with referrer for automatic code capture
    final playStoreLink =
        'https://play.google.com/store/apps/details?id=net.etanetwork.app&pcampaignid=web_share&referrer=utm_source%3D$_referralCode';

    final text =
        'Join me on Eta Network! Use my code: $_referralCode $playStoreLink';
    try {
      // ignore: deprecated_member_use
      await Share.share(text);
    } catch (e) {
      debugPrint('Share error: $e');
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Copy this link to share:'),
              const SizedBox(height: 8),
              SelectableText(text),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(_themedSnack('Link copied'));
                Navigator.pop(context);
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const pageBgTop = Color(0xFF0B1620);
    const pageBgBottom = Color(0xFF0E1618);
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    const buttonBlue = Color(0xFF1677FF);
    const muted = Colors.white54;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Referrals'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showHowItWorks,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
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

            final codeText = (_loading && _referralCode == null)
                ? '—'
                : _formatCode(_referralCode);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(s(16), s(16), s(16), s(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(s(18)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s(22)),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [cardBg, cardBg2],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 22,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.groups_rounded,
                          size: s(44),
                          color: buttonBlue,
                        ),
                        SizedBox(height: s(10)),
                        SizedBox(
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Invite & Earn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: s(24),
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: s(8)),
                        FractionallySizedBox(
                          widthFactor: 0.95,
                          child: Text(
                            'Share your unique code with friends to boost your mining rate by 10%.',
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: s(13),
                              color: muted,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                        SizedBox(height: s(16)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: s(16),
                            vertical: s(14),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(s(14)),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(
                            child: SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  codeText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    letterSpacing: 2.0,
                                    fontSize: s(20),
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: s(14)),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: s(46),
                                child: ElevatedButton.icon(
                                  onPressed: _loading || _referralCode == null
                                      ? null
                                      : _copyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.10,
                                    ),
                                    disabledBackgroundColor: Colors.white
                                        .withValues(alpha: 0.06),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        s(14),
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(
                                    Icons.copy_rounded,
                                    size: s(18),
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Copy',
                                    style: TextStyle(
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: s(12)),
                            Expanded(
                              child: SizedBox(
                                height: s(46),
                                child: ElevatedButton.icon(
                                  onPressed: _loading || _referralCode == null
                                      ? null
                                      : _shareLink,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: buttonBlue,
                                    disabledBackgroundColor: buttonBlue
                                        .withValues(alpha: 0.35),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        s(14),
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(
                                    Icons.ios_share_rounded,
                                    size: s(18),
                                    color: Colors.white,
                                  ),
                                  label: Text(
                                    'Share Link',
                                    style: TextStyle(
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: s(14)),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'TOTAL INVITED',
                          value: _loading ? '—' : '$_totalInvited',
                          icon: Icons.group_rounded,
                          accent: Colors.white54,
                          scale: s,
                          onTap: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _filter = _ReferralFilter.all;
                                  });
                                },
                        ),
                      ),
                      SizedBox(width: s(12)),
                      Expanded(
                        child: _metricCard(
                          title: 'ACTIVE NOW',
                          value: _loading ? '—' : '$_activeInvited',
                          icon: Icons.bolt_rounded,
                          accent: buttonBlue,
                          scale: s,
                          onTap: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _filter = _ReferralFilter.active;
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(18)),
                  Row(
                    children: [
                      Text(
                        'Your Team',
                        style: TextStyle(
                          fontSize: s(18),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                setState(() {
                                  _filter = _ReferralFilter.all;
                                });
                                _showAllTeam();
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: buttonBlue,
                        ),
                        child: Text(
                          'View All  ›',
                          style: TextStyle(
                            fontSize: s(14),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(8)),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: s(6)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(s(18)),
                      color: Colors.white.withValues(alpha: 0.02),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Builder(
                      builder: (context) {
                        final visible = _filter == _ReferralFilter.active
                            ? _referrals
                                  .where((r) => r.status == 'Active')
                                  .toList()
                            : _referrals;
                        if (visible.isEmpty && !_loading) {
                          return Padding(
                            padding: EdgeInsets.all(s(16)),
                            child: const Center(
                              child: Text('No referrals yet'),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (int i = 0; i < visible.length; i++) ...[
                              _teamRow(
                                item: visible[i],
                                scale: s,
                                buttonBlue: buttonBlue,
                              ),
                              if (i != visible.length - 1)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: s(16),
                                  ),
                                  child: Container(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required double Function(double) scale,
    VoidCallback? onTap,
  }) {
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    final content = Container(
      padding: EdgeInsets.all(scale(12)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scale(18)),
        gradient: const LinearGradient(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: scale(15), color: accent),
              SizedBox(width: scale(7)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white54,
                      letterSpacing: 0.9,
                      fontSize: scale(11),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Container(
                width: scale(7),
                height: scale(7),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          SizedBox(height: scale(9)),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: scale(24),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(scale(18)),
        onTap: onTap,
        child: content,
      ),
    );
  }

  Widget _teamRow({
    required _ReferralItem item,
    required double Function(double) scale,
    required Color buttonBlue,
  }) {
    final isMining = item.status == 'Active';
    final statusLabel = isMining ? 'Mining' : 'Inactive';
    final pillBg = isMining
        ? buttonBlue.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.08);
    final pillFg = isMining ? buttonBlue : Colors.white54;

    final username = item.username.trim().isEmpty ? 'Unknown' : item.username;
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale(12), vertical: scale(6)),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: scale(20),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: scale(14),
                  ),
                ),
              ),
              Positioned(
                right: scale(0),
                bottom: scale(0),
                child: Container(
                  width: scale(10),
                  height: scale(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMining ? const Color(0xFF2ECC71) : Colors.white38,
                    border: Border.all(
                      color: const Color(0xFF0E1618),
                      width: scale(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: scale(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: scale(15.5),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: scale(2)),
                Text(
                  'Joined ${item.joined}',
                  style: TextStyle(
                    fontSize: scale(12.5),
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: scale(10)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: scale(12),
              vertical: scale(8),
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: scale(12.5),
                fontWeight: FontWeight.w800,
                color: pillFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
