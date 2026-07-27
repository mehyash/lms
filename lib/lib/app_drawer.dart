import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'program_listing_screen.dart';
import 'messages_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'submissions_screen.dart';
import 'calendar_screen.dart';
import 'page_transitions.dart';

/// ---------------------------------------------------------------------
/// APP DRAWER DESTINATIONS
/// ---------------------------------------------------------------------
enum AppDrawerDestination {
  home,
  programs,
  submissions,
  calendar,
  messages,
  profile,
  settings,
  admin,
  curriculumAi,
}

/// ---------------------------------------------------------------------
/// APP DRAWER
/// ---------------------------------------------------------------------
class AppDrawer extends StatelessWidget {
  final AppDrawerDestination currentDestination;

  const AppDrawer({super.key, required this.currentDestination});

  static const _destinations = AppDrawerDestination.values;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexOf(currentDestination);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.15),
      child: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        children: [
          const _DrawerHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Divider(height: 1),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: Text('Home'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school_rounded),
            label: Text('Programs'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.upload_file_outlined),
            selectedIcon: Icon(Icons.upload_file_rounded),
            label: Text('Submissions'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded),
            label: Text('Calendar'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: Text('Messages'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: Text('Profile'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: Text('Settings'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings_rounded),
            label: Text('Admin Panel'),
          ),
          const NavigationDrawerDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: Text('Curriculum AI'),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Divider(height: 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              title: const Text(
                'Log out',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, int index) {
    final destination = _destinations[index];

    Navigator.pop(context);

    if (destination == currentDestination) return;

    switch (destination) {
      case AppDrawerDestination.home:
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case AppDrawerDestination.programs:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const ProgramListingScreen()),
        );
        break;

      case AppDrawerDestination.submissions:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const SubmissionsScreen()),
        );
        break;

      case AppDrawerDestination.calendar:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const CalendarScreen()),
        );
        break;

      case AppDrawerDestination.messages:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const MessagesScreen()),
        );
        break;

      case AppDrawerDestination.profile:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const ProfileScreen()),
        );
        break;

      case AppDrawerDestination.settings:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const SettingsScreen()),
        );
        break;

      case AppDrawerDestination.admin:
        Navigator.pushReplacementNamed(context, '/admin');
        break;

      case AppDrawerDestination.curriculumAi:
        Navigator.pushReplacementNamed(context, '/curriculum-ai');
        break;
    }
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Text(
            'Excelerate',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
