import 'model.dart';
import 'program_details_screen.dart';

/// ---------------------------------------------------------------------
/// PROGRAM LISTING SCREEN
/// ---------------------------------------------------------------------
/// Full catalog of programs/internships, split into three tabs:
///   - Available        -> not yet applied to
///   - Applied/Ongoing  -> in progress, shows a progress bar
///   - Completed        -> finished, shows a "Completed" badge
///
/// Frontend only — filtering happens on the dummy dataset. Real
/// filtering/search will move server-side once backend is ready.
///
/// UX/animation details:
///   - TabBar with animated indicator + icon+label tabs
///   - Search bar that animates its clear (X) button in/out
///   - Each card animates in with a staggered fade+slide on tab change
///   - Pull-to-refresh (RefreshIndicator) for a native, interactive feel
///   - AnimatedSwitcher for the "no results" empty state
/// ---------------------------------------------------------------------
class ProgramListingScreen extends StatefulWidget {
  const ProgramListingScreen({super.key});

  @override
  State<ProgramListingScreen> createState() => _ProgramListingScreenState();
}

class _ProgramListingScreenState extends State<ProgramListingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<Opportunity> _allOpportunities = [];
  bool _isLoading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _fetchName();
    _fetchPrograms();
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

  Future<void> _fetchPrograms() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('Fetching programs for user: ${user?.id}');
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 1. Fetch all courses
      final coursesRes = await Supabase.instance.client.from('Courses').select();
      final List<dynamic> coursesData = coursesRes as List<dynamic>;
      debugPrint('Fetched ${coursesData.length} courses: $coursesData');

      // 2. Fetch current user's enrollments
      final enrollmentsRes = await Supabase.instance.client
          .from('enrollments')
          .select()
          .eq('student_id', user.id);
      final List<dynamic> enrollmentsData = enrollmentsRes as List<dynamic>;
      debugPrint('Fetched ${enrollmentsData.length} enrollments for user ${user.id}: $enrollmentsData');

      // 3. Map to Opportunity objects
      final List<Opportunity> mapped = coursesData.map((course) {
        final courseId = course['id'].toString();
        
        // Find enrollment if it exists
        Map<String, dynamic>? enrollment;
        for (var e in enrollmentsData) {
          if (e['course_id'].toString() == courseId) {
            enrollment = e as Map<String, dynamic>;
            break;
          }
        }

        ProgramStatus status = ProgramStatus.available;
        double progress = 0.0;

        if (enrollment != null) {
          final String s = enrollment['status'] ?? 'applied';
          status = s == 'completed' ? ProgramStatus.completed : ProgramStatus.applied;
          progress = (enrollment['progress'] ?? 0.0).toDouble();
        }

        // Map category to icon for visual flair since icons aren't in DB
        IconData icon = Icons.school_outlined;
        Color color = Colors.blue;
        if (course['category'] == 'Power Skill Courses') {
          icon = Icons.bolt_rounded;
          color = Colors.green;
        } else if (course['category'] == 'Global Internships') {
          icon = Icons.public_rounded;
          color = Colors.indigo;
        }

        return Opportunity(
          dbId: course['id'],
          name: course['courseName'] ?? 'Unnamed Program',
          category: course['category'] ?? 'General',
          scholarship: course['scholarship_amount'] ?? '\$0',
          icon: icon,
          iconBackground: color,
          skillIcons: const [Icons.auto_awesome, Icons.psychology], // defaults
          status: status,
          progress: progress,
          description: 'A comprehensive program designed to build industry-ready skills.',
          curriculumUrl: course['curriculum_url'],
        );
      }).toList();

      setState(() {
        _allOpportunities = mapped;
        _isLoading = false;
      });

      if (mounted && mapped.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No programs found in database.')),
        );
      }
    } catch (e) {
      debugPrint('Error fetching programs: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _enrollInProgram(int courseId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('enrollments').insert({
        'student_id': user.id,
        'course_id': courseId,
        'status': 'applied',
        'progress': 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully applied! Check the "Applied" tab.'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _fetchPrograms();
    } catch (e) {
      debugPrint('Error enrolling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Opportunity> _forStatus(ProgramStatus status) {
    return _allOpportunities.where((o) {
      final matchesStatus = o.status == status;
      final matchesQuery =
          _query.isEmpty || o.name.toLowerCase().contains(_query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'];

    // Integrity check: if admin, redirect to admin dashboard
    if (role == 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/admin');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_userName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Available', icon: Icon(Icons.explore_outlined, size: 18)),
            Tab(text: 'Applied', icon: Icon(Icons.hourglass_top_rounded, size: 18)),
            Tab(text: 'Completed', icon: Icon(Icons.verified_outlined, size: 18)),
          ],
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.programs),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _ProgramListView(
                        items: _forStatus(ProgramStatus.available),
                        emptyLabel: 'No available programs match your search.',
                        onRefresh: _fetchPrograms,
                        onApply: (id) => _enrollInProgram(id),
                      ),
                      _ProgramListView(
                        items: _forStatus(ProgramStatus.applied),
                        emptyLabel: 'You haven\'t applied to anything yet.',
                        onRefresh: _fetchPrograms,
                        onApply: (_) {},
                      ),
                      _ProgramListView(
                        items: _forStatus(ProgramStatus.completed),
                        emptyLabel: 'No completed programs yet.',
                        onRefresh: _fetchPrograms,
                        onApply: (_) {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Search field with an animated clear (X) button that only appears
  /// once the user has typed something.
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        // Subtle shadow instead of a flat fill, matching the elevated
        // card style already used by OpportunitiesPreview on Home — for
        // visual consistency, not a redesign.
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search programs...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _query.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close),
                      onPressed: () => _searchController.clear(),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Renders one tab's list of programs, with:
///   - staggered entrance animation (re-triggers every time this list
///     rebuilds, e.g. after switching tabs or searching)
///   - pull-to-refresh
///   - animated empty state
/// ---------------------------------------------------------------------
class _ProgramListView extends StatelessWidget {
  final List<Opportunity> items;
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final Function(int) onApply;

  const _ProgramListView({
    required this.items,
    required this.emptyLabel,
    required this.onRefresh,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: items.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              // +1 for the results-count header row.
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${items.length} ${items.length == 1 ? 'program' : 'programs'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return _AnimatedProgramCard(
                  opportunity: items[index - 1],
                  index: index - 1,
                  onApply: () {
                    if (items[index - 1].dbId != null) {
                      onApply(items[index - 1].dbId!);
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          // Needed so RefreshIndicator still works with an "empty" view.
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight * 0.6,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.inbox_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      emptyLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A single program card with a staggered fade+slide entrance animation
/// and a status-appropriate footer (progress bar vs. completed badge).
class _AnimatedProgramCard extends StatefulWidget {
  final Opportunity opportunity;
  final int index;
  final VoidCallback onApply;

  const _AnimatedProgramCard({
    required this.opportunity,
    required this.index,
    required this.onApply,
  });

  @override
  State<_AnimatedProgramCard> createState() => _AnimatedProgramCardState();
}

class _AnimatedProgramCardState extends State<_AnimatedProgramCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(_fade);

    // Stagger: each card starts its animation slightly after the one
    // before it, capped so long lists don't feel sluggish.
    final delay = Duration(milliseconds: (widget.index * 60).clamp(0, 400));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 1.5,
            shadowColor: Colors.black.withOpacity(0.15),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade100),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  fadeSlideRoute(ProgramDetailsScreen(opportunity: o)),
                );
                if (result == true && o.dbId != null) {
                  widget.onApply();
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: o.iconBackground,
                          child: Icon(o.icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _chip(o.category,
                                      o.category == 'Power Skill Courses'
                                          ? Colors.green
                                          : Colors.blue),
                                  _chip(o.scholarship, Colors.orange),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildStatusFooter(o),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color.shade800,
        ),
      ),
    );
  }

  /// Status-specific footer:
  ///  - Available  -> "Apply Now" button
  ///  - Applied    -> animated progress bar
  ///  - Completed  -> green "Completed" badge with checkmark
  Widget _buildStatusFooter(Opportunity o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (o.curriculumUrl != null && o.curriculumUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: OutlinedButton.icon(
              onPressed: () async {
                try {
                  // Extract filename from the URL or path
                  final fileName = o.curriculumUrl!.split('/').last.split('?').first;
                  final String signedUrl = await Supabase.instance.client.storage
                      .from('curriculums')
                      .createSignedUrl(fileName, 300);

                  await launchUrl(
                    Uri.parse(signedUrl),
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  // Fallback to direct URL if signing fails
                  await launchUrl(
                    Uri.parse(o.curriculumUrl!),
                    mode: LaunchMode.externalApplication,
                  );
                }
              },
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View Curriculum PDF'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        _buildActionRow(o),
      ],
    );
  }

  Widget _buildActionRow(Opportunity o) {
    switch (o.status) {
      case ProgramStatus.available:
        return Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: widget.onApply,
            icon: const Icon(Icons.arrow_circle_right_outlined, size: 18),
            label: const Text('Apply Now'),
          ),
        );

      case ProgramStatus.applied:
        final progress = o.progress ?? 0.0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Progress',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('${(progress * 100).toInt()}%',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(Colors.blue),
                ),
              ),
            ),
          ],
        );

      case ProgramStatus.completed:
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 14, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green),
                ),
              ],
            ),
          ),
        );
    }
  }
}
