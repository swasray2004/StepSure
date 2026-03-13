import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'presentation/providers/session_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'core/constants/app_colors.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'data/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();

  // Initialize notifications and schedule default daily reminder at 8:00 AM
  await NotificationService.initialize();
  await NotificationService.scheduleDailyReminder(hour: 8, minute: 0);

  await Supabase.initialize(
    url: 'https://kbwpnxdrdevaytwgyrte.supabase.co',
    anonKey: 'sb_publishable_8B_r3ptSd6bch5HYNcwrMg_h29HxFuH',
  );

  runApp(const GaitRehabApp());
}

class GaitRehabApp extends StatelessWidget {
  const GaitRehabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
      ],
      child: MaterialApp(
        title: 'Gait Rehab AI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
        ),
        home: SplashScreen(
          next: const AuthGate(),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        return session != null ? HomeScreen() : const LoginScreen();
      },
    );
  }
}
