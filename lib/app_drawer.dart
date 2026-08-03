import 'model.dart';

/// ---------------------------------------------------------------------
/// APP DRAWER DESTINATIONS
/// ---------------------------------------------------------------------
enum AppDrawerDestination {
  home,
  dashboard,
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

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'student';

    // Define all possible destinations
    final List<_DrawerItem> allItems = [
      _DrawerItem(
        destination: AppDrawerDestination.home,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: 'Home',
        roles: ['student'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.dashboard,
        icon: Icons.dashboard_customize_outlined,
        selectedIcon: Icons.dashboard_customize_rounded,
        label: 'My Dashboard',
        roles: ['student'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.admin,
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings_rounded,
        label: 'Admin Dashboard',
        roles: ['admin'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.programs,
        icon: Icons.school_outlined,
        selectedIcon: Icons.school_rounded,
        label: 'Programs',
        roles: ['student'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.submissions,
        icon: Icons.upload_file_outlined,
        selectedIcon: Icons.upload_file_rounded,
        label: 'Submissions',
        roles: ['student'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.calendar,
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today_rounded,
        label: 'Calendar',
        roles: ['student'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.messages,
        icon: Icons.chat_bubble_outline_rounded,
        selectedIcon: Icons.chat_bubble_rounded,
        label: 'Messages',
        roles: ['student', 'admin'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.curriculumAi,
        icon: Icons.auto_awesome_outlined,
        selectedIcon: Icons.auto_awesome,
        label: 'Curriculum AI',
        roles: ['admin'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.profile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
        label: 'Profile',
        roles: ['student', 'admin'],
      ),
      _DrawerItem(
        destination: AppDrawerDestination.settings,
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: 'Settings',
        roles: ['student', 'admin'],
      ),
    ];

    // Filter items based on user role
    final List<_DrawerItem> filteredItems = allItems.where((item) => item.roles.contains(role)).toList();
    
    // Find index of current destination in filtered list
    final selectedIndex = filteredItems.indexWhere((item) => item.destination == currentDestination);

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
      ),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: NavigationDrawer(
        selectedIndex: selectedIndex != -1 ? selectedIndex : null,
        onDestinationSelected: (index) => _onDestinationSelected(context, filteredItems[index].destination),
        children: [
          const _DrawerHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Divider(height: 1),
          ),
          ...filteredItems.map((item) => NavigationDrawerDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: Text(item.label),
              )),
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
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                }
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _onDestinationSelected(BuildContext context, AppDrawerDestination destination) {
    Navigator.pop(context);

    if (destination == currentDestination) return;

    switch (destination) {
      case AppDrawerDestination.home:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case AppDrawerDestination.dashboard:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case AppDrawerDestination.programs:
        Navigator.pushReplacement(context, fadeSlideRoute(const ProgramListingScreen()));
        break;
      case AppDrawerDestination.submissions:
        Navigator.pushReplacement(context, fadeSlideRoute(const SubmissionsScreen()));
        break;
      case AppDrawerDestination.calendar:
        Navigator.pushReplacement(context, fadeSlideRoute(const CalendarScreen()));
        break;
      case AppDrawerDestination.messages:
        Navigator.pushReplacement(context, fadeSlideRoute(const MessagesScreen()));
        break;
      case AppDrawerDestination.profile:
        Navigator.pushReplacement(context, fadeSlideRoute(const ProfileScreen()));
        break;
      case AppDrawerDestination.settings:
        Navigator.pushReplacement(context, fadeSlideRoute(const SettingsScreen()));
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

class _DrawerItem {
  final AppDrawerDestination destination;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final List<String> roles;

  _DrawerItem({
    required this.destination,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.roles,
  });
}

class _DrawerHeader extends StatefulWidget {
  const _DrawerHeader();

  @override
  State<_DrawerHeader> createState() => _DrawerHeaderState();
}

class _DrawerHeaderState extends State<_DrawerHeader> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Fallback name from metadata
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'User';

    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();
      if (res != null && res['first_name'] != null) {
        name = res['first_name'];
      }
    } catch (_) {}

    if (mounted) setState(() => _userName = name);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'Student';
    final email = user?.email ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Hi, $_userName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            role.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
