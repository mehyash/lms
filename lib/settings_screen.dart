import 'model.dart';
import 'account_settings_screen.dart';
import 'email_preferences_screen.dart';
import 'appearance_screen.dart';
import 'experiential_record_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchName();
  }

  Future<void> _fetchName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'User';
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();
      if (res != null && res['first_name'] != null) name = res['first_name'];
    } catch (_) {}
    if (mounted) setState(() => _userName = name);
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'] ?? 'student';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_userName'),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(
                context,
                role == 'admin' ? '/admin' : '/home',
              );
            }
          },
        ),
      ),
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
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
