import 'model.dart';
import 'opportunities_preview.dart';

/// ---------------------------------------------------------------------
/// HOME SCREEN
/// ---------------------------------------------------------------------
/// This is the central hub of the app (as described in the Excelerate
/// App Proposal, Week 1 wireframes). It is reached AFTER a successful
/// login and shows three key sections:
///   1. Programs      -> quick access into the Program Listing flow
///   2. Announcements  -> simple feed, kept lightweight for now
///   3. Quick Links    -> shortcuts to frequently used actions
///
/// NOTE: This is FRONTEND ONLY. All data below is static/dummy data.
/// Backend/API integration (fetching real programs, announcements,
/// etc.) is scoped for next week's workload, per the task breakdown.
/// ---------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Opportunity? _activeProgram;
  bool _loadingProgress = true;
  List<Map<String, dynamic>> _announcements = [];
  bool _loadingAnnouncements = true;
  String _userName = 'Student';

  @override
  void initState() {
    super.initState();
    _checkRoleAndRedirect();
    _fetchUserData();
    _fetchActiveProgram();
    _fetchAnnouncements();
  }

  Future<void> _checkRoleAndRedirect() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final role = user.userMetadata?['role'];
    if (role == 'admin') {
      if (mounted) Navigator.pushReplacementNamed(context, '/admin');
      return;
    }

    // Fallback DB check
    try {
      final adminCheck = await Supabase.instance.client
          .from('Admins')
          .select()
          .ilike('Email', user.email!)
          .maybeSingle();

      if (adminCheck != null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/admin');
      }
    } catch (e) {
      debugPrint('Redirect check error: $e');
    }
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Try fetching from the 'students' table first
      final studentRes = await Supabase.instance.client
          .from('students')
          .select('first_name, last_name')
          .eq('id', user.id)
          .maybeSingle();

      if (studentRes != null && mounted) {
        setState(() {
          _userName = studentRes['first_name'] ?? 'Student';
        });
      } else {
        // 2. Fallback to Supabase Auth Metadata if table fetch fails
        final metadataName = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                             user.userMetadata?['first_name'];
        if (metadataName != null && mounted) {
          setState(() => _userName = metadataName);
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchAnnouncements() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch student's enrollments to filter announcements
      final enrollRes = await Supabase.instance.client
          .from('enrollments')
          .select('course_id')
          .eq('student_id', user.id);
      
      final List<int> enrolledCourseIds = (enrollRes as List).map((e) => e['course_id'] as int).toList();

      // Fetch announcements: broadcast (null) or student's courses
      var query = Supabase.instance.client.from('announcements').select();
      
      // Postgrest doesn't support complex OR in a single .filter call easily without 'or' filter string
      // But we can fetch and filter in memory since we're limiting to 3
      final res = await query.order('created_at', ascending: false);
      final List<Map<String, dynamic>> allAnnouncements = List<Map<String, dynamic>>.from(res);

      final filtered = allAnnouncements.where((a) {
        final cid = a['course_id'];
        return cid == null || enrolledCourseIds.contains(cid);
      }).take(3).toList();

      if (mounted) {
        setState(() {
          _announcements = filtered;
          _loadingAnnouncements = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      if (mounted) setState(() => _loadingAnnouncements = false);
    }
  }

  Future<void> _fetchActiveProgram() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final res = await Supabase.instance.client
          .from('enrollments')
          .select('*, Courses(*)')
          .eq('student_id', user.id)
          .eq('status', 'applied')
          .order('progress', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        final course = res['Courses'];
        IconData icon = Icons.school_outlined;
        Color color = Colors.blue;
        if (course['category'] == 'Power Skill Courses') {
          icon = Icons.bolt_rounded;
          color = Colors.green;
        } else if (course['category'] == 'Global Internships') {
          icon = Icons.public_rounded;
          color = Colors.indigo;
        }

        if (mounted) {
          setState(() {
            _activeProgram = Opportunity(
              name: course['courseName'] ?? 'Unnamed',
              category: course['category'] ?? 'General',
              scholarship: course['scholarship_amount'] ?? '\$0',
              icon: icon,
              iconBackground: color,
              skillIcons: const [],
              status: ProgramStatus.applied,
              progress: (res['progress'] ?? 0.0).toDouble(),
            );
            _loadingProgress = false;
          });
        }
      } else {
        if (mounted) setState(() => _loadingProgress = false);
      }
    } catch (e) {
      debugPrint('Error fetching active program: $e');
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'];

    // Integrity check: if admin, redirect to admin dashboard
    // We check metadata first, then database in the background if it's potentially an admin
    if (role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_userName'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.home),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, $_userName 👋',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const OpportunitiesPreview(),
              const SizedBox(height: 28),
              _buildSectionTitle('Current Program'),
              const SizedBox(height: 10),
              _buildProgramProgressCard(context),
              const SizedBox(height: 28),
              _buildSectionTitle('Announcements'),
              const SizedBox(height: 10),
              _buildAnnouncementsSection(),
              const SizedBox(height: 28),
              _buildSectionTitle('Quick Links'),
              const SizedBox(height: 10),
              _buildQuickLinksSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAnnouncementsSection() {
    if (_loadingAnnouncements) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_announcements.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text('No new announcements.', style: TextStyle(color: Colors.grey))),
      );
    }

    return Column(
      children: _announcements.map((a) {
        final DateTime createdAt = DateTime.parse(a['created_at']);
        final timeStr = "${createdAt.day}/${createdAt.month} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_outlined, size: 20, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a['content'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgramProgressCard(BuildContext context) {
    if (_loadingProgress) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_activeProgram == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'No ongoing programs yet — explore Programs to get started.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final program = _activeProgram!;
    final progress = program.progress ?? 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          fadeSlideRoute(const ProgramListingScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: program.iconBackground,
                  child: Icon(program.icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    program.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: In Progress',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksSection(BuildContext context) {
    final List<Map<String, dynamic>> quickLinks = [
      {'label': 'Dashboard', 'icon': Icons.dashboard_customize_outlined, 'route': '/dashboard'},
      {'label': 'Submissions', 'icon': Icons.upload_file, 'route': '/submissions'},
      {'label': 'Calendar', 'icon': Icons.calendar_today, 'route': '/calendar'},
      {'label': 'Messages', 'icon': Icons.chat_bubble_outline, 'route': '/messages'},
      {'label': 'Profile', 'icon': Icons.person_outline, 'route': '/profile'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: quickLinks.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final item = quickLinks[index];
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
             Navigator.pushNamed(context, item['route']);
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, size: 20),
                const SizedBox(width: 8),
                Text(item['label'] as String),
              ],
            ),
          ),
        );
      },
    );
  }
}
