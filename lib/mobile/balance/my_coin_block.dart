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

class MyCoinBlock extends StatelessWidget {
  const MyCoinBlock({super.key});

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
  const _NoCoinCard({required this.onCreate});
  @override
  Widget build(BuildContext context) {
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
  const _CoinCard({required this.data, required this.onEdit});
  @override
  Widget build(BuildContext context) {
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create your coin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'This coin will be visible in the network and can be mined by other users. These are app points, not a real cryptocurrency.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: _thumbBytes != null
                        ? MemoryImage(_thumbBytes!)
                        : (_initialImageUrl != null &&
                              _initialImageUrl!.isNotEmpty)
                        ? NetworkImage(_initialImageUrl!)
                        : null,
                    child:
                        (_thumbBytes == null &&
                            (_initialImageUrl == null ||
                                _initialImageUrl!.isEmpty))
                        ? const Icon(Icons.token)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  if (_allowImageUpload)
                    ElevatedButton(
                      onPressed: _submitting ? null : _pickImage,
                      child: const Text('Upload image'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Coin name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: symbolCtrl,
                decoration: const InputDecoration(
                  labelText: 'Symbol (optional)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Description',
                  helperText: '${descCtrl.text.length}/$_maxDesc',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: rateCtrl,
                      decoration: InputDecoration(
                        labelText: 'Mining rate (coins/hour)',
                        helperText: 'Allowed range: $_minRate – $_maxRate',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Social & project links (optional)'),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      if (_rows.length >= _maxLinks) return;
                      setState(() => _rows.add(_LinkRow()));
                    },
                    icon: const Icon(Icons.add_link),
                  ),
                ],
              ),
              Column(
                children: [
                  for (int i = 0; i < _rows.length; i++)
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _rows[i].type,
                          onChanged: (v) =>
                              setState(() => _rows[i].type = v ?? 'website'),
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
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _rows[i].urlCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Paste URL',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _rows.removeAt(i)),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Your coin is an in-app points system only. It is not a cryptocurrency, cannot be traded for money, and we do not guarantee any financial value.',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: Text(_isEditing ? 'Save' : 'Create Coin'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mined: ${_display.toStringAsFixed(3)}'),
              Text(active ? 'Active • $remaining' : 'Inactive'),
            ],
          ),
        ),
        ElevatedButton(
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
          child: const Text('Start Mining'),
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
