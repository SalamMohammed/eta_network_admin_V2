import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class UsernamePage extends StatefulWidget {
  const UsernamePage({super.key});
  @override
  State<UsernamePage> createState() => _UsernamePageState();
}

class _UsernamePageState extends State<UsernamePage> {
  final userCtrl = TextEditingController();
  String availability = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 60),
          const Text('Choose a username', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username'), onChanged: (v) => setState(() => availability = v.length >= 3 ? 'Available' : 'Too short')),
          const SizedBox(height: 8),
          Text(availability, style: TextStyle(color: availability == 'Available' ? AppColors.primaryAccent : AppColors.vipAccent)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: availability == 'Available' ? () {} : null, child: const Text('Continue')),
        ]),
      ),
    );
  }
}
