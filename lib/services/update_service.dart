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
        // We prioritize immediate (forced) updates.
        // In version 4.x, we don't have explicit immediateUpdateAllowed flags,
        // so we attempt the update if available.
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (e) {
          // If immediate update fails or is not allowed, try flexible
          try {
            await InAppUpdate.startFlexibleUpdate();
          } catch (_) {
            // Both failed, nothing to do
          }
        }
      }
    } catch (e) {
      // This is expected during development (app not on Play Store)
      debugPrint('In-app update check failed: $e');
    }
  }
}
