import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class ProgressRing extends StatelessWidget {
  final double progress; // 0..1
  final Widget child;
  const ProgressRing({super.key, required this.progress, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: _RingPainter(progress),
          ),
        ),
        child,
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter(this.progress);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final start = -90.0;
    final sweep = 360 * progress;
    final base = Paint()
      ..color = AppColors.deepLayer
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final grad = Paint()
      ..shader = SweepGradient(colors: [AppColors.secondaryAccent, AppColors.primaryAccent], startAngle: 0, endAngle: 6.283185).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    // base circle
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 0, 6.283185, false, base);
    // progress arc
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start * 3.14159 / 180, sweep * 3.14159 / 180, false, grad);
  }
  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
