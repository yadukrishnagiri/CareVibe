import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'providers/shell_controller.dart';
import 'providers/chat_context_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/profile_setup_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/medications_screen.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notification service
  try {
    await NotificationService().initialize();
  } catch (e) {
    // Notification service initialization failed, continue anyway
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ShellController()),
        ChangeNotifierProvider(create: (_) => ChatContextProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProxyProvider<SessionProvider, ProfileProvider>(
          create: (ctx) => ProfileProvider(ctx.read<SessionProvider>()),
          update: (ctx, session, previous) => ProfileProvider(session),
        ),
      ],
      child: const CareVibeApp(),
    ),
  );
}

class CareVibeApp extends StatelessWidget {
  const CareVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareVibe',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: theme.mode,
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/shell': (_) => const MainShell(),
        '/profile-setup': (_) => const ProfileSetupScreen(),
        '/medications': (_) => const MedicationsScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final profile = context.watch<ProfileProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (session.isAuthenticated) {
      // Require profile completion
      if (!profile.isComplete) {
        // Trigger profile load if not loaded
        if (!profile.loading && profile.profile == null) {
          // ignore: discarded_futures
          profile.load();
        }
        return const ProfileSetupScreen();
      }
      return const MainShell();
    }

    if (firebaseUser != null) {
      // User is signed in with Firebase but backend token missing; show login to refresh.
      return const LoginScreen();
    }

    return const LoginScreen();
  }
}
