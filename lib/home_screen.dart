import 'package:flutter/material.dart';
import 'opportunities_preview.dart';
import '/app_drawer.dart';
import '/opportunity.dart';
import 'page_transitions.dart';
import 'program_listing_screen.dart';

/// A single announcement shown in the Announcements section.
class _Announcement {
  final String title;
  final String description;
  final String date;
  final bool isNew;

  const _Announcement({
    required this.title,
    required this.description,
    required this.date,
    this.isNew = false,
  });
}

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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar acts as the top identity bar of the app (branding will be
      // themed globally later, per the "Navigation & Branding Setup" step).
      // `automaticallyImplyLeading` is left at its default (true) so
      // Flutter shows the standard hamburger (☰) icon beside the title
      // and wires it up to open `drawer` below — no custom button needed.
      appBar: AppBar(
        title: const Text('Excelerate'),
        centerTitle: false,
        actions: [
          // Notification bell — visual only for this sprint.
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO (Future Team):
              // Implement notification center / real-time notifications.
            },
          ),
        ],
      ),
      // Material 3 Navigation Drawer, opened via the AppBar hamburger.
      // Home is the currently active destination on this screen.
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.home),
      // SingleChildScrollView so the whole Home Screen scrolls nicely
      // on smaller devices instead of overflowing.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Simple welcome header — placeholder for now,
              // will later pull the logged-in user's name from backend.
              const Text(
                'Welcome back 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // ---------------- PROGRAMS / RECOMMENDED OPPORTUNITIES ----
              // Short dashboard-style overview (icon, name+category,
              // scholarship) matching the reference screenshot, with a
              // "View All" that pushes into the full Program Listing
              // screen (Available / Applied / Completed tabs).
              const OpportunitiesPreview(),
              const SizedBox(height: 28),

              // ---------------- PROGRAM PROGRESS SECTION ----------------
              _buildSectionTitle('Current Program'),
              const SizedBox(height: 10),
              _buildProgramProgressCard(context),
              const SizedBox(height: 28),

              // ---------------- ANNOUNCEMENTS SECTION ----------------
              _buildSectionTitle('Announcements'),
              const SizedBox(height: 10),
              _buildAnnouncementsSection(),
              const SizedBox(height: 28),

              // ---------------- QUICK LINKS SECTION ----------------
              _buildSectionTitle('Quick Links'),
              const SizedBox(height: 10),
              _buildQuickLinksSection(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable section title widget — keeps headings consistent
  /// across Programs / Announcements / Quick Links.
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  /// ---------------------------------------------------------------
  /// ANNOUNCEMENTS SECTION
  /// Simple vertical feed, kept out of the way visually (per the
  /// proposal's note: "Simple feeds ... that stay out of the way").
  /// ---------------------------------------------------------------
  Widget _buildAnnouncementsSection() {
    const List<_Announcement> dummyAnnouncements = [
      _Announcement(
        title: 'New Internship Orientation Tomorrow',
        description: 'Mid-semester orientation begins tomorrow.',
        date: '10:00 AM',
        isNew: true,
      ),
      _Announcement(
        title: 'Resume Workshop Friday',
        description: 'Improve your ATS score with industry mentors.',
        date: 'Friday',
        isNew: true,
      ),
      _Announcement(
        title: 'Submission Deadline Extended',
        description: 'Final submissions now due 2 days later than planned.',
        date: 'This week',
      ),
    ];

    return Column(
      children: dummyAnnouncements.map((a) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          // Matches the elevated white-card style used across the app
          // (OpportunitiesPreview, program cards) for visual consistency.
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (a.isNew) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'New',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.description,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.date,
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

  /// ---------------------------------------------------------------
  /// PROGRAM PROGRESS SECTION
  /// Summary-only overview of the user's most active ongoing program
  /// (highest progress among ProgramStatus.applied items). Tapping
  /// the card navigates to the full Programs page — no detail is
  /// shown here beyond the summary.
  /// ---------------------------------------------------------------
  Widget _buildProgramProgressCard(BuildContext context) {
    final ongoing = dummyOpportunities
        .where((o) => o.status == ProgramStatus.applied)
        .toList()
      ..sort((a, b) => (b.progress ?? 0).compareTo(a.progress ?? 0));

    if (ongoing.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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

    final program = ongoing.first;
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
              color: Colors.black.withOpacity(0.05),
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
            if (program.currentModule.isNotEmpty)
              Text(
                'Current Module: ${program.currentModule}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
              ),
            if (program.totalWeeks > 0) ...[
              const SizedBox(height: 2),
              Text(
                'Week ${program.weeksCompleted} of ${program.totalWeeks}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ---------------------------------------------------------------
  /// QUICK LINKS SECTION
  /// Grid of shortcut actions. These are placeholders — real
  /// destinations (Submissions, Calendar, etc.) get wired up as
  /// those screens are built in later weeks.
  /// ---------------------------------------------------------------
  Widget _buildQuickLinksSection(BuildContext context) {
    final List<Map<String, dynamic>> quickLinks = [
      {'label': 'Submissions', 'icon': Icons.upload_file},
      {'label': 'Calendar', 'icon': Icons.calendar_today},
      {'label': 'Messages', 'icon': Icons.chat_bubble_outline},
      {'label': 'Profile', 'icon': Icons.person_outline},
    ];

    return GridView.builder(
      shrinkWrap: true, // needed since this is nested in a scroll view
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
            // TODO (Future Team):
            // Implement navigation for this Quick Link once its
            // destination screen exists (Submissions, Calendar,
            // Messages, Profile). Keep design/functionality as-is
            // until then — see the drawer for the equivalent items.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item['label']} tapped')),
            );
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
