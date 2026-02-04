import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  /// Checks for update availability and forces an immediate update if available.
  /// This only works on Android devices with Google Play Store installed.
  static Future<void> checkForUpdate() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        // We prioritize immediate (forced) updates
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        }
        // Fallback to flexible if immediate is not allowed but flexible is
        else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          // Note: We do not call completeFlexibleUpdate() immediately because the download
          // happens in the background. Calling it now would fail.
          // The Play Store handles the install prompt once downloaded.
        }
      }
    } catch (e) {
      // This is expected during development (app not on Play Store)
      debugPrint('In-app update check failed: $e');
    }
  }
}
