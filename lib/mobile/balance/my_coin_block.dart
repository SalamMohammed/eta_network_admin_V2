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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: CoinService.watchUserCoin(uid),
      builder: (ctx, snap) {
        final data = snap.data?.data();
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
    const g1 = Color(0xFF5A46FF);
    const g2 = Color(0xFF8A2BFF);
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final rate =
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / 360).clamp(0.7, 1.0);
        double s(double v) => v * scale;
        return GestureDetector(
          onTap: onEdit,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(s(22)),
            child: Container(
              height: s(110),
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
                    padding: EdgeInsets.all(s(14)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: s(20),
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: s(6)),
                              Text(
                                'Base rate: ${rate.toStringAsFixed(3)}/h${symbol.isNotEmpty ? ' • $symbol' : ''}',
                                style: TextStyle(
                                  fontSize: s(14),
                                  color: Colors.white70,
                                  height: 1.2,
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
                            Icons.edit_rounded,
                            size: s(26),
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
    final name = (data[FirestoreUserCoinFields.name] as String?) ?? '—';
    final symbol = (data[FirestoreUserCoinFields.symbol] as String?) ?? '';
    final rate =
        (data[FirestoreUserCoinFields.baseRatePerHour] as num?)?.toDouble() ??
        0.0;
    final img = (data[FirestoreUserCoinFields.imageUrl] as String?) ?? '';
    final links =
        (data[FirestoreUserCoinFields.socialLinks] as List<dynamic>?) ??
        const [];
    return Container(
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
              ElevatedButton(onPressed: onEdit, child: const Text('Edit coin')),
            ],
          ),
          const SizedBox(height: 8),
          // Text(desc.length > 160 ? '${desc.substring(0, 160)}…' : desc),
          // const SizedBox(height: 8),
          Text('Base rate: ${rate.toStringAsFixed(3)} coins/hour'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in links)
                _LinkButton(
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
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String type;
  final String url;
  const _LinkButton({required this.type, required this.url});

  @override
  Widget build(BuildContext context) {
    // If you have uploaded assets, use Image.asset
    // For now we keep using Icons until you upload them.
    // Once uploaded to assets/social_icons/facebook.png, etc:
    //
    // String? assetName;
    // switch (type.toLowerCase()) {
    //   case 'facebook': assetName = 'assets/social_icons/facebook.png'; break;
    //   // ...
    // }
    // if (assetName != null) return IconButton(icon: Image.asset(assetName), ...);

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
        // X logo is unique, using a close match or custom if available
        // For standard icons, we can use close or alternate_email
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

    return IconButton(
      icon: Icon(icon, color: color),
      tooltip: type,
      onPressed: () async {
        if (url.isEmpty) return;
        var uri = Uri.tryParse(url);
        if (uri == null) return;
        if (!uri.hasScheme) {
          uri = Uri.tryParse('https://$url');
        }
        debugPrint('LinkButton: Trying to launch $uri');
        try {
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            // fallback if parsed but canLaunchUrl returns false (some devices need this)
            debugPrint(
              'LinkButton: canLaunchUrl returned false, trying force launch',
            );
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        } catch (e) {
          debugPrint('LinkButton: Launch error: $e');
        }
      },
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
                        helperText: 'Allowed range: $_minRate – $_maxRate',
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
                                  'This is an in-app digital coin used only within the ETA Network ecosystem. It is not a cryptocurrency, has no monetary value, and cannot be traded, exchanged, or redeemed for money. Any potential future use, integration, or evolution of ETA Network features will depend on platform policies, legal requirements, and community-driven decisions. No guarantees are made regarding future value or external usage.',
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: s(50),
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: buttonBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: buttonBlue.withValues(
                                alpha: 0.35,
                              ),
                              disabledForegroundColor: Colors.white.withValues(
                                alpha: 0.8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
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
                        SizedBox(height: s(8)),
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.white60,
                                fontWeight: FontWeight.w800,
                                fontSize: s(13.5),
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

  Future<void> _submit() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // validation
    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final rate = double.tryParse(rateCtrl.text.trim());
    if (name.length < 3 || name.length > 30) {
      return;
    }
    if (desc.length > _maxDesc) {
      return;
    }
    if (rate == null || rate < _minRate || rate > _maxRate) {
      return;
    }
    final links = <Map<String, dynamic>>[];
    for (final r in _rows) {
      final u = r.urlCtrl.text.trim();
      if (u.isEmpty) continue;
      if (!_validUrl(u)) {
        return;
      }
      links.add({'type': r.type, 'iconName': r.type, 'url': u});
    }

    setState(() => _submitting = true);
    debugPrint(
      '[CreateCoinDialog] Submit start | isEditing=$_isEditing | name=$name | symbol=${symbolCtrl.text.trim()} | hasThumb=${_thumbBytes != null} | initialImageSet=${_initialImageUrl != null && _initialImageUrl!.isNotEmpty}',
    );

    final now = FieldValue.serverTimestamp();
    final Map<String, dynamic> coinDoc = {
      FirestoreUserCoinFields.ownerId: uid,
      FirestoreUserCoinFields.name: name,
      FirestoreUserCoinFields.symbol: symbolCtrl.text.trim(),
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
    await CoinService.createOrUpdateUserCoin(
      uid: uid,
      coin: coinDoc,
      merge: _isEditing,
      thumbnailBytes: _thumbBytes,
      thumbnailContentType: _thumbContentType,
    );
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
  const CoinMiningControls({
    super.key,
    required this.coinOwnerId,
    this.miningData,
  });
  @override
  State<CoinMiningControls> createState() => _CoinMiningControlsState();
}

class _CoinMiningControlsState extends State<CoinMiningControls> {
  Timer? _timer;
  double _display = 0.0;
  Timestamp? _end;
  double _rate = 0.0;
  Timestamp? _start;
  double _totalBase = 0.0;
  DateTime? _lastSync;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.miningData != null) {
      _processData(widget.miningData!);
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

  void _processData(Map<String, dynamic> d) {
    final total =
        (d[FirestoreUserCoinMiningFields.totalPoints] as num?)?.toDouble() ??
        0.0;
    final end = d[FirestoreUserCoinMiningFields.lastMiningEnd] as Timestamp?;
    final rate =
        (d[FirestoreUserCoinMiningFields.hourlyRate] as num?)?.toDouble() ??
        0.0;
    final synced = d[FirestoreUserCoinMiningFields.lastSyncedAt] as Timestamp?;
    final start =
        d[FirestoreUserCoinMiningFields.lastMiningStart] as Timestamp?;
    final active = end != null && DateTime.now().isBefore(end.toDate());
    _rate = rate;
    _end = end;
    _start = synced ?? start;
    _totalBase = total;

    // Only update timer state if needed to avoid build side-effects issues
    if (active) {
      if (_timer == null) {
        _startTimer(base: total);
      }
    } else {
      if (_timer != null) {
        _timer?.cancel();
        _timer = null;
        // Update display to final total when stopping
        _display = total;
      } else {
        // If no timer and inactive, ensure display is correct
        _display = total;
      }
    }
  }

  Widget _buildUI() {
    final active = _timer != null; // or use _end check
    final remaining = _formatRemaining(_end);
    const activeGreen = Color(0xFF2ECC71);
    const buttonBlue = Color(0xFF1677FF);
    final statusColor = active ? activeGreen : Colors.white38;
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

  void _startTimer({required double base}) {
    _timer?.cancel();
    _display = base;
    _timer = Timer.periodic(const Duration(milliseconds: 1000), (_) async {
      final end = _end?.toDate();
      final start = _start?.toDate();
      if (end == null || start == null) return;
      final now = DateTime.now();
      if (!now.isBefore(end)) {
        _timer?.cancel();
        _timer = null; // Ensure null is set
        await CoinService.syncCoinEarnings(widget.coinOwnerId);
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

      if (_lastSync == null || now.difference(_lastSync!).inSeconds >= 60) {
        _lastSync = now;
        await CoinService.syncCoinEarnings(widget.coinOwnerId);
      }

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
