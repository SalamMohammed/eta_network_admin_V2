import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class GlowingButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  const GlowingButton({super.key, required this.label, this.onPressed});

  @override
  State<GlowingButton> createState() => _GlowingButtonState();
}

class _GlowingButtonState extends State<GlowingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final glow = 0.4 + 0.3 * _c.value;
        return ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryAccent,
            foregroundColor: AppColors.deepLayer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            shadowColor: AppColors.highlight.withValues(alpha: glow),
            elevation: 10,
          ),
          child: Text(widget.label),
        );
      },
    );
  }
}
