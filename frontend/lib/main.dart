import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'providers/shell_controller.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ShellController()),
      ],
      child: const CareVibeApp(),
    ),
  );
}

class CareVibeApp extends StatelessWidget {
  const CareVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareVibe',
      theme: AppTheme.light(),
      home: const AuthGate(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/shell': (_) => const MainShell(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (session.isAuthenticated) {
      return const MainShell();
    }

    if (firebaseUser != null) {
      // User is signed in with Firebase but backend token missing; show login to refresh.
      return const LoginScreen();
    }

    return const LoginScreen();
  }
}
