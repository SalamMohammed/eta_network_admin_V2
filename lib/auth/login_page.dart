import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../shared/theme/colors.dart';
import 'signup_page.dart';
import '../entry/selector_page.dart';

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
