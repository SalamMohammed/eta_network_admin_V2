import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'services/background_service.dart';
import 'shared/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEntryConfig.mode = AppEntryMode.selector;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    _initBackgroundServices();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETA Network',
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}

Future<void> _initBackgroundServices() async {
  try {
    await NotificationService().init();
    await NotificationService().ensureTokenRegistered();
    await AdsService().init();
    await BackgroundService.init();
  } catch (_) {}
}
