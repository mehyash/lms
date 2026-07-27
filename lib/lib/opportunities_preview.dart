import 'package:flutter/material.dart';
import '/opportunity.dart';
import '/program_listing_screen.dart';
import '/page_transitions.dart';

/// ---------------------------------------------------------------------
/// OPPORTUNITIES PREVIEW WIDGET  (Dashboard short overview)
/// ---------------------------------------------------------------------
/// Mirrors the table-style layout in the reference screenshot
/// (icon | name + category chip | scholarship | skills) but compressed
/// into a scrollable preview card for the Home Screen. Tapping
/// "View All" or any row pushes into the full Program Listing screen
/// (Available / Applied / Completed tabs).
///
/// UX details added:
///  - Staggered fade + slide-in entrance animation per row
///  - Scale-down "press" animation on tap (tactile feedback)
///  - Row highlight ripple via InkWell
/// ---------------------------------------------------------------------
class OpportunitiesPreview extends StatefulWidget {
  const OpportunitiesPreview({super.key});

  @override
  State<OpportunitiesPreview> createState() => _OpportunitiesPreviewState();
}

class _OpportunitiesPreviewState extends State<OpportunitiesPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Drives the staggered entrance animation for the preview rows.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only show a short preview (first 3) on the dashboard — full list
    // lives in the Program Listing screen.
    final preview = dummyOpportunities.take(3).toList();

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommended Opportunities',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // "View All" pushes into the full Program Listing screen,
              // with a subtle animated arrow to invite the tap.
              TextButton.icon(
                onPressed: () {
                  // Shared transition (see utils/page_transitions.dart) so
                  // this and every other opportunity-row tap animate the
                  // same way when entering the Programs page.
                  Navigator.push(
                    context,
                    fadeSlideRoute(const ProgramListingScreen()),
                  );
                },
                label: const Text('View All'),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Staggered rows: each row fades + slides in slightly after
          // the previous one, driven off the same controller.
          ...List.generate(preview.length, (index) {
            final start = index * 0.15;
            final end = (start + 0.6).clamp(0.0, 1.0);
            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(start, end, curve: Curves.easeOut),
            );
            return _AnimatedOpportunityRow(
              opportunity: preview[index],
              animation: animation,
            );
          }),
        ],
      ),
    );
  }
}

/// A single animated + tappable row representing one opportunity.
class _AnimatedOpportunityRow extends StatefulWidget {
  final Opportunity opportunity;
  final Animation<double> animation;

  const _AnimatedOpportunityRow({
    required this.opportunity,
    required this.animation,
  });

  @override
  State<_AnimatedOpportunityRow> createState() =>
      _AnimatedOpportunityRowState();
}

class _AnimatedOpportunityRowState extends State<_AnimatedOpportunityRow> {
  // Tracks whether the row is currently pressed, to drive the
  // "press and scale down slightly" tactile-feedback animation.
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;

    return FadeTransition(
      opacity: widget.animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(widget.animation),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              onTap: () {
                // Per spec: tapping a recommended opportunity on the Home
                // dashboard navigates to the Programs page (not a dialog,
                // not a duplicate page). A per-opportunity Program Details
                // screen does exist now (see screens/program_details_screen.dart)
                // and is reachable from the Program Listing cards instead.
                Navigator.push(
                  context,
                  fadeSlideRoute(const ProgramListingScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon bubble
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: o.iconBackground,
                      child: Icon(o.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Name + category chip
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: o.category == 'Power Skill Courses'
                                  ? Colors.green.shade50
                                  : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              o.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: o.category == 'Power Skill Courses'
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scholarship amount
                    Text(
                      o.scholarship,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
