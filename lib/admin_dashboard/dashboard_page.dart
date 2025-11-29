import 'package:flutter/material.dart';
import 'widgets/sidebar.dart';
import 'widgets/header.dart';
import 'pages/overview_page.dart';
import 'pages/users_page.dart';
import 'pages/user_detail_page.dart';
import 'pages/app_config_page.dart';
import 'pages/referrals_ranks_page.dart';
import 'pages/notifications_page.dart';
import 'pages/ads_monetization_page.dart';
import 'pages/settings_legal_page.dart';
import 'pages/manager_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int selectedIndex = 0;
  Map<String, dynamic>? selectedUser;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        return Scaffold(
          body: Row(
            children: [
              if (wide)
                SizedBox(
                  width: 280,
                  child: Sidebar(
                    selectedIndex: selectedIndex,
                    onSelect: (i) => setState(() => selectedIndex = i),
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    const Header(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(0),
                        child: _buildSection(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => selectedIndex = i),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: 'Overview',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_alt_rounded),
                      label: 'Users',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: 'User Detail',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_mode_rounded),
                      selectedIcon: Icon(Icons.auto_awesome_rounded),
                      label: 'Manager',
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSection() {
    switch (selectedIndex) {
      case 0:
        return const OverviewPage();
      case 1:
        return UsersPage(
          onOpenDetail: (u) => setState(() {
            selectedUser = u;
            selectedIndex = 2;
          }),
        );
      case 2:
        return UserDetailPage(user: selectedUser);
      case 3:
        return const AppConfigPage();
      case 4:
        return const ReferralsRanksPage();
      case 5:
        return const NotificationsPage();
      case 6:
        return const AdsMonetizationPage();
      case 7:
        return const SettingsLegalPage();
      case 8:
        return const ManagerPage();
      default:
        return const OverviewPage();
    }
  }
}
