import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/session_provider.dart';
import '../providers/shell_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_drawer.dart';
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'doctors_screen.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final nav = context.watch<ShellController>();

    if (!session.isAuthenticated) {
      Future.microtask(() => Navigator.pushReplacementNamed(context, '/login'));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const ProfileDrawer(),
      body: PageView(
        controller: nav.pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: nav.setIndexSilently,
        children: const [
          HomeScreen(),
          DashboardScreen(),
          DoctorsScreen(),
          ChatScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: nav.currentIndex,
          onTap: nav.jumpToIndex,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.medical_services_rounded), label: 'Doctors'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'AI Assistant'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Analytics'),
          ],
        ),
      ),
    );
  }
}

