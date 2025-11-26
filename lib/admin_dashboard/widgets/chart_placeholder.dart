import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class ChartPlaceholder extends StatelessWidget {
  final String title;
  const ChartPlaceholder({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondaryAccent.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(16, (i) {
                final h = (i % 7 + 4) * 8.0;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(colors: [AppColors.secondaryAccent, AppColors.primaryAccent], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    ),
                  ),
                );
              }),
            );
          }),
        ),
      ]),
    );
  }
}
