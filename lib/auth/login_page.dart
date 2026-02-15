import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../shared/theme/colors.dart';
import '../shared/firestore_constants.dart';
import '../utils/firestore_helper.dart';
import 'signup_page.dart';
import '../entry/selector_page.dart';
import '../firebase_options.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final bool goToSelectorAfterAuth;

  const LoginPage({super.key, this.goToSelectorAfterAuth = true});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

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

    final ref = FirestoreHelper.instance
        .collection(FirestoreConstants.users)
        .doc(user.uid);
    log(
      'INFO',
      'uid-flag',
      'ensureUserDocExists start',
      extra: {'uid': user.uid, 'path': ref.path},
    );
    final snap = await ref.get();
    if (snap.exists) {
      final data = snap.data() ?? {};
      final existingEmail = data[FirestoreUserFields.email] as String?;
      final existingUpdatedAt =
          data[FirestoreUserFields.updatedAt] as Timestamp?;
      final hasUidMigrationFinished =
          (data[FirestoreUserFields.uidMigrationCheckFinished] as bool?);

      bool needsUpdate = false;
      if (existingEmail != user.email) {
        needsUpdate = true;
      }

      if (!needsUpdate && existingUpdatedAt != null) {
        final diff = DateTime.now().difference(existingUpdatedAt.toDate());
        if (diff.inHours >= 24) needsUpdate = true;
      } else if (existingUpdatedAt == null) {
        needsUpdate = true;
      }

      if (needsUpdate) {
        try {
          log(
            'INFO',
            'uid-flag',
            'updating existing user metadata',
            extra: {'uid': user.uid},
          );
          await ref.set({
            FirestoreUserFields.email: user.email,
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          log(
            'INFO',
            'uid-flag',
            'updated existing user metadata',
            extra: {'uid': user.uid},
          );
        } on FirebaseException catch (fe, st) {
          log(
            'ERROR',
            'uid-flag',
            'failed updating existing user metadata',
            error:
                'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
            stack: st,
            extra: {'uid': user.uid},
          );
        } catch (e, st) {
          log(
            'ERROR',
            'uid-flag',
            'unexpected error updating user metadata',
            error: e,
            stack: st,
            extra: {'uid': user.uid},
          );
        }
      }
      // Ensure flag exists for existing users on first open/refresh
      if (hasUidMigrationFinished == null) {
        try {
          log(
            'INFO',
            'uid-flag',
            'backfilling uidMigrationCheckFinished=false',
            extra: {'uid': user.uid},
          );
          await ref.set({
            FirestoreUserFields.uidMigrationCheckFinished: false,
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          log(
            'INFO',
            'uid-flag',
            'backfilled uidMigrationCheckFinished=false',
            extra: {'uid': user.uid},
          );
        } on FirebaseException catch (fe, st) {
          log(
            'ERROR',
            'uid-flag',
            'failed backfilling uidMigrationCheckFinished',
            error:
                'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
            stack: st,
            extra: {'uid': user.uid},
          );
        } catch (e, st) {
          log(
            'ERROR',
            'uid-flag',
            'unexpected error backfilling uidMigrationCheckFinished',
            error: e,
            stack: st,
            extra: {'uid': user.uid},
          );
        }
      }
      return;
    }

    final email = user.email ?? '';
    final fallbackUsername = email.isNotEmpty
        ? email.split('@').first
        : user.uid.substring(0, 8);
    final username = (user.displayName ?? '').trim().isEmpty
        ? fallbackUsername
        : user.displayName!.trim();

    try {
      log(
        'INFO',
        'uid-flag',
        'creating new user doc with uidMigrationCheckFinished=false',
        extra: {'uid': user.uid},
      );
      await ref.set({
        FirestoreUserFields.uid: user.uid,
        FirestoreUserFields.email: email,
        FirestoreUserFields.username: username,
        FirestoreUserFields.uidMigrationCheckFinished: false,
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
      log('INFO', 'uid-flag', 'created new user doc', extra: {'uid': user.uid});
    } on FirebaseException catch (fe, st) {
      log(
        'ERROR',
        'uid-flag',
        'failed creating new user doc',
        error: 'code=${fe.code}, plugin=${fe.plugin}, message=${fe.message}',
        stack: st,
        extra: {'uid': user.uid},
      );
      rethrow;
    } catch (e, st) {
      log(
        'ERROR',
        'uid-flag',
        'unexpected error creating new user doc',
        error: e,
        stack: st,
        extra: {'uid': user.uid},
      );
      rethrow;
    }
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
      if (mounted && widget.goToSelectorAfterAuth) {
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
          if (mounted) {
            setState(() {
              _loading = false;
            });
          }
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

      if (mounted && widget.goToSelectorAfterAuth) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SelectorPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _friendlyAuthError(e);
      });
    } catch (e) {
      setState(() {
        _error = 'Google sign-in failed: ${e.toString().split('\n').first}';
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
    final blue = const Color(0xFF1B4BFF);
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final base = (w < h ? w : h);
    final tScale =
        (base / 390.0).clamp(0.82, 1.12) * (h / 820.0).clamp(0.75, 1.0);
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
                                      'Login',
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
                            SizedBox(height: s(22)),
                            Center(
                              child: Container(
                                width: s(56),
                                height: s(56),
                                decoration: BoxDecoration(
                                  color: blue,
                                  borderRadius: BorderRadius.circular(s(16)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: blue.withValues(alpha: 0.35),
                                      blurRadius: s(20),
                                      offset: Offset(0, s(10)),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.diamond_rounded,
                                  color: Colors.white,
                                  size: s(30),
                                ),
                              ),
                            ),
                            SizedBox(height: s(18)),
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: s(32),
                                fontWeight: FontWeight.w900,
                                height: 1.06,
                              ),
                            ),
                            SizedBox(height: s(8)),
                            Text(
                              'Manage your mining and ETA \nsecurely.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: s(14.5),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: s(20)),
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Email Address',
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
                                      hintText: 'Enter password',
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
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? 'Password required'
                                        : null,
                                  ),
                                  SizedBox(height: s(10)),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ForgotPasswordPage(),
                                                ),
                                              );
                                            },
                                      style: TextButton.styleFrom(
                                        foregroundColor: blue,
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: s(13.5),
                                          fontWeight: FontWeight.w800,
                                        ),
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
                                  SizedBox(
                                    height: s(54),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
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
                                      child: const Text('Sign In'),
                                    ),
                                  ),
                                  SizedBox(height: s(18)),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: s(12),
                                        ),
                                        child: Text(
                                          'OR',
                                          style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: s(12.5),
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          height: 1,
                                          color: Colors.white.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: s(18)),
                                  SizedBox(
                                    height: s(54),
                                    child: OutlinedButton(
                                      onPressed: _loading
                                          ? null
                                          : _loginWithGoogle,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                        ),
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.05),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            s(14),
                                          ),
                                        ),
                                        textStyle: TextStyle(
                                          fontSize: s(15),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: s(20),
                                            height: s(20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(s(6)),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              'G',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: s(13),
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: s(10)),
                                          const Text('Continue with Google'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: s(18)),
                            Center(
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  Text(
                                    'New to ETA? ',
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
                                                builder: (_) => SignupPage(
                                                  goToSelectorAfterAuth: widget
                                                      .goToSelectorAfterAuth,
                                                ),
                                              ),
                                            );
                                          },
                                    child: Text(
                                      'Register here',
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
}
