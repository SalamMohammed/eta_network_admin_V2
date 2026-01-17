import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'shared/theme/app_theme.dart';
import 'auth/auth_gate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'services/notification_service.dart';
import 'services/ads_service.dart';
import 'shared/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEntryConfig.mode = AppEntryMode.mobile;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    await NotificationService().init();
    await NotificationService().ensureTokenRegistered();
    await AdsService().init();
  }

  runApp(const MyMobileApp());
}

class MyMobileApp extends StatelessWidget {
  const MyMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ETA Network',
      theme: AppTheme.dark,
      home: const AuthGate(),
    );
  }
}
