import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme.dart';
import 'core/app_state.dart';
import 'core/api_bridge.dart';
import 'features/login_screen.dart';
import 'features/app_layout.dart';
import 'features/teacher_dashboard_screen.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file (non-fatal if missing)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ .env file not found or failed to load: $e');
    // App will use default API_BASE_URL from ApiService
  }

  // Initialize API service (load saved auth token)
  await ApiBridge.init();

  // Force light system status bar style with white background
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const AdyapanApp(),
    ),
  );
}

class AdyapanApp extends StatelessWidget {
  const AdyapanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adyapan Smart Learning Ecosystem',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AdyapanTheme.blueAccent,
          background: AdyapanTheme.bgDark,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: Platform.isIOS ? '.SF Pro Text' : 'Outfit',
          bodyColor: AdyapanTheme.textMain,
          displayColor: AdyapanTheme.textMain,
        ),
      ),
      home: Consumer<AppState>(
        builder: (context, state, child) {
          if (!state.initialized) {
            return const Scaffold(
              backgroundColor: Color(0xFFFFFDF8),
              body: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                ),
              ),
            );
          }
          // Only show dashboard if user is logged in AND session is verified
          if (state.isLoggedIn && state.sessionVerified) {
            if (state.userRole == 'teacher') {
              return const TeacherDashboardScreen();
            }
            return const AppLayout();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
