import 'package:flutter/material.dart';
import '../shared/theme/colors.dart';
import 'home_page.dart';
import 'balance/balance_page.dart';
import 'referrals/referrals_page.dart';
import 'profile/profile_page.dart';

class MobileAppScaffold extends StatefulWidget {
  const MobileAppScaffold({super.key});

  @override
  State<MobileAppScaffold> createState() => _MobileAppScaffoldState();
}

class _MobileAppScaffoldState extends State<MobileAppScaffold> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      MobileHomePage(),
      BalancePage(),
      ReferralsPage(),
      ProfilePage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bolt_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_toggle_off_rounded), label: 'Balance'),
          NavigationDestination(icon: Icon(Icons.group_add_rounded), label: 'Referrals'),
          NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
      floatingActionButton: index == 0
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryAccent,
              onPressed: () {
                // No-op: refresh handled inside home page
              },
              child: const Icon(Icons.refresh_rounded, color: AppColors.deepLayer),
            )
          : null,
    );
  }
}
