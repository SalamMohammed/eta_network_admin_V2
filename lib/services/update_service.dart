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
          // For flexible, we can choose to complete it immediately or let user decide.
          // For "Force" behavior, we might want to prompt user, but immediate is the standard force way.
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      // This is expected during development (app not on Play Store)
      debugPrint('In-app update check failed: $e');
    }
  }
}
