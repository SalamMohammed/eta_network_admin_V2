import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'dart:typed_data';
import '../shared/theme/colors.dart';
import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';
import 'login_page.dart';
import '../services/referral_engine.dart';
import '../services/auth_verification_service.dart';
import '../services/install_referrer_service.dart';

import 'auth_gate.dart';

class SignupPage extends StatefulWidget {
  final bool goToSelectorAfterAuth;

  const SignupPage({super.key, this.goToSelectorAfterAuth = true});
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  final _referralController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _checkInstallReferrer();
  }

  Future<void> _checkInstallReferrer() async {
    final code = await InstallReferrerService.getCapturedReferralCode();
    if (code != null && code.isNotEmpty && mounted) {
      setState(() {
        _referralController.text = code;
      });
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      String ts() => DateTime.now().toIso8601String();
      void log(
        String level,
        String op,
        String msg, {
        Object? error,
        StackTrace? stack,
        Map<String, Object?> extra = const {},
      }) {
        final extras = extra.isEmpty ? '' : ' | extra=${extra.toString()}';
        final err = error == null ? '' : ' | error=$error';
        final st = stack == null ? '' : ' | stack=${stack.toString()}';
        debugPrint('[$level][${ts()}][$op] $msg$extras$err$st');
      }

      debugPrint(
        'DEBUG: Creating user with email and password (email=${_emailController.text.trim()})...',
      );
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint(
        'DEBUG: createUserWithEmailAndPassword success. UID: ${cred.user?.uid}',
      );

      final uid = cred.user!.uid;
      debugPrint('DEBUG: User created successfully. UID: $uid');

      // Force auth propagation before Firestore writes
      debugPrint('DEBUG: Waiting for initial auth propagation (2s)...');
      await Future.delayed(const Duration(seconds: 2));
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        debugPrint(
          'DEBUG: Initial user reload complete. User: ${FirebaseAuth.instance.currentUser?.uid}',
        );
      } catch (e) {
        debugPrint('DEBUG: Initial user reload failed: $e');
      }

      if (FirebaseAuth.instance.currentUser == null) {
        throw FirebaseAuthException(
          code: 'auth-propagation-failed',
          message:
              'User is unauthenticated after creation. Please try logging in.',
        );
      }

      final username = _emailController.text.trim().split('@').first;
      final referralCode = _generateReferralCode();
      log(
        'INFO',
        'uid-flag',
        'creating signup user doc with unified earnings defaults',
        extra: {'uid': uid},
      );
      try {
        debugPrint('DEBUG: Creating user document in Firestore...');
        await _retry(
          () => FirestoreHelper.instance
              .collection(FirestoreConstants.users)
              .doc(uid)
              .set({
                FirestoreUserFields.uid: uid,
                FirestoreUserFields.email: cred.user!.email,
                FirestoreUserFields.username: username,
                FirestoreUserFields.migrationUnifiedEarnings: true,
                FirestoreUserFields.referralCode: referralCode,
                FirestoreUserFields.invitedBy: null,
                FirestoreUserFields.referralLocked: false,
                FirestoreUserFields.role: FirestoreUserRoles.free,
                FirestoreUserFields.rank: FirestoreUserRanks.explorer,
                FirestoreUserFields.totalPoints: 0,
                FirestoreUserFields.lastMiningStart: null,
                FirestoreUserFields.lastMiningEnd: null,
                FirestoreUserFields.streakDays: 0,
                FirestoreUserFields.totalSessions: 0,
                FirestoreUserFields.country: null,
                FirestoreUserFields.deviceId: null,
                FirestoreUserFields.managerEnabled: false,
                FirestoreUserFields.activeManagerId: null,
                FirestoreUserFields.createdAt: FieldValue.serverTimestamp(),
                FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
                FirestoreUserFields.subscription: {
                  FirestoreUserSubscriptionFields.status: 'expired',
                  FirestoreUserSubscriptionFields.autoRenew: false,
                },
              }, SetOptions(merge: true)),
        );
        log('INFO', 'uid-flag', 'created signup user doc', extra: {'uid': uid});
      } on FirebaseException catch (fe, st) {
        log(
          'ERROR',
          'uid-flag',
          'failed creating signup user doc',
          error: 'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
          stack: st,
          extra: {'uid': uid},
        );
        rethrow;
      }

      // Initialize unified earnings fields on user doc
      await _retry(
        () => FirestoreHelper.instance
            .collection(FirestoreConstants.users)
            .doc(uid)
            .set({
              FirestoreUserFields.hourlyRate: 0,
              FirestoreUserFields.managedCoinSelections: [],
              FirestoreUserFields.rateBase: 0.0,
              FirestoreUserFields.rateStreak: 0.0,
              FirestoreUserFields.rateRank: 0.0,
              FirestoreUserFields.rateReferral: 0.0,
              FirestoreUserFields.rateManager: 0.0,
              FirestoreUserFields.rateAds: 0.0,
              FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true)),
      );

      try {
        final b = Uint8List(0);
        final r = FirebaseStorage.instance.ref().child('users/$uid/thumbnail');
        await _retry(
          () => r.putData(b, SettableMetadata(contentType: 'image/png')),
        );
        final u = await _retry(() => r.getDownloadURL());
        await _retry(
          () => FirestoreHelper.instance
              .collection(FirestoreConstants.users)
              .doc(uid)
              .set({
                FirestoreUserFields.thumbnailUrl: u,
              }, SetOptions(merge: true)),
        );
      } catch (e) {
        debugPrint('DEBUG: Thumbnail setup failed (non-critical): $e');
        // Continue signup even if thumbnail fails
      }

      final providedCode = _referralController.text.trim();
      await ReferralEngine.processReferralOnSignup(
        uid: uid,
        referralCode: providedCode.isEmpty ? null : providedCode,
        inviteeEmail: cred.user?.email,
        inviteeUsername: username,
      );

      await AuthVerificationService.sendVerificationEmail();

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Finalizing setup...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait for auth propagation to avoid "User is unauthenticated" race conditions
        await Future.delayed(const Duration(seconds: 2));
        try {
          await FirebaseAuth.instance.currentUser?.reload();
        } catch (_) {}

        // Navigate to AuthGate which will handle the authenticated state
        // and show the verification overlay via MobileAppScaffold
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e);
      });
    } on FirebaseException catch (e) {
      setState(() {
        _error = _friendlyFirestoreError(e);
      });
    } catch (e) {
      setState(() {
        _error = 'Registration failed';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blue = const Color(0xFF1B4BFF);
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final base = (w < h ? w : h);
    final tScale =
        (base / 390.0).clamp(0.82, 1.12) * (h / 860.0).clamp(0.72, 1.0);
    double s(double v) => v * tScale;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.deepLayer, AppColors.primaryBackground],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final content = Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(22),
                          vertical: s(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: s(6)),
                            Row(
                              children: [
                                InkWell(
                                  onTap: () => Navigator.of(context).maybePop(),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Container(
                                    width: s(40),
                                    height: s(40),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: s(18),
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: s(16),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: s(40)),
                              ],
                            ),
                            SizedBox(height: s(18)),
                            Text(
                              'Join ETA Network',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: s(30),
                                fontWeight: FontWeight.w900,
                                height: 1.06,
                              ),
                            ),
                            SizedBox(height: s(8)),
                            Text(
                              'Start earning ETA and other coins mine today.',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: s(14.5),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: s(18)),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: s(8)),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'name@example.com',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: s(15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: s(14),
                                        vertical: s(16),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(color: blue),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      errorStyle: TextStyle(
                                        color: const Color(0xFFFF6B6B),
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Email required'
                                        : null,
                                  ),
                                  SizedBox(height: s(16)),
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: s(8)),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Min. 8 characters',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: s(15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: s(14),
                                        vertical: s(16),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(color: blue),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      errorStyle: TextStyle(
                                        color: const Color(0xFFFF6B6B),
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 6)
                                        ? 'Min 6 characters'
                                        : null,
                                  ),
                                  SizedBox(height: s(16)),
                                  Text(
                                    'Confirm Password',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: s(13.5),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: s(8)),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Re-enter password',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: s(15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: s(14),
                                        vertical: s(16),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(color: blue),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: const BorderSide(
                                          color: Colors.red,
                                        ),
                                      ),
                                      errorStyle: TextStyle(
                                        color: const Color(0xFFFF6B6B),
                                        fontSize: s(12),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) {
                                        return 'Confirm password';
                                      }
                                      if (v != _passwordController.text) {
                                        return 'Passwords do not match';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: s(16)),
                                  Row(
                                    children: [
                                      Text(
                                        'Referral Code',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: s(13.5),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'Optional',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: s(12.5),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(8)),
                                  TextFormField(
                                    controller: _referralController,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: s(15),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter code',
                                      hintStyle: TextStyle(
                                        color: Colors.white38,
                                        fontSize: s(15),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(
                                        alpha: 0.06,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: s(14),
                                        vertical: s(16),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          s(14),
                                        ),
                                        borderSide: BorderSide(color: blue),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: s(14)),
                                  if (_error != null) ...[
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        color: const Color(0xFFFF6B6B),
                                        fontSize: s(13),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: s(10)),
                                  ],
                                  Text(
                                    'By creating an account, you agree to our ',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: s(12.5),
                                      fontWeight: FontWeight.w700,
                                      height: 1.35,
                                    ),
                                  ),
                                  Wrap(
                                    children: [
                                      Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: s(12.5),
                                          fontWeight: FontWeight.w800,
                                          height: 1.35,
                                        ),
                                      ),
                                      Text(
                                        ' and ',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: s(12.5),
                                          fontWeight: FontWeight.w700,
                                          height: 1.35,
                                        ),
                                      ),
                                      Text(
                                        'Privacy Policy.',
                                        style: TextStyle(
                                          color: blue,
                                          fontSize: s(12.5),
                                          fontWeight: FontWeight.w800,
                                          height: 1.35,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(18)),
                                  SizedBox(
                                    height: s(54),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _signup,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: blue,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            s(14),
                                          ),
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: s(16),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      child: const Text('Create Account'),
                                    ),
                                  ),
                                  SizedBox(height: s(18)),
                                  Center(
                                    child: Wrap(
                                      alignment: WrapAlignment.center,
                                      children: [
                                        Text(
                                          'Already a member? ',
                                          style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: s(13.5),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: _loading
                                              ? null
                                              : () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          const LoginPage(),
                                                    ),
                                                  );
                                                },
                                          child: Text(
                                            'Log in',
                                            style: TextStyle(
                                              color: blue,
                                              fontSize: s(13.5),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: s(12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  return SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight - media.viewInsets.bottom,
                      ),
                      child: content,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Email already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (min 6 chars)';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Email or password is incorrect';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'network-request-failed':
        return 'Network error, check your connection';
      default:
        final msg = e.message ?? '';
        if (msg.contains('Json conversion failed') ||
            msg.contains('<!DOCTYPE html>')) {
          return 'Network error. Please check your connection or VPN.';
        }
        return msg.isNotEmpty ? msg : 'Authentication error';
    }
  }

  String _friendlyFirestoreError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'Firestore permission denied. Update security rules to allow user writes.';
      case 'unavailable':
        return 'Firestore unavailable. Check your network.';
      default:
        return e.message ?? 'Firestore error';
    }
  }

  String _generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(8, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<T> _retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e) {
        debugPrint(
          'DEBUG: Operation failed (attempt $attempts/$maxAttempts): $e',
        );
        if (attempts >= maxAttempts) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
  }
}
