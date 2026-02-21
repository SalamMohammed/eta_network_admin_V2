import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import '../shared/constants.dart';
import '../mobile/app.dart';
import '../mobile/onboarding/onboarding_flow.dart';
import '../admin_dashboard/dashboard_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {}
    switch (AppEntryConfig.mode) {
      case AppEntryMode.selector:
        return _buildMobileMode(context);
      case AppEntryMode.mobile:
        return _buildMobileMode(context);
      case AppEntryMode.admin:
        return _buildAdminMode(context);
    }
  }

  Widget _buildMobileMode(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const LoginPage(
            goToSelectorAfterAuth: false,
          );
        }
        return const _MobileOnboardingRouter();
      },
    );
  }

  Widget _buildAdminMode(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const LoginPage(
            goToSelectorAfterAuth: false,
          );
        }
        return const DashboardPage();
      },
    );
  }
}

class _MobileOnboardingRouter extends StatefulWidget {
  const _MobileOnboardingRouter();

  @override
  State<_MobileOnboardingRouter> createState() =>
      _MobileOnboardingRouterState();
}

class _MobileOnboardingRouterState extends State<_MobileOnboardingRouter> {
  bool? _completed;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('eta_onboarding_completed') ?? false;
    if (!mounted) return;
    setState(() {
      _completed = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_completed == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_completed!) {
      return const MobileAppScaffold();
    }
    return const OnboardingFlow();
  }
}
