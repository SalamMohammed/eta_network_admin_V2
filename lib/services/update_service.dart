import 'package:in_app_update/in_app_update.dart';
import 'package:flutter/foundation.dart';

class UpdateService {
  /// Checks for update availability and forces an immediate update if available.
  /// This only works on Android devices with Google Play Store installed.
  static Future<void> checkForUpdate() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final info = await InAppUpdate.checkForUpdate();

      if (info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress) {
        // We prioritize immediate (forced) updates.
        // This blocks the UI until the update is complete.
        try {
          await InAppUpdate.performImmediateUpdate();
        } catch (e) {
          debugPrint('Immediate update failed: $e');
        }
      }
    } catch (e) {
      // This is expected during development (app not on Play Store or signature mismatch)
      debugPrint('In-app update check failed: $e');
    }
  }
}
