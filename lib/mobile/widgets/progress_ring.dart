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
          child: CustomPaint(painter: _RingPainter(progress)),
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
    final start = -90.0;
    final sweep = 360 * progress;
    final base = Paint()
      ..color = AppColors.deepLayer.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = AppColors.primaryAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    // base circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      0,
      6.283185,
      false,
      base,
    );
    // progress arc
    if (sweep > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        start * 3.14159 / 180,
        sweep * 3.14159 / 180,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}
