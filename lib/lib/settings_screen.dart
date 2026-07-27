import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'page_transitions.dart';
import 'account_settings_screen.dart';
import 'email_preferences_screen.dart';
import 'appearance_screen.dart';
import 'experiential_record_screen.dart';

/// ---------------------------------------------------------------------
/// SETTINGS SCREEN
/// ---------------------------------------------------------------------
/// Reached from the drawer's "Settings" destination. Hosts the
/// account/app-level settings that don't belong on the Profile page:
///   - Account Settings        (change password, delete account —
///                               moved here from Profile)
///   - Email Preferences       (which emails the user receives)
///   - Appearance              (Light Mode / Dark Mode)
///   - My Experiential Record  (which fields appear on the public
///                               experiential record + its visibility)
///
/// Frontend only — each sub-screen uses static/dummy data except
/// Appearance, which is fully functional (see ThemeController).
/// ---------------------------------------------------------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), centerTitle: false),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.settings),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Manage your account, preferences, and how Excelerate looks.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            _buildMenuCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final items = [
      _SettingsMenuItem(
        icon: Icons.admin_panel_settings_outlined,
        label: 'Account Settings',
        subtitle: 'Password & account deletion',
        onTap: () => Navigator.push(context, fadeSlideRoute(const AccountSettingsScreen())),
      ),
      _SettingsMenuItem(
        icon: Icons.mail_outline_rounded,
        label: 'Email Preferences',
        subtitle: 'Choose the emails you receive',
        onTap: () => Navigator.push(context, fadeSlideRoute(const EmailPreferencesScreen())),
      ),
      _SettingsMenuItem(
        icon: Icons.dark_mode_outlined,
        label: 'Appearance',
        subtitle: 'Light Mode or Dark Mode',
        onTap: () => Navigator.push(context, fadeSlideRoute(const AppearanceScreen())),
      ),
      _SettingsMenuItem(
        icon: Icons.file_download_outlined,
        label: 'My Experiential Record',
        subtitle: 'What appears on your record',
        onTap: () => Navigator.push(context, fadeSlideRoute(const ExperientialRecordScreen())),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(
              children: [
                ListTile(
                  onTap: item.onTap,
                  leading: Icon(item.icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(item.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(item.subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ),
                if (i != items.length - 1)
                  Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade200),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _SettingsMenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  _SettingsMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}
