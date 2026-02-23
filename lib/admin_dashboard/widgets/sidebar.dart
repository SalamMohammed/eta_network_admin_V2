import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class Sidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const Sidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem('Overview', Icons.dashboard_rounded),
      _NavItem('Users', Icons.people_alt_rounded),
      _NavItem('User Detail', Icons.person_rounded),
      _NavItem('App Config (Points)', Icons.speed_rounded),
      _NavItem('Referrals & Ranks', Icons.workspace_premium_rounded),
      _NavItem('Notifications', Icons.notifications_rounded),
      _NavItem('Ads & Monetization', Icons.ads_click_rounded),
      _NavItem('Settings & Legal', Icons.settings_suggest_rounded),
      _NavItem('Manager', Icons.auto_mode_rounded),
      _NavItem('Data Search', Icons.search_rounded),
    ];
    return Container(
      color: AppColors.deepLayer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(color: AppColors.primaryBackground),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Eta Admin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i++)
                    _SidebarButton(
                      label: items[i].label,
                      icon: items[i].icon,
                      selected: i == selectedIndex,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.vipAccent.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.vipAccent,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'VIP',
                    style: TextStyle(
                      color: AppColors.vipAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}

class _SidebarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SidebarButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  (selected
                          ? AppColors.primaryAccent
                          : AppColors.primaryBackground)
                      .withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? AppColors.primaryAccent
                    : AppColors.secondaryAccent,
              ),
              const SizedBox(width: 12),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
