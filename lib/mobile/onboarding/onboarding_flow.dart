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
  double _swipeValue = 0.0;

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
      illustrationAsset: 'android/app/src/images/Check-in daily.png',
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
      illustrationAsset: 'android/app/src/images/Secure your Position.png',
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
      illustrationAsset: 'android/app/src/images/Auto Manager.png',
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
      illustrationAsset: 'android/app/src/images/Create & Share.png',
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
      illustrationAsset: 'android/app/src/images/community driven.png',
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
                      swipeValue: _swipeValue,
                      onAcceptedChanged: (v) {
                        setState(() => _disclaimerAccepted = v);
                      },
                      onSwipeChanged: (v) {
                        setState(() => _swipeValue = v);
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
                          setState(() => _swipeValue = 0.0);
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
    final hasAsset = asset.isNotEmpty;
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
              children: [
                if (hasAsset)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(scale(26)),
                    child: Center(
                      child: FractionallySizedBox(
                        widthFactor: 1,
                        heightFactor: 1,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stack) {
                            return _OnboardingIllustrationView(
                              illustration: _illustrationForSlide(slide),
                              scale: scale,
                            );
                          },
                        ),
                      ),
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
                child: Center(
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: Image.asset(
                      'android/app/src/images/Stay in The Loop.png',
                      fit: BoxFit.fill,
                      errorBuilder: (context, error, stack) {
                        return Center(
                          child: Icon(
                            Icons.notifications_active_rounded,
                            size: scale(64),
                            color: Colors.white54,
                          ),
                        );
                      },
                    ),
                  ),
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
  final double swipeValue;
  final ValueChanged<bool> onAcceptedChanged;
  final ValueChanged<double> onSwipeChanged;
  final Future<void> Function() onSwipeCompleted;

  const _DisclaimerOnboardingPage({
    required this.scale,
    required this.accepted,
    required this.swipeValue,
    required this.onAcceptedChanged,
    required this.onSwipeChanged,
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
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: 1,
                      child: Image.asset(
                        'android/app/src/images/Important Disclaimer.png',
                        fit: BoxFit.fill,
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
              value: swipeValue,
              enabled: accepted,
              onChanged: onSwipeChanged,
              onCompleted: onSwipeCompleted,
            ),
            SizedBox(height: scale(18)),
          ],
        ),
      ),
    );
  }
}

class _SwipeToContinue extends StatelessWidget {
  final double Function(double v) scale;
  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;
  final Future<void> Function() onCompleted;

  const _SwipeToContinue({
    required this.scale,
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    return LayoutBuilder(
      builder: (context, c) {
        final h = scale(56);
        final knob = scale(46);
        final maxX = (c.maxWidth - knob - scale(6)).clamp(0.0, 99999.0);
        final x = (value.clamp(0.0, 1.0) * maxX);
        return GestureDetector(
          onHorizontalDragUpdate: enabled
              ? (d) {
                  if (maxX <= 0) return;
                  final next = (value + (d.delta.dx / maxX)).clamp(0.0, 1.0);
                  onChanged(next);
                }
              : null,
          onHorizontalDragEnd: enabled
              ? (_) async {
                  if (value >= 0.92) {
                    await onCompleted();
                  } else {
                    onChanged(0.0);
                  }
                }
              : (_) => onChanged(0.0),
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
                    fontSize: scale(14.5),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Positioned(
                  left: scale(3) + x,
                  child: Container(
                    width: knob,
                    height: knob,
                    decoration: BoxDecoration(
                      color: enabled ? blue : Colors.white12,
                      shape: BoxShape.circle,
                      boxShadow: enabled
                          ? [
                              BoxShadow(
                                color: blue.withValues(alpha: 0.35),
                                blurRadius: scale(18),
                                offset: Offset(0, scale(10)),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: scale(20),
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

enum _OnboardingIllustration { autoCard, diamondNetwork, coinPath, checkCard }

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

class _IllustrationAutoCard extends StatelessWidget {
  final double Function(double v) scale;
  const _IllustrationAutoCard({required this.scale});

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final green = const Color(0xFF2ECC71);
    final card = Container(
      margin: EdgeInsets.all(scale(18)),
      padding: EdgeInsets.all(scale(16)),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A24).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(scale(22)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: scale(44),
                height: scale(44),
                decoration: BoxDecoration(
                  color: blue.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: scale(22),
                  color: blue.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: scale(14),
                  vertical: scale(8),
                ),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: green.withValues(alpha: 0.30)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: scale(8),
                      height: scale(8),
                      decoration: BoxDecoration(
                        color: green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: scale(8)),
                    Text(
                      'AUTO',
                      style: TextStyle(
                        color: green,
                        fontSize: scale(12),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: scale(16)),
          Row(
            children: [
              Text(
                'Rate',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: scale(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '12.5 ETA/hr',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale(18),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: scale(10)),
          Container(
            height: scale(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                child: Container(
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: scale(16)),
          Row(
            children: [
              Text(
                'Total Mined',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: scale(14),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: scale(18),
                height: scale(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '\$',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: scale(12),
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(width: scale(8)),
              Text(
                '2,840.5',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: scale(18),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return _IllustrationBackground(
      scale: scale,
      child: Center(child: card),
    );
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
