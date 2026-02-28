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
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/fallback_localization_delegate.dart';
import 'services/locale_provider.dart';

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

  // Load saved locale
  await localeProvider.load();

  // Run the mobile-specific app widget.
  runApp(const MyMobileApp());
}

// The root widget for the mobile application.
class MyMobileApp extends StatelessWidget {
  const MyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: localeProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'ETA Network',

          // Apply dark theme.
          theme: AppTheme.dark,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FallbackMaterialLocalizationsDelegate(),
            FallbackCupertinoLocalizationsDelegate(),
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('es'), // Spanish
            Locale('zh'), // Chinese (Simplified)
            Locale.fromSubtags(
              languageCode: 'zh',
              scriptCode: 'Hant',
            ), // Chinese (Traditional)
            Locale('hi'), // Hindi
            Locale('vi'), // Vietnamese
            Locale('ms'), // Malay
            Locale('ko'), // Korean
            Locale('tr'), // Turkish
            Locale('pt'), // Portuguese
            Locale('ar'), // Arabic
            Locale('id'), // Indonesian
            Locale('fr'), // French
            Locale('de'), // German
            Locale('my'), // Burmese
            Locale('te'), // Telugu
            Locale('ne'), // Nepali
            Locale('bn'), // Bengali
            Locale('mr'), // Marathi
            Locale('ta'), // Tamil
            Locale('pa'), // Punjabi
            Locale('ur'), // Urdu
            Locale('th'), // Thai
            Locale('ru'), // Russian
            Locale('it'), // Italian
            Locale('tl'), // Tagalog
            Locale('ja'), // Japanese
            Locale('ps'), // Pashto
            Locale('yo'), // Yoruba
            Locale('ff'), // Fulfulde
            Locale('ha'), // Hausa
            Locale('ig'), // Igbo
            Locale('fa'), // Persian
            Locale('pcm'), // Pidgin English
          ],

          // Start at the AuthGate to check login status.
          home: const AuthGate(),
        );
      },
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
