import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/theme/colors.dart';
import '../shared/firestore_constants.dart';
import 'login_page.dart';
import '../entry/selector_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});
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

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = cred.user!.uid;
      await FirebaseFirestore.instance
          .collection(FirestoreConstants.users)
          .doc(uid)
          .set({
            FirestoreUserFields.email: cred.user!.email,
            FirestoreUserFields.role: FirestoreUserRoles.free,
            FirestoreUserFields.createdAt: FieldValue.serverTimestamp(),
            FirestoreUserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

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
                            'Register',
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
                              labelText: 'Password (min 6 chars)',
                            ),
                            obscureText: true,
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Min 6 characters'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                            ),
                            obscureText: true,
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
                              onPressed: _loading ? null : _signup,
                              child: const Text('Create account'),
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
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                            child: const Text('Already have an account? Login'),
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
      case 'network-request-failed':
        return 'Network error, check your connection';
      default:
        return e.message ?? 'Authentication error';
    }
  }
}
