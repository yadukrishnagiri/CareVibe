import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/shell_controller.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';

class ProfileDrawer extends StatefulWidget {
  const ProfileDrawer({super.key});

  @override
  State<ProfileDrawer> createState() => _ProfileDrawerState();
}

class _ProfileDrawerState extends State<ProfileDrawer> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final user = session.firebaseUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: AppColors.primary, child: Icon(Icons.person, color: Colors.white, size: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.displayName ?? 'Guest', style: Theme.of(context).textTheme.titleMedium),
                        Text(user?.email ?? '', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/profile-setup');
              },
            ),
            SwitchListTile(
              value: context.watch<ThemeProvider>().isDark,
              onChanged: (value) {
                context.read<ThemeProvider>().toggle(value);
              },
              secondary: const Icon(Icons.nightlight_round),
              title: const Text('Dark mode'),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Security settings'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings coming soon.')),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await AuthProvider(session).signOut();
                  context.read<ShellController>().setIndexSilently(0);
                  if (!mounted) return;
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

