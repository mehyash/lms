import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'page_transitions.dart';
import 'personal_information_screen.dart';
import 'educational_information_screen.dart';

/// ---------------------------------------------------------------------
/// PROFILE SCREEN
/// ---------------------------------------------------------------------
/// The Profile hub, reached from the drawer's "Profile" destination and
/// the Home "Quick Links -> Profile" shortcut. Shows the signed-in
/// user's identity card plus a menu of editable sections that each open
/// their own screen.
///
/// Per this sprint's scope, only two sections are included on Profile —
/// Personal Information and Educational Information. Account Settings
/// now lives on the Settings page (see settings_screen.dart) instead.
/// Opportunity Provider, My Interests, My Experiential Record, and
/// Email Preferences are intentionally left off Profile too — My
/// Experiential Record and Email Preferences now live on Settings.
///
/// Frontend only — identity + section data is static/dummy for now.
/// ---------------------------------------------------------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Dummy signed-in user — will be replaced by real auth/profile data
  // once the backend is wired up.
  static const _name = 'Haasini Kunamneni';
  static const _role = 'Student';
  static const _email = 'haasini.kunamneni@example.com';
  static const _phone = '+91 90000 00000';
  static const _location = 'Hyderabad, India';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: false),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.profile),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildIdentityCard(context),
            const SizedBox(height: 20),
            _buildMenuCard(context),
            const SizedBox(height: 24),
            _buildSignOutButton(context),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primary, primary.withOpacity(0.6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Role: $_role', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),
          _identityRow(Icons.email_outlined, 'Email', _email),
          const SizedBox(height: 10),
          _identityRow(Icons.phone_outlined, 'Phone', _phone),
          const SizedBox(height: 10),
          _identityRow(Icons.location_on_outlined, 'Location', _location),
        ],
      ),
    );
  }

  Widget _identityRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text('$label: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final items = [
      _ProfileMenuItem(
        icon: Icons.person_outline_rounded,
        label: 'Personal Information',
        onTap: () => Navigator.push(context, fadeSlideRoute(const PersonalInformationScreen())),
      ),
      _ProfileMenuItem(
        icon: Icons.school_outlined,
        label: 'Educational Information',
        onTap: () => Navigator.push(context, fadeSlideRoute(const EducationalInformationScreen())),
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

  Widget _buildSignOutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          // Clears the nav stack back to Login so the back button can't
          // return into the app after signing out.
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign out'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _ProfileMenuItem({required this.icon, required this.label, required this.onTap});
}
