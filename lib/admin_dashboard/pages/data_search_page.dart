import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/theme/colors.dart';
import '../../shared/firestore_constants.dart';
import '../../utils/firestore_helper.dart';

class DataSearchPage extends StatefulWidget {
  const DataSearchPage({super.key});

  @override
  State<DataSearchPage> createState() => _DataSearchPageState();
}

class _DataSearchPageState extends State<DataSearchPage> {
  final TextEditingController _queryCtrl = TextEditingController();
  String _searchField = 'username';
  String _view = 'summary';
  bool _loading = false;
  String _status = '';
  String? _uid;
  Map<String, dynamic>? _userData;

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _status = 'Enter a username or email';
        _uid = null;
        _userData = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _status = 'Searching...';
    });
    try {
      final col = FirestoreHelper.instance.collection(FirestoreConstants.users);
      final field = _searchField == 'email'
          ? FirestoreUserFields.email
          : FirestoreUserFields.username;
      final snap = await col.where(field, isEqualTo: q).limit(1).get();
      if (snap.docs.isEmpty) {
        setState(() {
          _uid = null;
          _userData = null;
          _status = 'No user found for "$q"';
        });
        return;
      }
      final doc = snap.docs.first;
      final data = doc.data();
      final username =
          (data[FirestoreUserFields.username] as String?) ?? doc.id;
      setState(() {
        _uid = doc.id;
        _userData = data;
        _status = 'Loaded user $username (${doc.id})';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_uid == null) return;
    await _search();
  }

  Map<String, dynamic> _extractCoins() {
    final data = _userData ?? {};
    final wallet =
        (data[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
    final nestedCoins =
        (wallet['coins'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    if (nestedCoins.isNotEmpty) {
      return Map<String, dynamic>.from(nestedCoins);
    }
    final Map<String, dynamic> coins = {};
    final prefix = '${FirestoreUserFields.wallet}.coins.';
    data.forEach((key, value) {
      if (key.startsWith(prefix) && value is Map<String, dynamic>) {
        final ownerId = key.substring(prefix.length);
        if (ownerId.isNotEmpty) {
          coins[ownerId] = value;
        }
      }
    });
    return coins;
  }

  Widget _buildSummaryView() {
    if (_uid == null || _userData == null) {
      return const SizedBox.shrink();
    }
    final data = _userData!;
    final email = (data[FirestoreUserFields.email] as String?) ?? '';
    final username = (data[FirestoreUserFields.username] as String?) ?? '';
    final totalPoints =
        (data[FirestoreUserFields.totalPoints] as num?)?.toDouble() ?? 0.0;
    final hourlyRate =
        (data[FirestoreUserFields.hourlyRate] as num?)?.toDouble() ?? 0.0;
    final rank = (data[FirestoreUserFields.rank] as String?) ?? '';
    final totalSessions =
        (data[FirestoreUserFields.totalSessions] as num?)?.toInt() ?? 0;
    final country = (data[FirestoreUserFields.country] as String?) ?? '';
    final referralCode =
        (data[FirestoreUserFields.referralCode] as String?) ?? '';
    final invitedBy = (data[FirestoreUserFields.invitedBy] as String?) ?? '';
    final totalInvited =
        (data[FirestoreUserFields.totalInvited] as num?)?.toInt() ?? 0;
    final streakDays =
        (data[FirestoreUserFields.streakDays] as num?)?.toInt() ?? 0;
    final lastMiningStart = data[FirestoreUserFields.lastMiningStart];
    final lastMiningEnd = data[FirestoreUserFields.lastMiningEnd];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Summary',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SelectableText('UID: $_uid'),
          const SizedBox(height: 4),
          SelectableText('Username: $username'),
          const SizedBox(height: 4),
          SelectableText('Email: $email'),
          const SizedBox(height: 8),
          SelectableText('User doc path: users/$_uid'),
          const SizedBox(height: 4),
          SelectableText(
            'Referral stats path: ${FirestoreConstants.referralStats}/$_uid',
          ),
          const SizedBox(height: 4),
          SelectableText(
            'Wallet coins path: users/$_uid (field: ${FirestoreUserFields.wallet}.coins)',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              Text('Total points: ${totalPoints.toStringAsFixed(3)}'),
              Text('Hourly rate: ${hourlyRate.toStringAsFixed(3)}'),
              Text('Rank: $rank'),
              Text('Sessions: $totalSessions'),
              Text('Country: $country'),
              Text('Referral code: $referralCode'),
              Text('Invited by: $invitedBy'),
              Text('Total invited: $totalInvited'),
              Text('Streak days: $streakDays'),
              Text('Last mining start: ${_formatDateLike(lastMiningStart)}'),
              Text('Last mining end: ${_formatDateLike(lastMiningEnd)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinsView() {
    if (_uid == null || _userData == null) {
      return const SizedBox.shrink();
    }
    final coins = _extractCoins();
    if (coins.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text('No coins found in wallet.'),
      );
    }
    final entries = coins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wallet Coins (from users doc)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final e in entries) ...[
            _buildCoinRow(e.key, e.value as Map<String, dynamic>),
            const Divider(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCoinRow(String ownerId, Map<String, dynamic> data) {
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? ownerId;
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final rate =
        (data[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    final total =
        (data[FirestoreUserCoinMiningFields.totalPoints] as num?)?.toDouble() ??
        0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text('Owner ID: $ownerId'),
        if (symbol.isNotEmpty) Text('Symbol: $symbol'),
        const SizedBox(height: 4),
        Text('Hourly rate: ${rate.toStringAsFixed(3)}'),
        Text('Total points: ${total.toStringAsFixed(3)}'),
      ],
    );
  }

  Widget _buildReferralsView() {
    if (_uid == null || _userData == null) {
      return const SizedBox.shrink();
    }
    final data = _userData!;
    final referralCode =
        (data[FirestoreUserFields.referralCode] as String?) ?? '';
    final invitedBy = (data[FirestoreUserFields.invitedBy] as String?) ?? '';
    final totalInvited =
        (data[FirestoreUserFields.totalInvited] as num?)?.toInt() ?? 0;
    final referrals =
        (data[FirestoreUserFields.referrals] as Map<String, dynamic>?) ??
        <String, dynamic>{};
    final totalReferrals =
        (referrals[FirestoreUserFields.totalReferrals] as num?)?.toInt() ?? 0;
    final activeReferrals =
        (referrals[FirestoreUserFields.activeReferrals] as num?)?.toInt() ?? 0;
    final totalBonus =
        (referrals[FirestoreUserFields.totalBonusEarned] as num?)?.toDouble() ??
        0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referral Overview (from users doc)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SelectableText('Referral code: $referralCode'),
          const SizedBox(height: 4),
          SelectableText('Invited by UID: $invitedBy'),
          const SizedBox(height: 8),
          Text('Total invited (legacy field): $totalInvited'),
          Text('Total referrals (map): $totalReferrals'),
          Text('Active referrals (map): $activeReferrals'),
          Text('Total referral bonus earned: ${totalBonus.toStringAsFixed(3)}'),
          const SizedBox(height: 12),
          SelectableText(
            'Referrals stats doc path: ${FirestoreConstants.referralStats}/$_uid',
          ),
          const SizedBox(height: 4),
          const Text(
            'Use this path for referral_stats lookups; detailed lists are stored in the referrals collection.',
          ),
        ],
      ),
    );
  }

  Widget _buildRawView() {
    if (_uid == null || _userData == null) {
      return const SizedBox.shrink();
    }
    final encoder = JsonEncoder.withIndent('  ', _toEncodable);
    final pretty = encoder.convert(_userData);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Raw users doc JSON',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: SingleChildScrollView(child: SelectableText(pretty)),
          ),
        ],
      ),
    );
  }

  String _formatDateLike(dynamic value) {
    if (value == null) return '—';
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  dynamic _toEncodable(Object? value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Data Search',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Username or Email',
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _searchField,
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _searchField = v;
                        });
                      },
                      items: const [
                        DropdownMenuItem(
                          value: 'username',
                          child: Text('By Username'),
                        ),
                        DropdownMenuItem(
                          value: 'email',
                          child: Text('By Email'),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _search,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Search'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: !_loading && _uid != null ? _refresh : null,
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
                if (_status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(_status, style: const TextStyle(color: Colors.white70)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_uid != null && _userData != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('UID & Paths'),
                    selected: _view == 'summary',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _view = 'summary';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Coins'),
                    selected: _view == 'coins',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _view = 'coins';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Referrals'),
                    selected: _view == 'referrals',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _view = 'referrals';
                      });
                    },
                  ),
                  ChoiceChip(
                    label: const Text('Raw JSON'),
                    selected: _view == 'raw',
                    onSelected: (v) {
                      if (!v) return;
                      setState(() {
                        _view = 'raw';
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_view == 'summary') _buildSummaryView(),
            if (_view == 'coins') _buildCoinsView(),
            if (_view == 'referrals') _buildReferralsView(),
            if (_view == 'raw') _buildRawView(),
          ],
        ],
      ),
    );
  }
}
