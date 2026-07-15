import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GreenResApp());
}

class GreenResApp extends StatelessWidget {
  const GreenResApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GreenRes Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.base,
      home: const SplashScreen(),
    );
  }
}
