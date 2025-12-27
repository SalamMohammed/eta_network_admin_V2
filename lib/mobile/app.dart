import 'package:flutter/material.dart';
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
    const navBg = Color(0xFF141E28);
    final pages = const [
      MobileHomePage(),
      BalancePage(),
      ReferralsPage(),
      ProfilePage(),
    ];
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: navBg,
        indicatorColor: Colors.transparent,
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_add_rounded),
            label: 'Referrals',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: null,
    );
  }
}
