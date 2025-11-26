import 'package:flutter/material.dart';
import '../../shared/theme/colors.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 60),
          const Icon(Icons.token_rounded, size: 72, color: AppColors.secondaryAccent),
          const SizedBox(height: 20),
          const Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 8),
          TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () {}, child: const Text('Login')),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('Forgot Password?')),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('Create New Account')),
        ]),
      ),
    );
  }
}
