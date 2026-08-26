import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_view.dart';
import 'services/app_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase.initializeApp exception caught: $e');
  }

  // Initialize theme and system settings asynchronously
  AppSettingsService.initialize();

  runApp(const PMSAdminApp());
}

class PMSAdminApp extends StatelessWidget {
  const PMSAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppSettingsService.themeModeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: 'PMS Admin Console',
          debugShowCheckedModeBanner: false,
          themeMode: currentThemeMode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1E3A8A),
              brightness: Brightness.light,
              primary: const Color(0xFF1E3A8A),
              surface: Colors.white,
              surfaceContainerLow: Colors.white,
              surfaceContainerHighest: const Color(0xFFF1F5F9),
              outline: const Color(0xFF64748B),
              outlineVariant: const Color(0xFFE2E8F0),
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B82F6),
              brightness: Brightness.dark,
              primary: const Color(0xFF3B82F6),
              surface: const Color(0xFF1E293B),
              surfaceContainerLow: const Color(0xFF1E293B),
              surfaceContainerHighest: const Color(0xFF334155),
              outline: const Color(0xFF94A3B8),
              outlineVariant: const Color(0xFF334155),
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155)),
              ),
            ),
            fontFamily: 'Roboto',
          ),
          home: const LoginView(),
        );
      },
    );
  }
}
