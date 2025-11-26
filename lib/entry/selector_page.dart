import 'package:flutter/material.dart';
import '../shared/theme/colors.dart';
import '../admin_dashboard/dashboard_page.dart';
import '../mobile/app.dart';

class SelectorPage extends StatelessWidget {
  const SelectorPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.deepLayer, AppColors.primaryBackground], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Mode', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardPage()));
                  },
                  child: const Text('Admin Dashboard'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAppScaffold()));
                  },
                  child: const Text('Mobile App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
