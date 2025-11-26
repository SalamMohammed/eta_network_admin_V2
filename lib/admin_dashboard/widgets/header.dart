import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(color: AppColors.primaryBackground),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Admin Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.deepLayer,
                hintText: 'Search',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.secondaryAccent,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryBackground.withValues(alpha: 0.6),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryBackground.withValues(alpha: 0.6),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryAccent),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: () {}, child: const Text('New')),
        ],
      ),
    );
  }
}
