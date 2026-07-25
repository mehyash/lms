import 'package:flutter/material.dart';
import 'opportunity.dart';
import 'app_drawer.dart';
import 'page_transitions.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Opportunity> _forStatus(ProgramStatus status) {
    return dummyOpportunities.where((o) {
      final matchesStatus = o.status == status;
      final matchesQuery =
          _query.isEmpty || o.name.toLowerCase().contains(_query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Programs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        bottom: TabBar(
          controller: _tabController,
          // Animated pill-style indicator instead of the plain underline,
          // for a more modern / dynamic feel.
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
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
      // Programs is a primary drawer destination (not just a screen you
      // push into from Home), so it gets the same shared drawer as Home,
      // with "Programs" highlighted as the active item.
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.programs),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ProgramListView(
                  items: _forStatus(ProgramStatus.available),
                  emptyLabel: 'No available programs match your search.',
                ),
                _ProgramListView(
                  items: _forStatus(ProgramStatus.applied),
                  emptyLabel: 'You haven\'t applied to anything yet.',
                ),
                _ProgramListView(
                  items: _forStatus(ProgramStatus.completed),
                  emptyLabel: 'No completed programs yet.',
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

  const _ProgramListView({required this.items, required this.emptyLabel});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // Placeholder for a real API refresh call (next week's backend work).
        await Future.delayed(const Duration(milliseconds: 800));
      },
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

  const _AnimatedProgramCard({required this.opportunity, required this.index});

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
              onTap: () {
                Navigator.push(
                  context,
                  fadeSlideRoute(ProgramDetailsScreen(opportunity: o)),
                );
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
    switch (o.status) {
      case ProgramStatus.available:
        return Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Application flow coming soon')),
              );
            },
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
              // TweenAnimationBuilder animates the bar filling up smoothly
              // whenever this card is (re)built, instead of jumping
              // straight to its value.
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
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
