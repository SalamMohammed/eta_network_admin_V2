import 'package:flutter/material.dart';
import 'home_page.dart';
import 'balance/balance_page.dart';
import 'referrals/referrals_page.dart';
import 'profile/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/auth_gate.dart';
import '../services/auth_verification_service.dart';
import '../services/mining_state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The main scaffold for the logged-in mobile app.
// It handles navigation between the main tabs (Home, Balance, Referrals, Profile).
class MobileAppScaffold extends StatefulWidget {
  const MobileAppScaffold({super.key});

  @override
  State<MobileAppScaffold> createState() => _MobileAppScaffoldState();
}

class _MobileAppScaffoldState extends State<MobileAppScaffold> {
  // Tracks which tab is currently selected (0 = Home).
  int index = 0;
  bool _referralsInitialized = false;
  bool _profileInitialized = false;

  @override
  Widget build(BuildContext context) {
    // Background color for the navigation bar.
    const navBg = Color(0xFF141E28);

    final pages = [
      const MobileHomePage(),
      const BalancePage(),
      _referralsInitialized ? const ReferralsPage() : const SizedBox.shrink(),
      _profileInitialized ? const ProfilePage() : const SizedBox.shrink(),
    ];

    // Listen to changes in the current user's authentication state.
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        final u = snapshot.data;

        final unverified = u != null && !(u.emailVerified);

        // The main layout with the content body and bottom navigation bar.
        final scaffold = Scaffold(
          // IndexedStack keeps all pages alive in memory, so switching tabs doesn't reset them.
          body: IndexedStack(index: index, children: pages),

          bottomNavigationBar: NavigationBar(
            backgroundColor: navBg,
            indicatorColor:
                Colors.transparent, // No highlight bubble behind the icon.
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() {
              index = i;
              if (i == 2 && !_referralsInitialized) {
                _referralsInitialized = true;
              }
              if (i == 3 && !_profileInitialized) {
                _profileInitialized = true;
              }
            }),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Balance',
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

        if (!unverified) return scaffold;

        return Stack(
          children: [
            scaffold,
            Material(
              color: Colors.black.withValues(alpha: 0.85),
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E272E),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_unread_rounded,
                          size: 64,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'We have sent a verification link to your email address. Please verify your account to unlock all features.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await AuthVerificationService.sendVerificationEmail();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email sent'),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Resend Email',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            final ok =
                                await AuthVerificationService.refreshAndCheckVerified();
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Email verified successfully!'),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Email not verified yet. Please check your inbox.',
                                  ),
                                ),
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'I have verified',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () async {
                            MiningStateService().reset();
                            try {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.remove(
                                'referral_code_${FirebaseAuth.instance.currentUser?.uid ?? ''}',
                              );
                            } catch (_) {}
                            try {
                              await GoogleSignIn().signOut();
                            } catch (_) {}
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AuthGate(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.redAccent.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
