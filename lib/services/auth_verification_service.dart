import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

class AuthVerificationService {
  static ActionCodeSettings _settings() {
    final url = 'https://etanetwork.net/verified/';
    return ActionCodeSettings(
      url: url,
      handleCodeInApp: false,
      androidPackageName: 'com.eta.network',
      androidInstallApp: true,
      iOSBundleId: DefaultFirebaseOptions.ios.iosBundleId,
    );
  }

  static Future<void> sendVerificationEmail() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try {
      await u.sendEmailVerification(_settings());
    } catch (_) {}
  }

  static Future<bool> refreshAndCheckVerified() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return false;
    try {
      await u.reload();
    } catch (_) {}
    final fresh = FirebaseAuth.instance.currentUser;
    return fresh?.emailVerified ?? false;
  }

  static bool get isVerified {
    final u = FirebaseAuth.instance.currentUser;
    return u?.emailVerified ?? false;
  }
}
