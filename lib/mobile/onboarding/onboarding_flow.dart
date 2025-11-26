import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _ctrl = PageController();
  bool understood = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _ctrl,
        children: [
          _welcome(),
          _howItWorks(),
          _position(),
          _disclaimer(),
        ],
      ),
    );
  }

  Widget _welcome() {
    return _page(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 160, decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [AppColors.secondaryAccent, AppColors.primaryAccent]))),
          const SizedBox(height: 16),
          const Text('Start Earning Your ETA Power', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Daily mining. Real marketplace utility coming soon.'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut), child: const Text('Next')),
        ],
      ),
    );
  }

  Widget _howItWorks() {
    return _page(
      Column(children: const [
        _Bullet(icon: Icons.touch_app_rounded, text: 'Tap once per day'),
        SizedBox(height: 12),
        _Bullet(icon: Icons.token_rounded, text: 'Earn ETA automatically'),
        SizedBox(height: 12),
        _Bullet(icon: Icons.shopping_bag_rounded, text: 'Use it in future marketplace'),
      ]),
    );
  }

  Widget _position() {
    return _page(
      Column(children: const [
        SizedBox(height: 16),
        _Arc(),
        SizedBox(height: 16),
        Text('Your early ETA points will define your power in the future ecosystem.'),
      ]),
    );
  }

  Widget _disclaimer() {
    return _page(
      Column(children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primaryBackground, borderRadius: BorderRadius.circular(16)),
          child: const Text('These are loyalty points, not crypto yet.\nNo guaranteed future value.'),
        ),
        const SizedBox(height: 12),
        Row(children: [Checkbox(value: understood, onChanged: (v) => setState(() => understood = v ?? false)), const Text('I understand')]),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: understood ? () {} : null, child: const Text('Get Started')),
      ]),
    );
  }

  Widget _page(Widget child) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.deepLayer, AppColors.primaryBackground], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Center(child: child),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: AppColors.secondaryAccent), const SizedBox(width: 8), Text(text)]);
  }
}

class _Arc extends StatelessWidget {
  const _Arc();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: CustomPaint(
        painter: _ArcPainter(),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 20;
    final paint = Paint()
      ..shader = SweepGradient(colors: [AppColors.secondaryAccent, AppColors.primaryAccent]).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -3.14 / 2, 3.14, false, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
