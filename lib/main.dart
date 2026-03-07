import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/background_service.dart';
import 'shared/constants.dart';
import 'services/coin_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'services/locale_provider.dart';

// This is the main entry point of the application.
// It initializes all necessary services and starts the app.
Future<void> main() async {
  // Ensure that the Flutter engine is initialized before running any code.
  WidgetsFlutterBinding.ensureInitialized();

  // Set the application mode to 'selector' (likely for choosing between admin/mobile or dev/prod modes).
  AppEntryConfig.mode = AppEntryMode.selector;

  // Initialize Firebase connection using the platform-specific options.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize App Check to verify app integrity
  // This is required because Firebase Storage has App Check enforcement enabled.
  if (!kIsWeb) {
    // You can also use a "Debug Token" in development to test App Check
    // This is required because Firebase Storage has App Check enforcement enabled.
    try {
      // Use the correct parameter names for the latest version
      await FirebaseAppCheck.instance.activate(
        // providerAndroid takes an AndroidAppCheckProvider instance
        providerAndroid: kDebugMode
            ? AndroidDebugProvider()
            : AndroidPlayIntegrityProvider(),

        // providerApple takes an AppleAppCheckProvider instance
        providerApple: kDebugMode
            ? AppleDebugProvider()
            : AppleDeviceCheckProvider(),
      );
      debugPrint('[Main] App Check activated successfully.');
      if (kDebugMode) {
        debugPrint(
          '========================================================================',
        );
        debugPrint('APP CHECK IS ENABLED IN DEBUG MODE');
        debugPrint(
          'Search your logs for "DebugAppCheckProvider" to find your debug secret.',
        );
        debugPrint(
          'Then add it to Firebase Console -> App Check -> Manage debug tokens.',
        );
        debugPrint(
          '========================================================================',
        );
      }
    } catch (e) {
      debugPrint('[Main] Failed to activate App Check: $e');
    }
  }

  // If the app is NOT running on the web (i.e., it's on mobile or desktop),
  // initialize background services like notifications and ads.
  if (!kIsWeb) {
    _initBackgroundServices();
  }

  // Load saved locale
  await localeProvider.load();

  // Run the main application widget.
  runApp(const MyApp());
}

// The root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Sets up the Material Design structure.
    return AnimatedBuilder(
      animation: localeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'ETA Network',

          // Apply the custom dark theme defined in AppTheme.
          theme: AppTheme.dark,
          locale: localeProvider.locale,

          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('es'), // Spanish
          ],

          // The starting screen is the AuthGate, which decides if the user is logged in or not.
          home: const AuthGate(),
        );
      },
    );
  }
}

// Helper function to initialize services that run in the background.
Future<void> _initBackgroundServices() async {
  try {
    // Initialize the notification service to handle push notifications.
    await NotificationService().init();

    // Ensure the device token is registered for notifications.
    await NotificationService().ensureTokenRegistered();

    // Initialize the advertising service.
    await AdsService().init();

    // Initialize other general background tasks.
    await BackgroundService.init();
    CoinService.init();
  } catch (_) {
    // If any service fails to start, catch the error silently so the app doesn't crash.
  }
}
