import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../shared/theme/colors.dart';
import '../shared/firestore_constants.dart';
import 'signup_page.dart';
import '../entry/selector_page.dart';
import '../firebase_options.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    var x = now;
    final buf = StringBuffer();
    for (var i = 0; i < 8; i++) {
      buf.write(chars[x % chars.length]);
      x = (x ~/ chars.length) + 31;
    }
    return buf.toString();
  }

  Future<void> _ensureUserDocExists(User user) async {
    final ref = FirebaseFirestore.instance
        .collection(FirestoreConstants.users)
        .doc(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.set({
        FirestoreUserFields.email: user.email,
        FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final email = user.email ?? '';
    final fallbackUsername = email.isNotEmpty
        ? email.split('@').first
        : user.uid.substring(0, 8);
    final username = (user.displayName ?? '').trim().isEmpty
        ? fallbackUsername
        : user.displayName!.trim();

    await ref.set({
      FirestoreUserFields.uid: user.uid,
      FirestoreUserFields.email: email,
      FirestoreUserFields.username: username,
      FirestoreUserFields.referralCode: _generateReferralCode(),
      FirestoreUserFields.invitedBy: null,
      FirestoreUserFields.referralLocked: false,
      FirestoreUserFields.role: FirestoreUserRoles.free,
      FirestoreUserFields.rank: FirestoreUserRanks.explorer,
      FirestoreUserFields.totalPoints: 0,
      FirestoreUserFields.hourlyRate: 0,
      FirestoreUserFields.lastMiningStart: null,
      FirestoreUserFields.lastMiningEnd: null,
      FirestoreUserFields.streakDays: 0,
      FirestoreUserFields.totalSessions: 0,
      FirestoreUserFields.country: null,
      FirestoreUserFields.deviceId: null,
      FirestoreUserFields.managerEnabled: false,
      FirestoreUserFields.activeManagerId: null,
      if (user.photoURL != null && user.photoURL!.isNotEmpty)
        FirestoreUserFields.thumbnailUrl: user.photoURL,
      FirestoreUserFields.createdAt: FieldValue.serverTimestamp(),
      FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
      FirestoreUserFields.subscription: {
        FirestoreUserSubscriptionFields.status: 'expired',
        FirestoreUserSubscriptionFields.autoRenew: false,
      },
    }, SetOptions(merge: true));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SelectorPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e);
      });
    } catch (_) {
      setState(() {
        _error = 'Login failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      UserCredential cred;
      if (kIsWeb) {
        cred = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        final googleSignIn = GoogleSignIn(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? DefaultFirebaseOptions.ios.iosClientId
              : null,
          scopes: const ['email'],
        );
        final account = await googleSignIn.signIn();
        if (account == null) {
          return;
        }
        final auth = await account.authentication;
        final oauthCred = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        cred = await FirebaseAuth.instance.signInWithCredential(oauthCred);
      }

      final user = cred.user;
      if (user != null) {
        await _ensureUserDocExists(user);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SelectorPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e);
      });
    } catch (_) {
      setState(() {
        _error = 'Google sign-in failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'user-disabled':
        return 'This user account is disabled';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      case 'account-exists-with-different-credential':
        return 'Account exists with a different sign-in method';
      case 'network-request-failed':
        return 'Network error, check your connection';
      default:
        return e.message ?? 'Authentication error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepLayer, AppColors.primaryBackground],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final cardWidth = width < 520 ? width : 480.0;
            return Center(
              child: SizedBox(
                width: cardWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Email required'
                                : null,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          if (_error != null) ...[
                            Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                          ],
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _login,
                              child: const Text('Sign in'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loading ? null : _loginWithGoogle,
                              child: const Text('Continue with Google'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _loading
                                ? null
                                : () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupPage(),
                                      ),
                                    );
                                  },
                            child: const Text('No account? Register'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
