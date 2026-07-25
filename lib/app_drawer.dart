import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'program_listing_screen.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'page_transitions.dart';

/// ---------------------------------------------------------------------
/// APP DRAWER DESTINATIONS
/// ---------------------------------------------------------------------
/// Used by every screen that hosts the drawer to tell AppDrawer which
/// item is currently active, so it can be highlighted.
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
}

/// ---------------------------------------------------------------------
/// APP DRAWER  (Material 3 NavigationDrawer)
/// ---------------------------------------------------------------------
/// Shared, reusable navigation drawer opened via the hamburger icon in
/// the AppBar (wired automatically by Scaffold whenever a `drawer:` is
/// supplied). Only Home and Programs are functional this sprint —
/// everything else is intentionally inert and marked with TODOs for
/// future teams, per this week's scope.
/// ---------------------------------------------------------------------
class AppDrawer extends StatelessWidget {
  final AppDrawerDestination currentDestination;

  const AppDrawer({super.key, required this.currentDestination});

  static const _destinations = AppDrawerDestination.values;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _destinations.indexOf(currentDestination);

    // Wrapping in a Material with an explicit rounded shape + subtle
    // elevation keeps the drawer feeling minimal/modern (rounded corners,
    // soft shadow) without touching Flutter's built-in Material 3 slide
    // animation, which NavigationDrawer already provides out of the box
    // whenever it's opened via Scaffold's `drawer:` property.
    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.15),
      child: NavigationDrawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        // Consistent horizontal padding for every destination row,
        // matching Material 3 drawer spec.
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
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
              ),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
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

    // Always close the drawer first regardless of destination.
    Navigator.pop(context);

    // Don't re-navigate if the user tapped the page they're already on.
    if (destination == currentDestination) return;

    switch (destination) {
      case AppDrawerDestination.home:
        // pushReplacementNamed so repeated Home <-> Programs navigation
        // via the drawer doesn't pile up duplicate screens on the stack.
        Navigator.pushReplacementNamed(context, '/home');
        break;

      case AppDrawerDestination.programs:
        Navigator.pushReplacement(
          context,
          fadeSlideRoute(const ProgramListingScreen()),
        );
        break;

      case AppDrawerDestination.submissions:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;

      case AppDrawerDestination.calendar:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;

      case AppDrawerDestination.messages:
        // TODO (Future Team):
        // Implement navigation and functionality for the Messages module.
        break;

      case AppDrawerDestination.profile:
        // TODO (Future Team):
        // Implement navigation and functionality for the Profile module.
        break;

      case AppDrawerDestination.settings:
        // TODO (Future Team):
        // Implement navigation and functionality for the Settings module.
        break;

      case AppDrawerDestination.admin:
        Navigator.pushReplacementNamed(context, '/admin');
        break;
    }
  }
}

/// Small branded header at the top of the drawer. Reuses the app's
/// existing color scheme instead of introducing new branding.
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
