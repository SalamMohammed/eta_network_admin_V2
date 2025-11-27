import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/theme/colors.dart';
import '../../auth/auth_gate.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.secondaryAccent,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('alex'),
                      SizedBox(height: 6),
                      Text('Explorer'),
                    ],
                  ),
                  const Spacer(),
                  const Icon(Icons.qr_code_2_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _section('Account Info', [
              _kv('Username', 'alex'),
              _kv('Email', 'alex@example.com'),
              _kv('UID', 'UID1234…'),
              _kv('Device ID', 'device-xyz'),
              _kv('Timezone', 'UTC+1'),
            ]),
            _section('Performance', [
              _kv('StreakDays', '6'),
              _kv('Referral count', '12'),
              _kv('Total mining sessions', '142'),
            ]),
            _section('Notifications', [
              _toggle('Enable notifications', true),
              _toggle('Streak reminders', true),
            ]),
            _section('Legal', [
              _button(context, 'FAQ'),
              _button(context, 'Disclaimer'),
              _button(context, 'Terms & Privacy'),
            ]),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
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
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(title), const SizedBox(height: 8), ...children],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _toggle(String label, bool value) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(value: value, onChanged: (_) {}),
      ],
    );
  }

  Widget _button(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ElevatedButton(onPressed: () {}, child: Text(label)),
    );
  }
}
