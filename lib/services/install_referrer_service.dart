import 'dart:io';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstallReferrerService {
  static const String _prefsKey = 'referral_code_from_install';

  /// Initializes the listener for install referrer.
  /// Should be called on app startup.
  static Future<void> init() async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final prefs = await SharedPreferences.getInstance();

      // If we already captured it, no need to check again.
      if (prefs.containsKey(_prefsKey)) return;

      final referrerDetails = await PlayInstallReferrer.installReferrer;

      if (referrerDetails.installReferrer != null) {
        String referrerUrl = referrerDetails.installReferrer!;
        debugPrint('Install Referrer URL: $referrerUrl');

        // The referrer string is typically URL-encoded parameters, e.g.,
        // "utm_source=test_source&utm_medium=test_medium"
        // We prepend '?' to parse it easily with Uri.
        if (!referrerUrl.startsWith('?')) {
          referrerUrl = '?$referrerUrl';
        }

        final uri = Uri.tryParse(referrerUrl);
        if (uri != null) {
          final source = uri.queryParameters['utm_source'];
          if (source != null && source.isNotEmpty) {
            await prefs.setString(_prefsKey, source);
            debugPrint('Captured referral code from install: $source');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get install referrer: $e');
    }
  }

  /// Retrieves the captured referral code, if any.
  static Future<String?> getCapturedReferralCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefsKey);
  }
}
