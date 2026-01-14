import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/theme/colors.dart';
import '../../services/notification_service.dart';
import '../app.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _ctrl = PageController();
  int _index = 0;
  bool _requestingNotifPermission = false;
  NotificationSettings? _notifSettings;
  bool _disclaimerAccepted = false;

  static const _slides = <_OnboardingSlide>[
    _OnboardingSlide(
      headerTitle: 'How it Works',
      titleA: 'Check-in',
      titleB: 'Daily',
      body:
          'Spend just seconds a day to activate your session. Consistency is key to maximizing your ETA points.',
      ctaText: 'Continue',
      showArrow: false,
      tagLabel: null,
      tagIcon: null,
      illustrationIcon: Icons.bolt_rounded,
      illustrationAsset: 'android/app/src/images/New Images/Check in daily.png',
      illustrationNetworkUrl: null,
    ),
    _OnboardingSlide(
      headerTitle: null,
      titleA: 'Secure Your',
      titleB: 'Position',
      body:
          'Timing is key in the ETA ecosystem. Early adopters unlock higher mining rates and pivotal community roles.',
      ctaText: 'Continue',
      showArrow: true,
      tagLabel: null,
      tagIcon: null,
      illustrationIcon: Icons.verified_rounded,
      illustrationAsset:
          'android/app/src/images/New Images/Secure your Position.png',
      illustrationNetworkUrl: null,
      illustrationDesign: null,
    ),
    _OnboardingSlide(
      headerTitle: null,
      titleA: 'Effortless',
      titleB: 'Auto Mining',
      body:
          'Set it and forget it. Automatically mine ETA and your favorite Community coins with maximum efficiency around the clock.',
      ctaText: 'Continue',
      showArrow: true,
      tagLabel: null,
      tagIcon: null,
      illustrationIcon: Icons.auto_awesome_rounded,
      illustrationAsset:
          'android/app/src/images/New Images/Effortless Auto Mining.png',
      illustrationNetworkUrl: null,
      illustrationDesign: null,
    ),
    _OnboardingSlide(
      headerTitle: null,
      titleA: 'Your Coin',
      titleB: 'Journey',
      body:
          'Create, mine, and share your own community coins. Watch your ideas evolve into something massive.',
      ctaText: 'Continue',
      showArrow: true,
      tagLabel: null,
      tagIcon: null,
      illustrationIcon: Icons.route_rounded,
      illustrationAsset:
          'android/app/src/images/New Images/Your Coin journey.png',
      illustrationNetworkUrl: null,
      illustrationDesign: null,
    ),
    _OnboardingSlide(
      headerTitle: null,
      titleA: 'Mine',
      titleB: 'Community Coins',
      body:
          'Support projects created by fellow members. Your mining power directly contributes to their success and network stability.',
      ctaText: 'Continue',
      showArrow: true,
      tagLabel: null,
      tagIcon: null,
      illustrationIcon: Icons.diamond_rounded,
      illustrationAsset:
          'android/app/src/images/New Images/Mine community coins.png',
      illustrationNetworkUrl: null,
      illustrationDesign: null,
    ),
  ];

  int get _pageCount => _slides.length + 2;
  int get _notificationsIndex => _slides.length;
  int get _disclaimerIndex => _slides.length + 1;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final base = (w < h ? w : h);
    final tScale = (base / 390.0).clamp(0.85, 1.15);
    double s(double v) => v * tScale;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepLayer, AppColors.primaryBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: s(18),
                  vertical: s(6),
                ),
                child: _OnboardingHeader(
                  index: _index,
                  count: _pageCount,
                  scale: s,
                  showSkip: _index != _disclaimerIndex,
                  title: _index == _disclaimerIndex
                      ? 'Step ${_disclaimerIndex + 1} of $_pageCount'
                      : null,
                  onBack: () async {
                    if (_index > 0) {
                      await _ctrl.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      );
                    } else {
                      if (mounted) Navigator.of(context).maybePop();
                    }
                  },
                  onSkip: _completeOnboarding,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _pageCount,
                  itemBuilder: (context, i) {
                    if (i < _slides.length) {
                      final slide = _slides[i];
                      return _SlideView(
                        slide: slide,
                        scale: s,
                        onContinue: _onContinue,
                      );
                    }
                    if (i == _notificationsIndex) {
                      return _NotificationsOnboardingPage(
                        scale: s,
                        requesting: _requestingNotifPermission,
                        settings: _notifSettings,
                        onEnable: _requestNotifications,
                        onMaybeLater: _onContinue,
                      );
                    }
                    return _DisclaimerOnboardingPage(
                      scale: s,
                      accepted: _disclaimerAccepted,
                      onAcceptedChanged: (v) {
                        setState(() => _disclaimerAccepted = v);
                      },
                      onSwipeCompleted: () async {
                        if (!_disclaimerAccepted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Please acknowledge the disclaimer to continue.',
                              ),
                            ),
                          );
                          return;
                        }
                        await _completeOnboarding();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_index < _pageCount - 1) {
      await _ctrl.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
      return;
    }
    await _completeOnboarding();
  }

  Future<void> _requestNotifications() async {
    if (_requestingNotifPermission) return;
    setState(() => _requestingNotifPermission = true);
    try {
      final settings = await NotificationService().requestPermissions();
      if (!mounted) return;
      setState(() => _notifSettings = settings);
      if (_index == _notificationsIndex) {
        await _onContinue();
      }
    } finally {
      if (mounted) setState(() => _requestingNotifPermission = false);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('eta_onboarding_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MobileAppScaffold()),
    );
  }
}

class _OnboardingSlide {
  final String? headerTitle;
  final String titleA;
  final String titleB;
  final String body;
  final String ctaText;
  final bool showArrow;
  final String? tagLabel;
  final IconData? tagIcon;
  final IconData illustrationIcon;
  final String? illustrationAsset;
  final String? illustrationNetworkUrl;
  final _OnboardingIllustration? illustrationDesign;

  const _OnboardingSlide({
    required this.headerTitle,
    required this.titleA,
    required this.titleB,
    required this.body,
    required this.ctaText,
    required this.showArrow,
    required this.tagLabel,
    required this.tagIcon,
    required this.illustrationIcon,
    required this.illustrationAsset,
    required this.illustrationNetworkUrl,
    this.illustrationDesign,
  });
}

class _OnboardingHeader extends StatelessWidget {
  final int index;
  final int count;
  final double Function(double v) scale;
  final bool showSkip;
  final String? title;
  final VoidCallback onSkip;
  final VoidCallback onBack;

  const _OnboardingHeader({
    required this.index,
    required this.count,
    required this.scale,
    required this.showSkip,
    required this.title,
    required this.onSkip,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final onLast = index == count - 1;
    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: onBack,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: scale(40),
                height: scale(40),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: scale(18),
                  color: Colors.white70,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: title == null
                    ? const SizedBox.shrink()
                    : Text(
                        title!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: scale(15.5),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            if (showSkip)
              InkWell(
                onTap: onSkip,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: scale(8),
                    vertical: scale(8),
                  ),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: scale(13.5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              SizedBox(width: scale(40)),
          ],
        ),
        SizedBox(height: scale(10)),
        if (onLast)
          _DotsProgress(count: count, index: index, scale: scale)
        else
          _ProgressPills(count: count, index: index),
      ],
    );
  }
}

class _DotsProgress extends StatelessWidget {
  final int count;
  final int index;
  final double Function(double v) scale;
  const _DotsProgress({
    required this.count,
    required this.index,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: active ? scale(22) : scale(7),
          height: scale(7),
          margin: EdgeInsets.symmetric(horizontal: scale(4)),
          decoration: BoxDecoration(
            color: active ? blue : Colors.white12,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _ProgressPills extends StatelessWidget {
  final int count;
  final int index;
  const _ProgressPills({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(count, (i) {
        final active = i <= index;
        return Container(
          width: 28,
          height: 4,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1B4BFF) : Colors.white12,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _SlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final double Function(double v) scale;
  final Future<void> Function() onContinue;
  const _SlideView({
    required this.slide,
    required this.scale,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final asset = (slide.illustrationAsset ?? '').trim();
    final networkUrl = (slide.illustrationNetworkUrl ?? '').trim();
    final hasNetworkUrl = networkUrl.isNotEmpty;
    final hasAsset = asset.isNotEmpty;
    final design = slide.illustrationDesign;
    final screenH = MediaQuery.of(context).size.height;
    final imgH = (screenH * 0.28).clamp(scale(200), scale(260));
    final fallback = Center(
      child: Container(
        width: scale(76),
        height: scale(76),
        decoration: BoxDecoration(
          color: blue.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(scale(18)),
          boxShadow: [
            BoxShadow(
              color: blue.withValues(alpha: 0.25),
              blurRadius: scale(30),
              offset: Offset(0, scale(14)),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          slide.illustrationIcon,
          size: scale(36),
          color: Colors.white,
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale(22)),
      child: Column(
        children: [
          if (slide.headerTitle != null) ...[
            SizedBox(height: scale(6)),
            Text(
              slide.headerTitle!,
              style: TextStyle(
                color: Colors.white,
                fontSize: scale(16),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          SizedBox(height: scale(slide.headerTitle == null ? 26 : 18)),
          Container(
            height: imgH,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(scale(26)),
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasNetworkUrl)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(scale(26)),
                    child: _HtmlImageCard(
                      imageUrl: networkUrl,
                      icon: slide.illustrationIcon,
                      scale: scale,
                    ),
                  )
                else if (design != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(scale(26)),
                    child: _OnboardingIllustrationView(
                      illustration: design,
                      scale: scale,
                    ),
                  )
                else if (hasAsset)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(scale(26)),
                    child: Image.asset(
                      asset,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stack) {
                        return _OnboardingIllustrationView(
                          illustration: _illustrationForSlide(slide),
                          scale: scale,
                        );
                      },
                    ),
                  )
                else ...[
                  Positioned(
                    top: scale(26),
                    right: scale(22),
                    child: Container(
                      width: scale(92),
                      height: scale(92),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  Positioned(
                    left: scale(22),
                    bottom: scale(28),
                    child: Container(
                      width: scale(74),
                      height: scale(74),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                  fallback,
                ],
              ],
            ),
          ),
          SizedBox(height: scale(22)),
          if (slide.tagLabel != null && slide.tagIcon != null)
            _TagPill(
              scale: scale,
              label: slide.tagLabel!,
              icon: slide.tagIcon!,
            ),
          if (slide.tagLabel != null && slide.tagIcon != null)
            SizedBox(height: scale(22)),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: scale(32),
                fontWeight: FontWeight.w900,
                height: 1.08,
              ),
              children: [
                TextSpan(text: '${slide.titleA}\n'),
                TextSpan(
                  text: slide.titleB,
                  style: TextStyle(color: blue),
                ),
              ],
            ),
          ),
          SizedBox(height: scale(14)),
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: scale(14.5),
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: scale(56),
            child: ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(scale(14)),
                ),
                textStyle: TextStyle(
                  fontSize: scale(16),
                  fontWeight: FontWeight.w900,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(slide.ctaText),
                  if (slide.showArrow) ...[
                    SizedBox(width: scale(10)),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: scale(18),
                      color: Colors.white,
                    ),
                  ],
                ],
              ),
            ),
          ),
          SizedBox(height: scale(18)),
        ],
      ),
    );
  }
}

class _HtmlImageCard extends StatelessWidget {
  final String imageUrl;
  final IconData icon;
  final double Function(double v) scale;
  const _HtmlImageCard({
    required this.imageUrl,
    required this.icon,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final bg1 = const Color(0xFF1A2633);
    final bg2 = const Color(0xFF101922);
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg1, bg2],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            color: Colors.white.withValues(alpha: 0.22),
            colorBlendMode: BlendMode.overlay,
            errorBuilder: (context, error, stack) {
              return Center(
                child: Icon(
                  icon,
                  size: scale(56),
                  color: blue.withValues(alpha: 0.92),
                ),
              );
            },
          ),
        ),
        Center(
          child: Transform.scale(
            scale: 1.5,
            child: Icon(
              icon,
              size: scale(46),
              color: blue,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: scale(18),
                  offset: Offset(0, scale(8)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _IllustrationStayInLoop extends StatefulWidget {
  final double Function(double v) scale;
  const _IllustrationStayInLoop({required this.scale});

  @override
  State<_IllustrationStayInLoop> createState() =>
      _IllustrationStayInLoopState();
}

class _IllustrationStayInLoopState extends State<_IllustrationStayInLoop>
    with SingleTickerProviderStateMixin {
  static const _imgUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBlCweTwYwElGuuH8-EB_JYagzr9m8SIc3ywziKYihccPmpherjMqusR1XVxY0XJKCOkBvuadN-yyNwDJD2c1mikIxikOWy_E6BsacPRemd_KgzTTuB7YjjZaiTQVduxyiKOrVFXS9DTLpL_adiOdgo_dvZaGGpfvlq3KwQ0ARYgN_rqItsem2bZO1ib2c7CjqHwMGKyPfg_aDCFS9OosM4G8pCtH_W1pQHimwYDSC98J2opZJHipXMyEBPHPtJeSepLdNiLOA_Wn8';

  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF137FEC);
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final base = math.min(w, h);
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF0F172A), const Color(0xFF0B1220)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  spacing: widget.scale(24),
                  dotRadius: widget.scale(1.1),
                  color: blue.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      blue.withValues(alpha: 0.10),
                      const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = 0.5 - 0.5 * math.cos(_pulse.value * math.pi * 2);
                final size = base * (0.62 + 0.05 * t);
                return Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blue.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.40),
                          blurRadius: widget.scale(80),
                          spreadRadius: widget.scale(6),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(widget.scale(18)),
                child: Image.network(
                  _imgUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) {
                    return Center(
                      child: Icon(
                        Icons.notifications_active_rounded,
                        size: widget.scale(64),
                        color: Colors.white54,
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: h * 0.16,
              right: w * 0.12,
              child: Transform.rotate(
                angle: 0.22,
                child: Container(
                  width: widget.scale(56),
                  height: widget.scale(56),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(widget.scale(16)),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: widget.scale(20),
                        offset: Offset(0, widget.scale(10)),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.notifications_active_rounded,
                    size: widget.scale(32),
                    color: blue,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

_OnboardingIllustration _illustrationForSlide(_OnboardingSlide slide) {
  final asset = (slide.illustrationAsset ?? '').toLowerCase();
  if (asset.contains('auto manager')) return _OnboardingIllustration.autoCard;
  if (asset.contains('create & share')) return _OnboardingIllustration.coinPath;
  if (asset.contains('check-in')) return _OnboardingIllustration.checkCard;
  return _OnboardingIllustration.diamondNetwork;
}

class _NotificationsOnboardingPage extends StatelessWidget {
  final double Function(double v) scale;
  final bool requesting;
  final NotificationSettings? settings;
  final Future<void> Function() onEnable;
  final Future<void> Function() onMaybeLater;

  const _NotificationsOnboardingPage({
    required this.scale,
    required this.requesting,
    required this.settings,
    required this.onEnable,
    required this.onMaybeLater,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final auth = settings?.authorizationStatus;
    final enabled =
        auth == AuthorizationStatus.authorized ||
        auth == AuthorizationStatus.provisional;
    final denied = auth == AuthorizationStatus.denied;
    final badgeText = enabled
        ? 'ON'
        : (denied ? 'OFF' : (auth == null ? 'PENDING' : 'PENDING'));
    final badgeColor = enabled
        ? const Color(0xFF2ECC71)
        : (denied ? const Color(0xFFFF6B6B) : const Color(0xFFFFB020));
    final iconColor = enabled
        ? const Color(0xFF2ECC71)
        : (denied ? const Color(0xFFFF6B6B) : const Color(0xFFFFB020));
    final screenH = MediaQuery.of(context).size.height;
    final imgH = (screenH * 0.28).clamp(scale(190), scale(260));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale(22)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: scale(26)),
            Container(
              height: imgH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(scale(26)),
                color: Colors.white.withValues(alpha: 0.03),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(scale(26)),
                child: Image.asset(
                  'android/app/src/images/New Images/Stay in the loop.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stack) {
                    return _IllustrationStayInLoop(scale: scale);
                  },
                ),
              ),
            ),
            SizedBox(height: scale(22)),
            Text(
              'Stay in the Loop',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: scale(34),
                fontWeight: FontWeight.w900,
                height: 1.06,
              ),
            ),
            SizedBox(height: scale(10)),
            Text(
              "Don't miss critical mining updates. Get\nnotified when your session ends to\nmaximize your ETA points.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: scale(14.5),
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
            SizedBox(height: scale(18)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: scale(14),
                vertical: scale(12),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(scale(16)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Row(
                children: [
                  Container(
                    width: scale(40),
                    height: scale(40),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: scale(20),
                      color: iconColor,
                    ),
                  ),
                  SizedBox(width: scale(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Push Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: scale(14.5),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: scale(2)),
                        Text(
                          enabled
                              ? 'On'
                              : (denied
                                    ? 'Permission denied'
                                    : 'Permission required'),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: scale(12.5),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale(12),
                      vertical: scale(7),
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: badgeColor.withValues(alpha: 0.40),
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: scale(12),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: scale(24)),
            SizedBox(
              width: double.infinity,
              height: scale(56),
              child: ElevatedButton.icon(
                onPressed: requesting
                    ? null
                    : () async {
                        if (enabled) {
                          await onMaybeLater();
                        } else {
                          await onEnable();
                        }
                      },
                icon: Icon(
                  enabled ? Icons.check_rounded : Icons.notifications_rounded,
                  size: scale(20),
                  color: Colors.white,
                ),
                label: Text(enabled ? 'Continue' : 'Enable Notifications'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(scale(14)),
                  ),
                  textStyle: TextStyle(
                    fontSize: scale(16),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            SizedBox(height: scale(14)),
            TextButton(
              onPressed: requesting ? null : () async => onMaybeLater(),
              style: TextButton.styleFrom(foregroundColor: Colors.white60),
              child: Text(
                'Maybe Later',
                style: TextStyle(
                  fontSize: scale(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: scale(18)),
          ],
        ),
      ),
    );
  }
}

class _DisclaimerOnboardingPage extends StatelessWidget {
  final double Function(double v) scale;
  final bool accepted;
  final ValueChanged<bool> onAcceptedChanged;
  final Future<void> Function() onSwipeCompleted;

  const _DisclaimerOnboardingPage({
    required this.scale,
    required this.accepted,
    required this.onAcceptedChanged,
    required this.onSwipeCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final screenH = MediaQuery.of(context).size.height;
    final imgH = (screenH * 0.22).clamp(scale(120), scale(180));
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scale(22)),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: scale(18)),
            Center(
              child: Container(
                width: scale(240),
                height: imgH,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(scale(20)),
                  color: Colors.white.withValues(alpha: 0.03),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(scale(20)),
                  child: Image.asset(
                    'android/app/src/images/Important Disclaimer.png',
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stack) {
                      return Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: scale(52),
                          color: Colors.white54,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: scale(18)),
            Text(
              'Important Disclaimer',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: scale(30),
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            SizedBox(height: scale(8)),
            Text(
              'Please read the terms below carefully',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white54,
                fontSize: scale(14.5),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: scale(16)),
            Container(
              padding: EdgeInsets.all(scale(16)),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(scale(18)),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Text(
                'ETA points and community coins are part of the ETA Network ecosystem and are used to measure participation, activity, and contribution within the app.\n\nETA Network is currently in an early growth phase. As the ecosystem evolves, new features, utilities, and integrations may be introduced based on community activity, platform development, and regulatory considerations.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: scale(13.5),
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
            ),
            SizedBox(height: scale(16)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.scale(
                  scale: 1.05,
                  child: Checkbox(
                    value: accepted,
                    onChanged: (v) => onAcceptedChanged(v ?? false),
                    activeColor: blue,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: scale(10)),
                    child: Text(
                      'I acknowledge that I have read and agree to the terms above.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: scale(13.5),
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: scale(22)),
            _SwipeToContinue(
              scale: scale,
              enabled: accepted,
              onCompleted: onSwipeCompleted,
            ),
            SizedBox(height: scale(18)),
          ],
        ),
      ),
    );
  }
}

class _SwipeToContinue extends StatefulWidget {
  final double Function(double v) scale;
  final bool enabled;
  final Future<void> Function() onCompleted;

  const _SwipeToContinue({
    required this.scale,
    required this.enabled,
    required this.onCompleted,
  });

  @override
  State<_SwipeToContinue> createState() => _SwipeToContinueState();
}

class _SwipeToContinueState extends State<_SwipeToContinue>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _value = 0.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _anim = Tween<double>(begin: 0.0, end: 0.0).animate(_ctrl);
    _ctrl.addListener(() {
      setState(() => _value = _anim.value);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_SwipeToContinue old) {
    super.didUpdateWidget(old);
    if (!widget.enabled && _value > 0) {
      setState(() => _value = 0.0);
    }
  }

  void _onDragUpdate(DragUpdateDetails d, double maxX) {
    if (!widget.enabled || maxX <= 0) return;
    // Stop any snap-back animation if user grabs it again
    if (_ctrl.isAnimating) _ctrl.stop();
    setState(() {
      _value = (_value + (d.delta.dx / maxX)).clamp(0.0, 1.0);
    });
  }

  void _onDragEnd() {
    if (!widget.enabled) return;
    if (_value >= 0.92) {
      widget.onCompleted();
    } else {
      // Snap back smoothly
      _anim = Tween<double>(
        begin: _value,
        end: 0.0,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl.reset();
      _ctrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return LayoutBuilder(
      builder: (context, c) {
        final h = widget.scale(56);
        final knob = widget.scale(46);
        final maxX = (c.maxWidth - knob - widget.scale(6)).clamp(0.0, 99999.0);
        final x = (_value.clamp(0.0, 1.0) * maxX);
        return GestureDetector(
          onHorizontalDragUpdate: (d) => _onDragUpdate(d, maxX),
          onHorizontalDragEnd: (_) => _onDragEnd(),
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Swipe to Continue',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: widget.scale(14.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Positioned(
                  left: widget.scale(3) + x,
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      color: widget.enabled ? blue : Colors.white12,
                      shape: BoxShape.circle,
                      boxShadow: widget.enabled
                          ? [
                              BoxShadow(
                                color: blue.withValues(alpha: 0.35),
                                blurRadius: widget.scale(18),
                                offset: Offset(0, widget.scale(10)),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: widget.scale(20),
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
}

class _TagPill extends StatelessWidget {
  final double Function(double v) scale;
  final String label;
  final IconData icon;
  const _TagPill({
    required this.scale,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: scale(14),
          vertical: scale(8),
        ),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: scale(16), color: blue),
            SizedBox(width: scale(8)),
            Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: scale(12),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OnboardingIllustration {
  autoCard,
  diamondNetwork,
  coinPath,
  checkCard,
  securePosition,
}

class _OnboardingIllustrationView extends StatelessWidget {
  final _OnboardingIllustration illustration;
  final double Function(double v) scale;
  const _OnboardingIllustrationView({
    required this.illustration,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    switch (illustration) {
      case _OnboardingIllustration.autoCard:
        return _IllustrationAutoCard(scale: scale);
      case _OnboardingIllustration.diamondNetwork:
        return _IllustrationDiamondNetwork(scale: scale);
      case _OnboardingIllustration.coinPath:
        return _IllustrationCoinPath(scale: scale);
      case _OnboardingIllustration.checkCard:
        return _IllustrationCheckCard(scale: scale);
      case _OnboardingIllustration.securePosition:
        return _IllustrationSecurePosition(scale: scale);
    }
  }
}

class _IllustrationBackground extends StatelessWidget {
  final double Function(double v) scale;
  final Widget child;
  const _IllustrationBackground({required this.scale, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF0B1622), const Color(0xFF09111A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _StarDotsPainter())),
          child,
        ],
      ),
    );
  }
}

class _StarDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()..color = Colors.white.withValues(alpha: 0.07);
    final p2 = Paint()..color = const Color(0xFF1B4BFF).withValues(alpha: 0.12);
    for (int i = 0; i < 26; i++) {
      final dx = ((i * 97) % 100) / 100.0 * size.width;
      final dy = ((i * 53) % 100) / 100.0 * size.height;
      canvas.drawCircle(Offset(dx, dy), 1.2, i.isEven ? p1 : p2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IllustrationAutoCard extends StatefulWidget {
  final double Function(double v) scale;
  const _IllustrationAutoCard({required this.scale});

  @override
  State<_IllustrationAutoCard> createState() => _IllustrationAutoCardState();
}

class _IllustrationAutoCardState extends State<_IllustrationAutoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF3B82F6);
    final green = const Color(0xFF22C55E);
    final surface = const Color(0xFF1E293B);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        final base = math.min(w, h);
        final cardWidth = math.min(w * 0.78, widget.scale(240));
        final cardPadding = widget.scale(16);
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFF0F172A)),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  spacing: widget.scale(24),
                  dotRadius: widget.scale(1.1),
                  color: blue.withValues(alpha: 0.15),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [blue.withValues(alpha: 0.08), Colors.transparent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _pulse,
              builder: (context, child) {
                final t = 0.5 - 0.5 * math.cos(_pulse.value * math.pi * 2);
                final size = base * (0.56 + 0.06 * t);
                return Center(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: blue.withValues(alpha: 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.40),
                          blurRadius: widget.scale(90),
                          spreadRadius: widget.scale(8),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Center(
              child: Container(
                width: cardWidth,
                padding: EdgeInsets.all(cardPadding),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(widget.scale(18)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: widget.scale(26),
                      offset: Offset(0, widget.scale(16)),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: widget.scale(40),
                          height: widget.scale(40),
                          decoration: BoxDecoration(
                            color: blue.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.smart_toy_rounded,
                            size: widget.scale(22),
                            color: blue,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: widget.scale(10),
                            vertical: widget.scale(6),
                          ),
                          decoration: BoxDecoration(
                            color: green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: green.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, child) {
                                  final t =
                                      0.5 -
                                      0.5 *
                                          math.cos(_pulse.value * math.pi * 2);
                                  return Container(
                                    width: widget.scale(6),
                                    height: widget.scale(6),
                                    decoration: BoxDecoration(
                                      color: green.withValues(
                                        alpha: 0.65 + 0.35 * t,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: widget.scale(8)),
                              Text(
                                'Auto',
                                style: TextStyle(
                                  color: green,
                                  fontSize: widget.scale(11),
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: widget.scale(14)),
                    Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Rate',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: widget.scale(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '12.5 ETA/hr',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.scale(14),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: widget.scale(8)),
                        Container(
                          height: widget.scale(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.75,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: blue,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: widget.scale(12)),
                        Container(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                        SizedBox(height: widget.scale(12)),
                        Row(
                          children: [
                            Text(
                              'Total Mined',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: widget.scale(12),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.monetization_on_rounded,
                              size: widget.scale(16),
                              color: const Color(0xFFF59E0B),
                            ),
                            SizedBox(width: widget.scale(6)),
                            Text(
                              '2,840.5',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: widget.scale(12.5),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -widget.scale(12),
              right: -widget.scale(12),
              child: Container(
                width: widget.scale(70),
                height: widget.scale(70),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: blue.withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: 0.25),
                      blurRadius: widget.scale(40),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: h * 0.20,
              left: w * 0.18,
              child: Container(
                width: widget.scale(52),
                height: widget.scale(52),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFA855F7).withValues(alpha: 0.12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA855F7).withValues(alpha: 0.20),
                      blurRadius: widget.scale(34),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _IllustrationSecurePosition extends StatefulWidget {
  final double Function(double v) scale;
  const _IllustrationSecurePosition({required this.scale});

  @override
  State<_IllustrationSecurePosition> createState() =>
      _IllustrationSecurePositionState();
}

class _IllustrationSecurePositionState
    extends State<_IllustrationSecurePosition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF3B82F6);
    final surface = const Color(0xFF1E293B);
    return LayoutBuilder(
      builder: (context, c) {
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(color: surface)),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: _DotGridPainter(
                  spacing: widget.scale(24),
                  dotRadius: widget.scale(1.1),
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [blue.withValues(alpha: 0.10), Colors.transparent],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(widget.scale(14)),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 240 / 200,
                    child: CustomPaint(
                      painter: _SecurePositionSvgPainter(pulse: _pulseCtrl),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.scale(12)),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.scale(14),
                    vertical: widget.scale(8),
                  ),
                  decoration: BoxDecoration(
                    color: surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.30),
                        blurRadius: widget.scale(18),
                        offset: Offset(0, widget.scale(10)),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        size: widget.scale(18),
                        color: blue,
                      ),
                      SizedBox(width: widget.scale(8)),
                      Text(
                        'EARLY ACCESS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: widget.scale(11.5),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final double spacing;
  final double dotRadius;
  final Color color;
  const _DotGridPainter({
    required this.spacing,
    required this.dotRadius,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    final dxCount = (size.width / spacing).ceil() + 1;
    final dyCount = (size.height / spacing).ceil() + 1;
    for (int y = 0; y < dyCount; y++) {
      for (int x = 0; x < dxCount; x++) {
        final dx = x * spacing;
        final dy = y * spacing;
        canvas.drawCircle(Offset(dx, dy), dotRadius, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) {
    return oldDelegate.spacing != spacing ||
        oldDelegate.dotRadius != dotRadius ||
        oldDelegate.color != color;
  }
}

class _SecurePositionSvgPainter extends CustomPainter {
  final Animation<double> pulse;
  _SecurePositionSvgPainter({required this.pulse}) : super(repaint: pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 240.0;
    final sy = size.height / 200.0;
    canvas.save();
    canvas.scale(sx, sy);

    final slate100 = Paint()..color = Colors.white.withValues(alpha: 0.06);
    final slate200 = Paint()..color = Colors.white.withValues(alpha: 0.10);
    final phoneBlue = Paint()..color = const Color(0xFF3B82F6);

    canvas.drawOval(
      Rect.fromCenter(center: const Offset(120, 160), width: 180, height: 48),
      slate100,
    );

    final side1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 115, 30, 50),
      const Radius.circular(6),
    );
    canvas.drawRRect(side1, slate200);

    final side2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(175, 125, 30, 40),
      const Radius.circular(6),
    );
    canvas.drawRRect(side2, slate200);

    final phoneRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(85, 60, 70, 100),
      const Radius.circular(10),
    );
    canvas.drawRRect(phoneRect, phoneBlue);

    final overlay = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
      ).createShader(const Rect.fromLTWH(85, 60, 70, 100))
      ..color = Colors.white.withValues(alpha: 0.25);
    canvas.save();
    canvas.clipRRect(phoneRect);
    canvas.drawRect(const Rect.fromLTWH(85, 60, 70, 100), overlay);
    canvas.restore();

    final ring = Paint()..color = Colors.white.withValues(alpha: 0.18);
    canvas.drawCircle(const Offset(120, 100), 20, ring);

    final check = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(110, 100)
      ..lineTo(116, 106)
      ..lineTo(130, 92);
    canvas.drawPath(path, check);

    final pulseT = 0.70 + 0.30 * math.sin(pulse.value * math.pi * 2);
    final amber = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.65 + 0.35 * pulseT);
    canvas.drawCircle(const Offset(165, 50), 6 * (0.92 + 0.16 * pulseT), amber);

    final amberLine = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(165, 56), const Offset(165, 62), amberLine);

    final smallBlue = Paint()
      ..color = const Color(0xFF93C5FD).withValues(alpha: 0.50);
    canvas.drawCircle(const Offset(65, 70), 4, smallBlue);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SecurePositionSvgPainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}

class _IllustrationDiamondNetwork extends StatelessWidget {
  final double Function(double v) scale;
  const _IllustrationDiamondNetwork({required this.scale});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return _IllustrationBackground(
      scale: scale,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final center = Offset(w * 0.50, h * 0.55);
          final nodes = <Offset>[
            Offset(w * 0.20, h * 0.22),
            Offset(w * 0.82, h * 0.24),
            Offset(w * 0.22, h * 0.78),
            Offset(w * 0.80, h * 0.74),
          ];
          return CustomPaint(
            painter: _NetworkLinesPainter(center: center, nodes: nodes),
            child: Stack(
              children: [
                Positioned(
                  left: center.dx - scale(54),
                  top: center.dy - scale(54),
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: scale(108),
                      height: scale(108),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(scale(26)),
                        gradient: LinearGradient(
                          colors: [
                            blue.withValues(alpha: 0.95),
                            blue.withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: blue.withValues(alpha: 0.35),
                            blurRadius: scale(34),
                            offset: Offset(0, scale(18)),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Transform.rotate(
                        angle: -0.785398,
                        child: Icon(
                          Icons.diamond_rounded,
                          color: Colors.white,
                          size: scale(44),
                        ),
                      ),
                    ),
                  ),
                ),
                for (final p in nodes)
                  Positioned(
                    left: p.dx - scale(26),
                    top: p.dy - scale(26),
                    child: Container(
                      width: scale(52),
                      height: scale(52),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.person_rounded,
                        size: scale(20),
                        color: Colors.white38,
                      ),
                    ),
                  ),
                Positioned(
                  left: nodes.first.dx + scale(12),
                  top: nodes.first.dy - scale(18),
                  child: Container(
                    width: scale(22),
                    height: scale(22),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: scale(16),
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  left: center.dx - scale(36),
                  top: center.dy - scale(92),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: scale(12),
                      vertical: scale(7),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.trending_up_rounded,
                          size: scale(16),
                          color: blue,
                        ),
                        SizedBox(width: scale(6)),
                        Text(
                          '+12%',
                          style: TextStyle(
                            color: blue,
                            fontSize: scale(13),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NetworkLinesPainter extends CustomPainter {
  final Offset center;
  final List<Offset> nodes;
  _NetworkLinesPainter({required this.center, required this.nodes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final n in nodes) {
      _drawDashedLine(canvas, paint, center, n, dash: 7, gap: 6);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Paint paint,
    Offset a,
    Offset b, {
    required double dash,
    required double gap,
  }) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist <= 0.01) return;
    final ux = dx / dist;
    final uy = dy / dist;
    double t = 0;
    while (t < dist) {
      final len = (t + dash <= dist) ? dash : (dist - t);
      final p1 = Offset(a.dx + ux * t, a.dy + uy * t);
      final p2 = Offset(a.dx + ux * (t + len), a.dy + uy * (t + len));
      canvas.drawLine(p1, p2, paint);
      t += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _NetworkLinesPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.nodes != nodes;
  }
}

class _IllustrationCoinPath extends StatelessWidget {
  final double Function(double v) scale;
  const _IllustrationCoinPath({required this.scale});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return _IllustrationBackground(
      scale: scale,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final left = Offset(w * 0.18, h * 0.72);
          final mid = Offset(w * 0.50, h * 0.55);
          final right = Offset(w * 0.82, h * 0.28);
          return CustomPaint(
            painter: _CoinPathPainter(left: left, mid: mid, right: right),
            child: Stack(
              children: [
                Positioned(
                  left: left.dx - scale(30),
                  top: left.dy - scale(30),
                  child: Container(
                    width: scale(60),
                    height: scale(60),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121F2B).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(scale(18)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: const Color(0xFFFFB020),
                      size: scale(26),
                    ),
                  ),
                ),
                Positioned(
                  left: mid.dx - scale(26),
                  top: mid.dy - scale(26),
                  child: Container(
                    width: scale(52),
                    height: scale(52),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(scale(16)),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.diamond_rounded,
                      color: blue.withValues(alpha: 0.85),
                      size: scale(24),
                    ),
                  ),
                ),
                Positioned(
                  left: right.dx - scale(34),
                  top: right.dy - scale(34),
                  child: Container(
                    width: scale(68),
                    height: scale(68),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: blue.withValues(alpha: 0.35),
                          blurRadius: scale(26),
                          offset: Offset(0, scale(16)),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '₿',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: scale(30),
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: right.dx + scale(16),
                  top: right.dy - scale(44),
                  child: Container(
                    width: scale(16),
                    height: scale(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CoinPathPainter extends CustomPainter {
  final Offset left;
  final Offset mid;
  final Offset right;
  _CoinPathPainter({
    required this.left,
    required this.mid,
    required this.right,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(left.dx, left.dy)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.58,
        size.width * 0.40,
        size.height * 0.66,
        mid.dx,
        mid.dy,
      )
      ..cubicTo(
        size.width * 0.62,
        size.height * 0.40,
        size.width * 0.72,
        size.height * 0.40,
        right.dx,
        right.dy,
      );
    for (final metric in path.computeMetrics()) {
      double d = 0;
      while (d < metric.length) {
        final next = (d + 8).clamp(0.0, metric.length);
        final segment = metric.extractPath(d, next);
        canvas.drawPath(segment, paint);
        d += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoinPathPainter oldDelegate) {
    return oldDelegate.left != left ||
        oldDelegate.mid != mid ||
        oldDelegate.right != right;
  }
}

class _IllustrationCheckCard extends StatelessWidget {
  final double Function(double v) scale;
  const _IllustrationCheckCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return _IllustrationBackground(
      scale: scale,
      child: Stack(
        children: [
          Positioned(
            left: scale(36),
            bottom: scale(-18),
            child: Container(
              width: scale(64),
              height: scale(170),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(scale(18)),
              ),
            ),
          ),
          Positioned(
            right: scale(36),
            bottom: scale(-18),
            child: Container(
              width: scale(64),
              height: scale(150),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(scale(18)),
              ),
            ),
          ),
          Center(
            child: Container(
              width: scale(108),
              height: scale(140),
              decoration: BoxDecoration(
                color: blue.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(scale(22)),
                boxShadow: [
                  BoxShadow(
                    color: blue.withValues(alpha: 0.35),
                    blurRadius: scale(30),
                    offset: Offset(0, scale(18)),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Container(
                width: scale(56),
                height: scale(56),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: scale(34),
                ),
              ),
            ),
          ),
          Positioned(
            right: scale(46),
            top: scale(26),
            child: Container(
              width: scale(10),
              height: scale(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB020),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: scale(52),
            top: scale(64),
            child: Container(
              width: scale(8),
              height: scale(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
