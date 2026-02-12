import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/install_referrer_service.dart';
import 'shared/constants.dart';

// This is the main entry point specifically for the Mobile version of the app.
Future<void> main() async {
  // Ensure the Flutter engine is ready.
  WidgetsFlutterBinding.ensureInitialized();

  // Set the application mode to 'mobile'.
  AppEntryConfig.mode = AppEntryMode.mobile;

  // Connect to Firebase.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize background services if not on web.
  if (!kIsWeb) {
    await _initBackgroundServices();
  }

  // Run the mobile-specific app widget.
  runApp(const MyMobileApp());
}

// The root widget for the mobile application.
class MyMobileApp extends StatelessWidget {
  const MyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETA Network',
      
      // Apply dark theme.
      theme: AppTheme.dark,
      
      // Start at the AuthGate to check login status.
      home: const AuthGate(),
    );
  }
}

// Initialize services needed for the mobile app background operations.
Future<void> _initBackgroundServices() async {
  try {
    // Track where the installation came from (e.g., Play Store referral).
    await InstallReferrerService.init();
    
    // Setup push notifications.
    await NotificationService().init();
    await NotificationService().ensureTokenRegistered();
    
    // Setup ads.
    await AdsService().init();
  } catch (_) {
    // Silently ignore initialization errors to keep the app running.
  }
}
