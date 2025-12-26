import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../shared/theme/colors.dart';
import '../../auth/auth_gate.dart';

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
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              try {
                await GoogleSignIn().signOut();
              } catch (_) {}
              await FirebaseAuth.instance.signOut();
              // reset navigation to auth gate
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vipAccent,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
