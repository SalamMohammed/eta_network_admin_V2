import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:convert';

import '../../shared/firestore_constants.dart';
import '../../services/coin_service.dart';
import '../../services/sql_api_service.dart';
import '../../utils/firestore_helper.dart';

void showCoinDetailsDialog(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (ctx) => CoinDetailsDialog(data: data),
  );
}

double? _safeDoubleNullable(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

List<dynamic> _safeList(dynamic val) {
  if (val == null) return [];
  if (val is List) return val;
  if (val is String) {
    try {
      final decoded = json.decode(val);
      if (decoded is List) return decoded;
    } catch (_) {}
  }
  return [];
}

class CoinDetailsDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  const CoinDetailsDialog({super.key, required this.data});

  @override
  State<CoinDetailsDialog> createState() => _CoinDetailsDialogState();
}

class _CoinDetailsDialogState extends State<CoinDetailsDialog> {
  late Map<String, dynamic> _data;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    /* if (CoinService.useSqlBackend) {
      _fetchSqlData();
    } */
  }

  /* Future<void> _fetchSqlData() async {
    final ownerId = (_data['ownerId'] as String?) ?? (_data['uid'] as String?);
    if (ownerId == null || ownerId.isEmpty) return;

    // Pass current user ID as viewerId to fetch MY mining stats
    final uid = FirebaseAuth.instance.currentUser?.uid;

    try {
      final fresh = await SqlApiService.getUserCoin(ownerId, viewerId: uid);
      if (fresh != null && mounted) {
        setState(() {
          _data = fresh;
        });
      }
    } catch (e) {
      debugPrint('Error fetching SQL coin details: $e');
    }
  } */

  @override
  Widget build(BuildContext context) {
    final ownerId = (_data['ownerId'] as String?) ?? '';
    final name = (_data['name'] as String?) ?? '—';
    final symbol = (_data['symbol'] as String?) ?? '';
    final imageUrl = (_data['imageUrl'] as String?) ?? '';
    final description =
        (_data['description'] as String?) ?? 'No description available.';
    final rate =
        _safeDoubleNullable(_data[FirestoreUserCoinMiningFields.hourlyRate]) ??
        _safeDoubleNullable(_data[FirestoreUserCoinFields.baseRatePerHour]) ??
        0.0;
    final total =
        _safeDoubleNullable(_data[FirestoreUserCoinMiningFields.totalPoints]) ??
        0.0;
    final links = _safeList(_data['socialLinks']);
    final holders =
        _safeDoubleNullable(_data['holdersCount']) ??
        _safeDoubleNullable(_data['holders']);
    final changePct =
        _safeDoubleNullable(_data['rateChangePct']) ??
        _safeDoubleNullable(_data['changePct']);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isCreator = uid != null && uid == ownerId;

    Future<double?> fetchTotalMinedAll() async {
      if (ownerId.isEmpty) return null;
      try {
        /* if (CoinService.useSqlBackend) {
          // For SQL, we might need a different endpoint or aggregation.
          // For now, return null or implement if API supports it.
          // Assuming existing logic was Firestore only.
          return null;
        } */
        final qs = await FirestoreHelper.instance
            .collectionGroup(FirestoreUserSubCollections.coins)
            .where(FirestoreUserCoinMiningFields.ownerId, isEqualTo: ownerId)
            .get();
        double sum = 0.0;
        for (final doc in qs.docs) {
          final v = _safeDoubleNullable(
            doc.data()[FirestoreUserCoinMiningFields.totalPoints],
          );
          if (v != null && v.isFinite) {
            sum += v;
          }
        }
        return sum;
      } catch (_) {
        return null;
      }
    }

    final totalMinedAllFuture = isCreator ? fetchTotalMinedAll() : null;

    const cardBg = Color(0xFF0F1A24);
    const cardBg2 = Color(0xFF0B121A);
    const surface = Color(0xFF17222C);
    const border = Color(0xFF24303B);
    const buttonBlue = Color(0xFF1677FF);
    const accentOrange = Color(0xFFFFB020);

    String compactNum(num? v) {
      if (v == null) {
        return '—';
      }
      final n = v.toDouble();
      if (!n.isFinite) {
        return '—';
      }
      final abs = n.abs();
      if (abs >= 1000000000) {
        return '${(n / 1000000000).toStringAsFixed(1)}B';
      }
      if (abs >= 1000000) {
        return '${(n / 1000000).toStringAsFixed(1)}M';
      }
      if (abs >= 1000) {
        return '${(n / 1000).toStringAsFixed(1)}k';
      }
      if (abs >= 100) {
        return n.toStringAsFixed(0);
      }
      if (abs >= 10) {
        return n.toStringAsFixed(1);
      }
      return n.toStringAsFixed(2);
    }

    String fmtRate(double v) {
      final s = v.toStringAsFixed(3);
      return s.replaceFirst(RegExp(r'\.?0+$'), '');
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 420).clamp(0.82, 1.0);
          double s(double v) => v * scale;
          var expanded = false;

          Widget metricCard({
            required IconData icon,
            required Color iconBg,
            required String title,
            required String value,
            String? suffix,
            String? footnote,
            Color? footnoteColor,
          }) {
            return Container(
              padding: EdgeInsets.all(s(14)),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(s(18)),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: s(34),
                        height: s(34),
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(s(12)),
                        ),
                        child: Icon(icon, size: s(18), color: Colors.white),
                      ),
                      SizedBox(width: s(10)),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: s(11.5),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: s(12)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: s(20),
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      if (suffix != null) ...[
                        SizedBox(width: s(6)),
                        Padding(
                          padding: EdgeInsets.only(bottom: s(2)),
                          child: Text(
                            suffix,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: s(12.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (footnote != null) ...[
                    SizedBox(height: s(6)),
                    Text(
                      footnote,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: footnoteColor ?? Colors.white54,
                        fontSize: s(12.5),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(s(26)),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cardBg, cardBg2],
                ),
                border: Border.all(color: Colors.white10),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(s(26)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: s(10)),
                    Container(
                      width: s(54),
                      height: s(5),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    SizedBox(height: s(10)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: s(18)),
                      child: Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: s(22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(s(18), 0, s(18), s(16)),
                        child: StatefulBuilder(
                          builder: (context, setLocal) {
                            void toggle() =>
                                setLocal(() => expanded = !expanded);

                            final showReadMore = description.length > 140;
                            final aboutText = description;

                            return Column(
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    SizedBox(
                                      width: s(112),
                                      height: s(112),
                                      child: Stack(
                                        children: [
                                          Positioned.fill(
                                            child: ClipOval(
                                              child: imageUrl.isNotEmpty
                                                  ? Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stack,
                                                          ) {
                                                            return Container(
                                                              color: Colors
                                                                  .white10,
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              child: Icon(
                                                                Icons
                                                                    .monetization_on_rounded,
                                                                size: s(42),
                                                                color: Colors
                                                                    .white54,
                                                              ),
                                                            );
                                                          },
                                                    )
                                                  : Container(
                                                      color: Colors.white10,
                                                      alignment:
                                                          Alignment.center,
                                                      child: Icon(
                                                        Icons
                                                            .monetization_on_rounded,
                                                        size: s(42),
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: accentOrange,
                                                  width: s(2),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      right: s(4),
                                      bottom: s(6),
                                      child: Container(
                                        width: s(26),
                                        height: s(26),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: buttonBlue,
                                          border: Border.all(
                                            color: cardBg,
                                            width: s(2),
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check_rounded,
                                          color: Colors.white,
                                          size: s(16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: s(12)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: s(26),
                                          fontWeight: FontWeight.w900,
                                          height: 1.05,
                                        ),
                                      ),
                                    ),
                                    if (symbol.isNotEmpty) ...[
                                      SizedBox(width: s(8)),
                                      Text(
                                        '(\$$symbol)',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: s(16),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                if (ownerId.isNotEmpty) ...[
                                  SizedBox(height: s(8)),
                                  FutureBuilder<
                                    DocumentSnapshot<Map<String, dynamic>>
                                  >(
                                    future: FirestoreHelper.instance
                                        .collection(FirestoreConstants.users)
                                        .doc(ownerId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      final u = snapshot.data?.data();
                                      final username =
                                          (u?[FirestoreUserFields.username]
                                              as String?) ??
                                          'Unknown';
                                      return Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: s(12),
                                          vertical: s(8),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            CircleAvatar(
                                              radius: s(10),
                                              backgroundColor: Colors.white12,
                                              child: Icon(
                                                Icons.person_rounded,
                                                size: s(14),
                                                color: Colors.white70,
                                              ),
                                            ),
                                            SizedBox(width: s(8)),
                                            Text(
                                              'Created by @$username',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: s(13.5),
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                            SizedBox(width: s(8)),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: Colors.white54,
                                              size: s(18),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                                SizedBox(height: s(18)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: metricCard(
                                        icon: Icons.bolt_rounded,
                                        iconBg: const Color(
                                          0xFF1B4BFF,
                                        ).withValues(alpha: 0.35),
                                        title: 'Mining rate',
                                        value: fmtRate(rate),
                                        suffix: 'ETA/hr',
                                        footnote: changePct == null
                                            ? null
                                            : '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(1)}%',
                                        footnoteColor: changePct == null
                                            ? null
                                            : (changePct >= 0
                                                  ? const Color(0xFF2ECC71)
                                                  : const Color(0xFFFF5A5F)),
                                      ),
                                    ),
                                    SizedBox(width: s(12)),
                                    Expanded(
                                      child: LiveMinedDisplay(
                                        uid: uid ?? '',
                                        coinOwnerId: ownerId,
                                        initialData: _data,
                                        builder: (v) {
                                          final valStr = v.toStringAsFixed(4);
                                          return metricCard(
                                            icon: Icons.layers_rounded,
                                            iconBg: const Color(
                                              0xFF8B5CF6,
                                            ).withValues(alpha: 0.28),
                                            title: 'Your mined',
                                            value: valStr,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: s(12)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: metricCard(
                                        icon: Icons.groups_rounded,
                                        iconBg: const Color(
                                          0xFFFF4D9D,
                                        ).withValues(alpha: 0.22),
                                        title: 'Holders',
                                        value: compactNum(holders),
                                      ),
                                    ),
                                    SizedBox(width: s(12)),
                                    Expanded(
                                      child: isCreator
                                          ? FutureBuilder<double?>(
                                              future: totalMinedAllFuture,
                                              builder: (context, snap) {
                                                final done =
                                                    snap.connectionState ==
                                                    ConnectionState.done;
                                                final v = done
                                                    ? snap.data
                                                    : null;
                                                return metricCard(
                                                  icon: Icons.layers_rounded,
                                                  iconBg: const Color(
                                                    0xFF8B5CF6,
                                                  ).withValues(alpha: 0.28),
                                                  title: 'Total mined',
                                                  value: done
                                                      ? compactNum(v)
                                                      : '…',
                                                );
                                              },
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: s(18)),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'About $name',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s(16),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                SizedBox(height: s(8)),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    aboutText,
                                    maxLines: showReadMore && !expanded
                                        ? 4
                                        : 999,
                                    overflow: showReadMore && !expanded
                                        ? TextOverflow.ellipsis
                                        : TextOverflow.visible,
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                                if (showReadMore) ...[
                                  SizedBox(height: s(8)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: toggle,
                                      child: Text(
                                        expanded ? 'Read Less' : 'Read More',
                                        style: TextStyle(
                                          color: buttonBlue,
                                          fontSize: s(13.5),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (links.isNotEmpty) ...[
                                  SizedBox(height: s(18)),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Project Links',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: s(14),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: s(10)),
                                  Wrap(
                                    spacing: s(8),
                                    runSpacing: s(8),
                                    children: [
                                      for (final l in links)
                                        if (l is Map)
                                          LinkButton(
                                            type:
                                                (l['type'] as String?) ??
                                                'other',
                                            url: (l['url'] as String?) ?? '',
                                          ),
                                    ],
                                  ),
                                ],
                                SizedBox(height: s(18)),
                                SizedBox(
                                  width: double.infinity,
                                  height: s(52),
                                  child: ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonBlue,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        fontSize: s(15),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LinkButton extends StatelessWidget {
  final String type;
  final String url;
  const LinkButton({super.key, required this.type, required this.url});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color? color;
    switch (type.toLowerCase()) {
      case 'website':
        icon = Icons.language;
        break;
      case 'youtube':
        icon = Icons.play_circle_fill;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'twitter':
      case 'x':
        icon = Icons.close;
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.purpleAccent;
        break;
      case 'telegram':
        icon = Icons.send;
        color = Colors.lightBlue;
        break;
      default:
        icon = Icons.link;
    }

    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 16,
        icon: Icon(icon, color: color ?? Colors.white70),
        tooltip: type,
        onPressed: () async {
          if (url.isEmpty) return;
          var uri = Uri.tryParse(url);
          if (uri == null) return;
          if (!uri.hasScheme) {
            uri = Uri.tryParse('https://$url');
          }
          try {
            if (uri != null && await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            debugPrint('LinkButton: Launch error: $e');
          }
        },
      ),
    );
  }
}

class LiveMinedDisplay extends StatefulWidget {
  final String uid;
  final String coinOwnerId;
  final Widget Function(double value) builder;
  final Map<String, dynamic>? initialData;

  const LiveMinedDisplay({
    super.key,
    required this.uid,
    required this.coinOwnerId,
    required this.builder,
    this.initialData,
  });

  @override
  State<LiveMinedDisplay> createState() => _LiveMinedDisplayState();
}

class _LiveMinedDisplayState extends State<LiveMinedDisplay>
    with WidgetsBindingObserver {
  Timer? _timer;
  double _display = 0.0;
  Timestamp? _end;
  double _rate = 0.0;
  Timestamp? _start;
  double _totalBase = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      _timer = null;
    } else if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (_end != null && now.isBefore(_end!.toDate())) {
        _startTimer();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Timestamp? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is String) {
      String toParse = val;
      if (val.contains(' ') && !val.contains('T')) {
        toParse = val.replaceFirst(' ', 'T');
      }
      final dt = DateTime.tryParse(toParse);
      if (dt != null) return Timestamp.fromDate(dt);
    }
    return null;
  }

  double _parseDouble(dynamic val) {
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  double _extractTotal(Map<String, dynamic> d) {
    if (d.containsKey(FirestoreUserCoinMiningFields.totalPoints)) {
      return _parseDouble(d[FirestoreUserCoinMiningFields.totalPoints]);
    }
    final wallet =
        (d[FirestoreUserFields.wallet] as Map<String, dynamic>?) ?? {};
    final coins = (wallet['coins'] as Map<String, dynamic>?) ?? {};
    final coin = coins[widget.coinOwnerId];
    if (coin is Map<String, dynamic>) {
      final v = coin[FirestoreUserCoinMiningFields.totalPoints];
      return _parseDouble(v);
    }
    return 0.0;
  }

  void _processData(Map<String, dynamic> d) {
    final total = _extractTotal(d);
    final end = _parseTimestamp(d[FirestoreUserCoinMiningFields.lastMiningEnd]);
    final rate = _parseDouble(d[FirestoreUserCoinMiningFields.hourlyRate]);
    final synced = _parseTimestamp(
      d[FirestoreUserCoinMiningFields.lastSyncedAt],
    );
    final start = _parseTimestamp(
      d[FirestoreUserCoinMiningFields.lastMiningStart],
    );

    final now = DateTime.now();
    final active = end != null && now.isBefore(end.toDate());

    _rate = rate;
    _end = end;
    _start = synced ?? start;
    _totalBase = total;

    if (_start != null && _end != null) {
      final s = _start!.toDate();
      final e = _end!.toDate();
      final totalSessionSec = e.difference(s).inSeconds.toDouble();

      if (active) {
        final elapsedSec = now.difference(s).inSeconds.toDouble();
        final inc = (elapsedSec * (_rate / 3600.0)).clamp(
          0.0,
          totalSessionSec * (_rate / 3600.0),
        );
        _display = _totalBase + inc;
      } else {
        if (totalSessionSec > 0) {
          final fullEarned = (totalSessionSec * (_rate / 3600.0));
          _display = _totalBase + fullEarned;
        } else {
          _display = _totalBase;
        }
      }
    } else {
      _display = _totalBase;
    }

    if (active) {
      if (_timer == null) {
        _startTimer();
      }
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
      final end = _end?.toDate();
      final start = _start?.toDate();
      if (end == null || start == null) return;
      final now = DateTime.now();
      if (!now.isBefore(end)) {
        _timer?.cancel();
        _timer = null;
        final totalSessionSec = end.difference(start).inSeconds.toDouble();
        final fullEarned = totalSessionSec * (_rate / 3600.0);
        _display = _totalBase + fullEarned;
        if (mounted) setState(() {});
        return;
      }
      final elapsedSec = now.difference(start).inSeconds.toDouble();
      final totalSessionSec = end.difference(start).inSeconds.toDouble();
      final inc = (elapsedSec * (_rate / 3600.0)).clamp(
        0.0,
        totalSessionSec * (_rate / 3600.0),
      );

      final oldDisplay = _display;
      _display = _totalBase + inc;

      if (mounted &&
          (_display.toStringAsFixed(3) != oldDisplay.toStringAsFixed(3))) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Stream<Map<String, dynamic>?> stream;
    if (CoinService.useSqlBackend) {
      // For SQL, we rely on initialData (fetched in dialog) or manual polling if needed.
      // watchUserCoin(uid) returns the *created* coin, which is wrong if uid != coinOwnerId.
      if (widget.uid == widget.coinOwnerId) {
        stream = CoinService.watchUserCoin(widget.uid);
      } else {
        // No stream for mined coins in SQL yet (unless we poll getMyCoins)
        stream = Stream.value(null);
      }
    } else {
      stream = FirestoreHelper.instance
          .collection(FirestoreConstants.users)
          .doc(widget.uid)
          .snapshots()
          .map((snap) {
            final data = snap.data() ?? {};
            final wallet =
                (data[FirestoreUserFields.wallet] as Map<String, dynamic>?) ??
                {};
            final coins = (wallet['coins'] as Map<String, dynamic>?) ?? {};
            final coin = coins[widget.coinOwnerId];
            if (coin is Map<String, dynamic>) {
              return Map<String, dynamic>.from(coin);
            }
            return null;
          });
    }

    return StreamBuilder<Map<String, dynamic>?>(
      stream: stream,
      builder: (context, snap) {
        final d = snap.data;
        if (d != null) {
          _processData(d);
        }
        return widget.builder(_display);
      },
    );
  }
}
