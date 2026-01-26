import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../shared/firestore_constants.dart';
import '../../shared/theme/colors.dart';
import '../../services/coin_service.dart';
import '../../shared/device_id.dart';
import '../../shared/pick_image_io.dart'
    if (dart.library.html) '../../shared/pick_image_web.dart'
    as picker;
import 'dart:typed_data';
import '../widgets/coin_details_dialog.dart';

enum MyCoinBlockVariant { standard, home }

class MyCoinBlock extends StatelessWidget {
  final MyCoinBlockVariant variant;
  const MyCoinBlock({super.key, this.variant = MyCoinBlockVariant.standard});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<Map<String, dynamic>?>(
      stream: CoinService.watchUserCoin(uid),
      builder: (ctx, snap) {
        final data = snap.data;
        if (data == null || (data[FirestoreUserCoinFields.isActive] != true)) {
          return _NoCoinCard(
            variant: variant,
            onCreate: () {
              showDialog(
                context: context,
                builder: (_) => const CreateCoinDialog(),
              );
            },
          );
        }
        return _CoinCard(
          data: data,
          variant: variant,
          onEdit: () {
            showDialog(
              context: context,
              builder: (_) => CreateCoinDialog(initial: data),
            );
          },
        );
      },
    );
  }
}

class _NoCoinCard extends StatelessWidget {
  final VoidCallback onCreate;
  final MyCoinBlockVariant variant;
  const _NoCoinCard({required this.onCreate, required this.variant});

  Widget _homeCard(BuildContext context) {
    const g1 = Color(0xFF5A46FF);
    const g2 = Color(0xFF8A2BFF);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(0.7, 1.0);
        double s(double v) => v * scale;
        return GestureDetector(
          onTap: onCreate,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(s(22)),
            child: Container(
              height: s(114),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [g1, g2],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DotPatternPainter(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(s(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FractionallySizedBox(
                                widthFactor: 0.75,
                                alignment: Alignment.centerLeft,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Create Community Coin',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: s(20),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: s(6)),
                              FractionallySizedBox(
                                widthFactor: 0.88,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Launch your own coin on ETA Network instantly.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: s(13.4),
                                    color: Colors.white70,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: s(10)),
                        Container(
                          width: s(50),
                          height: s(50),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            size: s(28),
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (variant == MyCoinBlockVariant.home) {
      return _homeCard(context);
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Create your own coin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 6),
                Text(
                  'Launch your own community coin that other ETA users can mine.',
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onCreate, child: const Text('Create Coin')),
        ],
      ),
    );
  }
}

class _CoinCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final MyCoinBlockVariant variant;
  const _CoinCard({
    required this.data,
    required this.onEdit,
    required this.variant,
  });

  Widget _homeCard(BuildContext context) {
    const cardBg = Color(0xFF0F1A24);
    const cardBg2 = Color(0xFF0B121A);
    const border = Color(0xFF24303B);
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final rawRate = data[FirestoreUserCoinFields.baseRatePerHour];
    final rate = (rawRate is num)
        ? rawRate.toDouble()
        : (rawRate is String ? double.tryParse(rawRate) ?? 0.0 : 0.0);
    final img = (data[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final links =
        (data[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ??
        const [];
    final ownerId = (data[FirestoreUserCoinFields.ownerId] as String?) ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 380).clamp(0.78, 1.0);
        double s(double v) => v * scale;

        Future<void> openLink(String url) async {
          if (url.isEmpty) return;
          final uri = Uri.tryParse(url);
          if (uri == null) return;
          try {
            final ok = await canLaunchUrl(uri);
            if (!ok) return;
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {}
        }

        String firstLinkUrl(String type) {
          for (final l in links) {
            final t = (l['type'] as String?) ?? '';
            final u = (l['url'] as String?) ?? '';
            if (t.toLowerCase() == type.toLowerCase() && u.isNotEmpty) {
              return u;
            }
          }
          return '';
        }

        final websiteUrl = firstLinkUrl('website');
        final telegramUrl = firstLinkUrl('telegram');
        final twitterUrl = firstLinkUrl('twitter');
        final instagramUrl = firstLinkUrl('instagram');
        final youtubeUrl = firstLinkUrl('youtube');
        final facebookUrl = firstLinkUrl('facebook');

        Widget iconPill({
          required IconData icon,
          required VoidCallback? onPressed,
        }) {
          return Container(
            width: s(30),
            height: s(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(s(10)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: onPressed,
              icon: Icon(icon, size: s(16), color: Colors.white70),
            ),
          );
        }

        final iconWidgets = <Widget>[];
        if (websiteUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.language_rounded,
              onPressed: () => openLink(websiteUrl),
            ),
          );
        }
        if (telegramUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.send_rounded,
              onPressed: () => openLink(telegramUrl),
            ),
          );
        }
        if (twitterUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.close_rounded,
              onPressed: () => openLink(twitterUrl),
            ),
          );
        }
        if (instagramUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.camera_alt_rounded,
              onPressed: () => openLink(instagramUrl),
            ),
          );
        }
        if (youtubeUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.play_circle_fill_rounded,
              onPressed: () => openLink(youtubeUrl),
            ),
          );
        }
        if (facebookUrl.isNotEmpty) {
          iconWidgets.add(
            iconPill(
              icon: Icons.facebook_rounded,
              onPressed: () => openLink(facebookUrl),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(s(22)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => showCoinDetailsDialog(context, data),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cardBg, cardBg2],
                  ),
                  border: Border.all(color: border),
                  borderRadius: BorderRadius.circular(s(22)),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(s(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: s(66),
                            height: s(66),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(s(18)),
                              color: Colors.white.withValues(alpha: 0.06),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                              image: img.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(img),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: img.isEmpty
                                ? Icon(
                                    Icons.token_rounded,
                                    color: Colors.white54,
                                    size: s(28),
                                  )
                                : null,
                          ),
                          SizedBox(width: s(14)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: s(20),
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: onEdit,
                                      icon: Icon(
                                        Icons.edit_rounded,
                                        color: Colors.white70,
                                        size: s(18),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: s(8)),
                                Row(
                                  children: [
                                    if (symbol.trim().isNotEmpty)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: s(10),
                                          vertical: s(6),
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            s(10),
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.12,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          symbol.trim(),
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w900,
                                            fontSize: s(12),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                    if (iconWidgets.isNotEmpty &&
                                        symbol.trim().isNotEmpty) ...[
                                      SizedBox(width: s(12)),
                                      Container(
                                        width: 1,
                                        height: s(18),
                                        color: Colors.white24,
                                      ),
                                      SizedBox(width: s(12)),
                                    ],
                                    if (iconWidgets.isNotEmpty)
                                      Wrap(
                                        spacing: s(10),
                                        runSpacing: s(10),
                                        children: iconWidgets,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: s(14)),
                      Container(height: 1, color: Colors.white12),
                      SizedBox(height: s(14)),
                      CoinMiningControls(
                        coinOwnerId: ownerId,
                        baseRate: rate,
                        symbol: symbol,
                        variant: CoinMiningControlsVariant.myCoinCard,
                        miningData: data,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (variant == MyCoinBlockVariant.home) {
      return _homeCard(context);
    }
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final rawRate = data[FirestoreUserCoinFields.baseRatePerHour];
    final rate = (rawRate is num)
        ? rawRate.toDouble()
        : (rawRate is String ? double.tryParse(rawRate) ?? 0.0 : 0.0);
    final img = (data[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final links =
        (data[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ??
        const [];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showCoinDetailsDialog(context, data),
      child: Container(
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryAccent,
                  backgroundImage: img.isNotEmpty ? NetworkImage(img) : null,
                  child: img.isEmpty
                      ? Text(name.isNotEmpty ? name[0] : '?')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (symbol.isNotEmpty)
                        Text(
                          symbol,
                          style: const TextStyle(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: onEdit,
                  child: const Text('Edit coin'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Base rate: ${rate.toStringAsFixed(3)} coins/hour'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final l in links)
                  LinkButton(
                    type: (l['type'] as String?) ?? 'other',
                    url: (l['url'] as String?) ?? '',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            CoinMiningControls(
              coinOwnerId:
                  (data[FirestoreUserCoinFields.ownerId] as String?) ?? '',
            ),
          ],
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  final Color color;
  const _DotPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    const gap = 22.0;
    const r = 1.3;
    for (double y = 0; y < size.height + gap; y += gap) {
      final shift = ((y ~/ gap) % 2) * (gap / 2);
      for (double x = -gap; x < size.width + gap; x += gap) {
        canvas.drawCircle(Offset(x + shift, y), r, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class CreateCoinDialog extends StatefulWidget {
  final Map<String, dynamic>? initial;
  const CreateCoinDialog({super.key, this.initial});
  @override
  State<CreateCoinDialog> createState() => _CreateCoinDialogState();
}

class _CreateCoinDialogState extends State<CreateCoinDialog> {
  final nameCtrl = TextEditingController();
  final symbolCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final List<_LinkRow> _rows = [];
  bool _allowImageUpload = false;
  int _maxDesc = 500;
  int _maxLinks = 6;
  double _minRate = 0.01;
  double _maxRate = 10.0;
  bool _submitting = false;
  Uint8List? _thumbBytes;
  String? _initialImageUrl;
  String? _thumbContentType;
  bool _isEditing = false;

  OverlayEntry? _errorOverlay;

  @override
  void dispose() {
    _errorOverlay?.remove();
    nameCtrl.dispose();
    symbolCtrl.dispose();
    descCtrl.dispose();
    rateCtrl.dispose();
    for (final r in _rows) {
      r.urlCtrl.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadConfig();
    final init = widget.initial;
    if (init != null) {
      _isEditing = true;
      nameCtrl.text = (init[FirestoreUserCoinFields.name] as String?) ?? '';
      symbolCtrl.text = (init[FirestoreUserCoinFields.symbol] as String?) ?? '';
      _initialImageUrl =
          (init[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
      descCtrl.text =
          (init[FirestoreUserCoinFields.description] as String?) ?? '';
      final rate = (init[FirestoreUserCoinFields.baseRatePerHour] as num?)
          ?.toDouble();
      if (rate != null) rateCtrl.text = rate.toString();
      final links =
          (init[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ?? [];
      for (final l in links) {
        _rows.add(
          _LinkRow(
            type: (l['type'] as String?) ?? 'website',
            url: (l['url'] as String?) ?? '',
          ),
        );
      }
    }
  }

  Future<void> _loadConfig() async {
    final cfg = await CoinService.getUserCoinConfig();
    _allowImageUpload =
        (cfg[FirestoreAppConfigFields.allowImageUpload] as bool?) ?? false;
    _maxDesc =
        (cfg[FirestoreAppConfigFields.maxDescriptionLength] as num?)?.toInt() ??
        500;
    _maxLinks =
        (cfg[FirestoreAppConfigFields.maxSocialLinks] as num?)?.toInt() ?? 6;
    _minRate =
        (cfg[FirestoreAppConfigFields.minRatePerHour] as num?)?.toDouble() ??
        0.01;
    _maxRate =
        (cfg[FirestoreAppConfigFields.maxRatePerHour] as num?)?.toDouble() ??
        10.0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFF1B2632);
    const cardBg2 = Color(0xFF141E28);
    const buttonBlue = Color(0xFF1677FF);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = (constraints.maxWidth / 420).clamp(0.82, 1.0);
          double s(double v) => v * scale;

          final fieldBorder = OutlineInputBorder(
            borderRadius: BorderRadius.circular(s(14)),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          );
          final focusedBorder = OutlineInputBorder(
            borderRadius: BorderRadius.circular(s(14)),
            borderSide: const BorderSide(color: AppColors.primaryAccent),
          );

          InputDecoration deco(String label, {String? helperText}) {
            return InputDecoration(
              labelText: label,
              helperText: helperText,
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: fieldBorder,
              enabledBorder: fieldBorder,
              focusedBorder: focusedBorder,
              contentPadding: EdgeInsets.symmetric(
                horizontal: s(14),
                vertical: s(12),
              ),
            );
          }

          final ImageProvider<Object>? avatarImage = _thumbBytes != null
              ? MemoryImage(_thumbBytes!)
              : (_initialImageUrl != null && _initialImageUrl!.isNotEmpty)
              ? NetworkImage(_initialImageUrl!)
              : null;

          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Container(
              padding: EdgeInsets.fromLTRB(s(18), s(18), s(18), s(14)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(s(22)),
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isEditing
                                ? 'Edit Community Coin'
                                : 'Create Community Coin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: s(20),
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ),
                        SizedBox(width: s(8)),
                        IconButton(
                          onPressed: _submitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                            size: s(22),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(6)),
                    Text(
                      'Launch your own coin inside ETA ecosystem for your community.',
                      style: TextStyle(
                        fontSize: s(13.4),
                        color: Colors.white70,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: s(16)),
                    Center(
                      child: Column(
                        children: [
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              onTap: (!_allowImageUpload || _submitting)
                                  ? null
                                  : _pickImage,
                              customBorder: const CircleBorder(),
                              child: Container(
                                width: s(92),
                                height: s(92),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: s(46),
                                  backgroundColor: Colors.transparent,
                                  backgroundImage: avatarImage,
                                  child: avatarImage == null
                                      ? Icon(
                                          Icons.token_rounded,
                                          color: Colors.white70,
                                          size: s(28),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          if (_allowImageUpload) ...[
                            SizedBox(height: s(8)),
                            Text(
                              'Upload',
                              style: TextStyle(
                                fontSize: s(13.5),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: s(2)),
                            Text(
                              'Recommended 200×200px',
                              style: TextStyle(
                                fontSize: s(12.2),
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: s(16)),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: nameCtrl,
                            decoration: deco('Coin name'),
                          ),
                        ),
                        SizedBox(width: s(10)),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: symbolCtrl,
                            decoration: deco('Symbol'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(10)),
                    TextField(
                      controller: descCtrl,
                      minLines: 4,
                      maxLines: 6,
                      onChanged: (_) => setState(() {}),
                      decoration: deco(
                        'Description',
                        helperText: '${descCtrl.text.length}/$_maxDesc',
                      ),
                    ),
                    SizedBox(height: s(10)),
                    TextField(
                      controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: deco(
                        'Base mining rate (coins/hour)',
                        helperText: 'Max Allowed : $_maxRate',
                      ),
                    ),
                    SizedBox(height: s(14)),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Social & project links (optional)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w800,
                              fontSize: s(13.5),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            if (_rows.length >= _maxLinks) return;
                            setState(() => _rows.add(_LinkRow()));
                          },
                          icon: Icon(
                            Icons.add_link_rounded,
                            color: Colors.white70,
                            size: s(22),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: s(6)),
                    Column(
                      children: [
                        for (int i = 0; i < _rows.length; i++)
                          Padding(
                            padding: EdgeInsets.only(bottom: s(8)),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: s(10),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(s(14)),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _rows[i].type,
                                      dropdownColor: cardBg,
                                      iconEnabledColor: Colors.white70,
                                      onChanged: (v) => setState(
                                        () => _rows[i].type = v ?? 'website',
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'website',
                                          child: Text('Website'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'youtube',
                                          child: Text('YouTube'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'facebook',
                                          child: Text('Facebook'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'twitter',
                                          child: Text('X / Twitter'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'instagram',
                                          child: Text('Instagram'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'telegram',
                                          child: Text('Telegram'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'other',
                                          child: Text('Other'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: s(10)),
                                Expanded(
                                  child: TextField(
                                    controller: _rows[i].urlCtrl,
                                    decoration: deco('Paste URL'),
                                  ),
                                ),
                                SizedBox(width: s(6)),
                                IconButton(
                                  onPressed: () =>
                                      setState(() => _rows.removeAt(i)),
                                  icon: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white54,
                                    size: s(22),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: s(12)),
                    Container(
                      padding: EdgeInsets.all(s(12)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(s(16)),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Important Notice ',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: s(12.6),
                                height: 1.25,
                              ),
                            ),
                            TextSpan(
                              text:
                                  'This coin is part of the ETA Network ecosystem and represents participation in a growing digital community. Community coins are created by users to build, experiment, and engage within the network.ETA Network is in an early stage of development. As the ecosystem grows, new utilities, features, and integrations may be introduced based on community activity, platform evolution, and applicable guidelines.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w700,
                                fontSize: s(12.6),
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: s(14)),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: s(50),
                            child: OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white70,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(s(16)),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: s(14.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: s(12)),
                        Expanded(
                          child: SizedBox(
                            height: s(50),
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: buttonBlue.withValues(
                                  alpha: 0.35,
                                ),
                                disabledForegroundColor: Colors.white
                                    .withValues(alpha: 0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(s(16)),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _submitting
                                        ? Icons.hourglass_top_rounded
                                        : (_isEditing
                                              ? Icons.save_rounded
                                              : Icons.rocket_launch_rounded),
                                    size: s(18),
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: s(10)),
                                  Text(
                                    _submitting
                                        ? 'Please wait…'
                                        : (_isEditing ? 'Save' : 'Create Coin'),
                                    style: TextStyle(
                                      fontSize: s(14.5),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  bool _validUrl(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  void _showError(String message) {
    if (!mounted) return;

    _errorOverlay?.remove();
    _errorOverlay = null;

    final overlay = Overlay.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final padding = MediaQuery.of(context).padding;
    final bottomOffset = (viewInsets.bottom > 0)
        ? viewInsets.bottom + 16
        : padding.bottom + 20;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: bottomOffset,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFCF6679),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _errorOverlay?.remove();
                    _errorOverlay = null;
                  },
                  child: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    _errorOverlay = entry;

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _errorOverlay == entry) {
        entry.remove();
        _errorOverlay = null;
      }
    });
  }

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // validation
    final name = nameCtrl.text.trim();
    final rawSymbol = symbolCtrl.text.trim();
    final symbol = rawSymbol
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase()
        .trim();
    final desc = descCtrl.text.trim();
    final rate = double.tryParse(rateCtrl.text.trim());
    if (name.length < 3 || name.length > 30) {
      _showError('Coin name must be 3–30 characters.');
      return;
    }
    if (symbol.isEmpty) {
      _showError('Symbol is required.');
      return;
    }
    if (symbol.length < 2 || symbol.length > 10) {
      _showError('Symbol must be 2–10 letters/numbers.');
      return;
    }
    if (symbolCtrl.text.trim() != symbol) {
      symbolCtrl.value = TextEditingValue(
        text: symbol,
        selection: TextSelection.collapsed(offset: symbol.length),
      );
    }
    if (desc.length > _maxDesc) {
      _showError('Description is too long.');
      return;
    }
    if (rate == null || rate < _minRate || rate > _maxRate) {
      _showError('Base mining rate is out of range.');
      return;
    }

    // Check name uniqueness
    final nameVariants = <String>{
      name,
      name.toLowerCase(),
      name.toUpperCase(),
    }.where((s) => s.trim().isNotEmpty).toList();

    for (final v in nameVariants) {
      final qs = await FirebaseFirestore.instance
          .collection(FirestoreConstants.userCoins)
          .where(FirestoreUserCoinFields.name, isEqualTo: v)
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty && qs.docs.first.id != uid) {
        _showError('Coin name already exists. Please choose another.');
        return;
      }
    }

    final checkVariants = <String>{
      symbol,
      rawSymbol,
      rawSymbol.toUpperCase(),
      rawSymbol.toLowerCase(),
    }.where((s) => s.trim().isNotEmpty).toList();
    for (final v in checkVariants) {
      final qs = await FirebaseFirestore.instance
          .collection(FirestoreConstants.userCoins)
          .where(FirestoreUserCoinFields.symbol, isEqualTo: v)
          .limit(1)
          .get();
      if (qs.docs.isNotEmpty && qs.docs.first.id != uid) {
        _showError('Symbol already exists. Please choose another.');
        return;
      }
    }
    final links = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final u = r.urlCtrl.text.trim();
      if (u.isEmpty) continue;
      if (!_validUrl(u)) {
        _showError('One of the URLs is invalid.');
        return;
      }
      links.add({'type': r.type, 'iconName': r.type, 'url': u});
    }

    setState(() => _submitting = true);
    debugPrint(
      '[CreateCoinDialog] Submit start | isEditing=$_isEditing | name=$name | symbol=$symbol | hasThumb=${_thumbBytes != null} | initialImageSet=${_initialImageUrl != null && _initialImageUrl!.isNotEmpty}',
    );

    final now = FieldValue.serverTimestamp();
    final Map<String, dynamic> coinDoc = {
      FirestoreUserCoinFields.ownerId: uid,
      FirestoreUserCoinFields.name: name,
      FirestoreUserCoinFields.symbol: symbol,
      FirestoreUserCoinFields.description: desc,
      FirestoreUserCoinFields.socialLinks: links,
      FirestoreUserCoinFields.baseRatePerHour: rate,
      FirestoreUserCoinFields.updatedAt: now,
    };
    if (!_isEditing) {
      coinDoc[FirestoreUserCoinFields.createdAt] = now;
      coinDoc[FirestoreUserCoinFields.isActive] = true;
    }
    if (_thumbBytes == null &&
        (_initialImageUrl != null && _initialImageUrl!.isNotEmpty)) {
      coinDoc[FirestoreUserCoinFields.imageUrl] = _initialImageUrl!;
    }
    try {
      await CoinService.createOrUpdateUserCoin(
        uid: uid,
        coin: coinDoc,
        merge: _isEditing,
        thumbnailBytes: _thumbBytes,
        thumbnailContentType: _thumbContentType,
      );
    } catch (e) {
      setState(() => _submitting = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
      return;
    }
    debugPrint('[CreateCoinDialog] Submit end');
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage();
    if (picked == null) return;
    setState(() {
      _thumbBytes = picked.bytes;
      _thumbContentType = picked.contentType;
    });
  }
}

class _LinkRow {
  String type;
  final TextEditingController urlCtrl;
  _LinkRow({this.type = 'website', String url = ''})
    : urlCtrl = TextEditingController(text: url);
}

class CoinMiningControls extends StatefulWidget {
  final String coinOwnerId;
  final Map<String, dynamic>? miningData;
  final double? baseRate;
  final String? symbol;
  final CoinMiningControlsVariant variant;
  const CoinMiningControls({
    super.key,
    required this.coinOwnerId,
    this.miningData,
    this.baseRate,
    this.symbol,
    this.variant = CoinMiningControlsVariant.compact,
  });
  @override
  State<CoinMiningControls> createState() => _CoinMiningControlsState();
}

enum CoinMiningControlsVariant { compact, detailed, myCoinCard }

class _CoinMiningControlsState extends State<CoinMiningControls> {
  Timer? _timer;
  double _display = 0.0;
  Timestamp? _end;
  double _rate = 0.0;
  Timestamp? _start;
  double _totalBase = 0.0;
  Map<String, dynamic>? _localOverrideData;

  @override
  void didUpdateWidget(CoinMiningControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isSameState(widget.miningData, oldWidget.miningData)) {
      _localOverrideData = null;
    }
  }

  bool _isSameState(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;

    // Key fields that define the mining state
    const keys = [
      FirestoreUserCoinMiningFields.lastMiningEnd,
      FirestoreUserCoinMiningFields.lastMiningStart,
      FirestoreUserCoinMiningFields.totalPoints,
      FirestoreUserCoinMiningFields.hourlyRate,
      FirestoreUserCoinFields.isActive,
    ];

    for (final k in keys) {
      final v1 = a[k];
      final v2 = b[k];
      // Simple string comparison handles Timestamp vs String (SQL) differences roughly,
      // but ideally we should compare parsed values.
      // For preventing redundant updates, direct comparison is usually enough
      // if the source format hasn't changed.
      if (v1.toString() != v2.toString()) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _localOverrideData ?? widget.miningData;
    if (data != null) {
      _processData(data);
      return _buildUI();
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.coinOwnerId.isEmpty) {
      return const SizedBox.shrink();
    }
    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(uid)
        .collection(FirestoreUserSubCollections.coins)
        .doc(widget.coinOwnerId);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data();
        if (d != null) {
          _processData(d);
        }
        return _buildUI();
      },
    );
  }

  Timestamp? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is String) {
      // Handle MySQL format "YYYY-MM-DD HH:MM:SS" by replacing space with T
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

  void _processData(Map<String, dynamic> d) {
    final total = _parseDouble(d[FirestoreUserCoinMiningFields.totalPoints]);
    final end = _parseTimestamp(d[FirestoreUserCoinMiningFields.lastMiningEnd]);
    final rate = _parseDouble(d[FirestoreUserCoinMiningFields.hourlyRate]);
    final synced = _parseTimestamp(
      d[FirestoreUserCoinMiningFields.lastSyncedAt],
    );
    final start = _parseTimestamp(
      d[FirestoreUserCoinMiningFields.lastMiningStart],
    );

    // Check if active based on end time
    final now = DateTime.now();
    final active = end != null && now.isBefore(end.toDate());

    _rate = rate;
    _end = end;
    _start = synced ?? start;
    _totalBase = total;

    // Calculate correct display value immediately to avoid UI reset/jump
    if (_start != null && _end != null) {
      final s = _start!.toDate();
      final e = _end!.toDate();
      final totalSessionSec = e.difference(s).inSeconds.toDouble();

      if (active) {
        // Currently mining: Base + Elapsed
        final elapsedSec = now.difference(s).inSeconds.toDouble();
        final inc = (elapsedSec * (_rate / 3600.0)).clamp(
          0.0,
          totalSessionSec * (_rate / 3600.0),
        );
        _display = _totalBase + inc;
      } else {
        // Finished mining (waiting for next session start to sync chunk): Base + Full Session
        // But only if we have a valid past session recorded
        // If the session is very old, we still show it as "unsynced earnings" until they start a new one?
        // Yes, because DB totalPoints is not updated yet.
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

    // Only update timer state if needed to avoid build side-effects issues
    if (active) {
      if (_timer == null) {
        _startTimer();
      }
    } else {
      if (_timer != null) {
        _timer?.cancel();
        _timer = null;
      }
    }
  }

  Widget _buildUI() {
    final active = _timer != null; // or use _end check
    const activeGreen = Color(0xFF2ECC71);
    const buttonBlue = Color(0xFF1677FF);
    final remaining = _formatRemaining(_end);
    final statusColor = active ? activeGreen : Colors.white38;

    if (widget.variant == CoinMiningControlsVariant.myCoinCard) {
      String fmtRate(double v) {
        final str = v.toStringAsFixed(3);
        return str.replaceFirst(RegExp(r'\.?0+$'), '');
      }

      String fmtDisplay(double v) {
        final str = v.toStringAsFixed(2);
        return str.replaceFirst(RegExp(r'\.?0+$'), '');
      }

      final sym = (widget.symbol ?? '').trim();
      final rate = widget.baseRate ?? _rate;
      final baseSuffix = sym.isEmpty ? '—/hr' : '$sym/hr';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mined Coins',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtDisplay(_display),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            sym.isEmpty ? '—' : sym,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 44, color: Colors.white12),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Base Rate',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtRate(rate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            baseSuffix,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: active
                  ? null
                  : () async {
                      try {
                        final devId = await DeviceId.get();
                        await CoinService.startCoinMining(
                          widget.coinOwnerId,
                          deviceId: devId,
                        );
                        if (mounted) setState(() {});
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Start failed: $e')),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonBlue,
                disabledBackgroundColor: buttonBlue.withValues(alpha: 0.35),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_settings_new_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    active ? 'Mining' : 'Mine',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            active ? 'Mining… • $remaining' : 'Inactive',
            style: TextStyle(
              color: statusColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (widget.variant == CoinMiningControlsVariant.detailed) {
      const surface = Color(0xFF17222C);
      const border = Color(0xFF24303B);

      String formatClock(Timestamp? end) {
        if (end == null) return '00 : 00 : 00';
        final now = DateTime.now();
        final e = end.toDate();
        Duration rem = e.difference(now);
        if (rem.isNegative) rem = Duration.zero;
        final h = rem.inHours;
        final m = rem.inMinutes % 60;
        final s = rem.inSeconds % 60;
        String p2(int v) => v.toString().padLeft(2, '0');
        return '${p2(h)} : ${p2(m)} : ${p2(s)}';
      }

      double sessionProgress() {
        final end = _end?.toDate();
        final start = _start?.toDate();
        if (end == null || start == null) return 0.0;
        final total = end.difference(start).inSeconds.toDouble();
        if (total <= 0) return 0.0;
        final elapsed = DateTime.now().difference(start).inSeconds.toDouble();
        return (elapsed / total).clamp(0.0, 1.0);
      }

      final p = active ? sessionProgress() : 0.0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Session Progress',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                formatClock(_end),
                style: TextStyle(
                  color: buttonBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'remaining',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: p,
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            buttonBlue.withValues(alpha: 0.85),
                            buttonBlue,
                          ],
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.02),
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                            stops: const [0.0, 0.25, 0.5, 0.75],
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: active
                        ? null
                        : () async {
                            try {
                              final devId = await DeviceId.get();
                              await CoinService.startCoinMining(
                                widget.coinOwnerId,
                                deviceId: devId,
                              );
                              if (mounted) setState(() {});
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Start failed: $e')),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: surface,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: surface.withValues(alpha: 0.65),
                      disabledForegroundColor: Colors.white.withValues(
                        alpha: 0.55,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: border),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 20,
                          color: active ? Colors.white38 : Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Boost Rate',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: active ? Colors.white38 : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 56,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: surface,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: border),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Icon(Icons.settings_rounded, size: 26),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            active ? 'Mining… • $remaining' : 'Inactive',
            style: TextStyle(
              color: statusColor,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mined',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _display.toStringAsFixed(3),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                active ? 'Mining… • $remaining' : 'Inactive',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 34,
          child: ElevatedButton(
            onPressed: active
                ? null
                : () async {
                    try {
                      final devId = await DeviceId.get();
                      final result = await CoinService.startCoinMining(
                        widget.coinOwnerId,
                        deviceId: devId,
                      );
                      if (mounted) {
                        if (result.isNotEmpty) {
                          setState(() {
                            _localOverrideData = result;
                          });
                        } else {
                          setState(() {});
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Start failed: $e')),
                        );
                      }
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBlue,
              disabledBackgroundColor: buttonBlue.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
              minimumSize: const Size(64, 34),
            ),
            child: Text(
              active ? 'Mining' : 'Mine',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  void _startTimer() {
    _timer?.cancel();
    // _display is already set correctly in _processData, do NOT reset it here.
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      final end = _end?.toDate();
      final start = _start?.toDate();
      if (end == null || start == null) return;
      final now = DateTime.now();
      if (!now.isBefore(end)) {
        _timer?.cancel();
        _timer = null; // Ensure null is set
        // Ensure final value is set correctly when timer ends naturally
        final totalSessionSec = end.difference(start).inSeconds.toDouble();
        final fullEarned = totalSessionSec * (_rate / 3600.0);
        _display = _totalBase + fullEarned;

        // Trigger sync to ensure points are added to DB at the exact end time
        try {
          await CoinService.syncCoinEarnings(
            coinOwnerId: widget.coinOwnerId,
            amount: fullEarned,
            lastSyncedAt: end,
          );
        } catch (e) {
          debugPrint('Auto-sync error: $e');
        }

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

      // Only rebuild if the displayed value (3 decimal places) actually changes
      if (mounted &&
          (_display.toStringAsFixed(3) != oldDisplay.toStringAsFixed(3))) {
        setState(() {});
      }
    });
  }

  String _formatRemaining(Timestamp? end) {
    if (end == null) return '';
    final now = DateTime.now();
    final e = end.toDate();
    Duration rem = e.difference(now);
    if (rem.isNegative) rem = Duration.zero;
    final h = rem.inHours;
    final m = rem.inMinutes % 60;
    return '${h}h ${m}m remaining';
  }
}
