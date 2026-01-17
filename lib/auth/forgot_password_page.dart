import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/theme/colors.dart';
import '../firebase_options.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return 'Email required';
    }
    if (!v.contains('@') || !v.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });
    try {
      final email = _emailController.text.trim();
      final settings = ActionCodeSettings(
        url: 'https://etanetwork.net/reset-password/',
        handleCodeInApp: false,
        androidPackageName: 'com.eta.network',
        androidInstallApp: true,
        iOSBundleId: DefaultFirebaseOptions.ios.iosBundleId,
      );
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: settings,
      );
      setState(() {
        _info = 'If an account exists, a reset email has been sent.';
      });
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-email':
          msg = 'Enter a valid email address';
          break;
        default:
          msg = 'Unable to send reset email. Try again later.';
      }
      setState(() {
        _error = msg;
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to send reset email. Try again later.';
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
    final media = MediaQuery.of(context);
    final w = media.size.width;
    final h = media.size.height;
    final base = w < h ? w : h;
    final tScale =
        (base / 390.0).clamp(0.82, 1.12) * (h / 820.0).clamp(0.75, 1.0);
    double s(double v) => v * tScale;

    final blue = const Color(0xFF1B4BFF);

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
                                      'Reset Password',
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
                                  Icons.lock_reset_rounded,
                                  color: Colors.white,
                                  size: s(30),
                                ),
                              ),
                            ),
                            SizedBox(height: s(18)),
                            Text(
                              'Forgot your password?',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: s(24),
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                              ),
                            ),
                            SizedBox(height: s(8)),
                            Text(
                              'Enter your email and we will send you a link to reset it.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: s(14.5),
                                fontWeight: FontWeight.w700,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: s(24)),
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
                                    validator: _validateEmail,
                                  ),
                                  SizedBox(height: s(18)),
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
                                  if (_info != null) ...[
                                    Text(
                                      _info!,
                                      style: TextStyle(
                                        color: const Color(0xFF4CD964),
                                        fontSize: s(13),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    SizedBox(height: s(10)),
                                  ],
                                  SizedBox(
                                    height: s(54),
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
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
                                      child: const Text('Send reset link'),
                                    ),
                                  ),
                                  SizedBox(height: s(16)),
                                  Center(
                                    child: TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () => Navigator.of(context).pop(),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white70,
                                      ),
                                      child: Text(
                                        'Back to login',
                                        style: TextStyle(
                                          fontSize: s(13.5),
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
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
}
