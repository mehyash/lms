import 'model.dart';

/// ---------------------------------------------------------------------
/// PROGRAM DETAILS SCREEN
/// ---------------------------------------------------------------------
/// Reached by tapping a program card on the Program Listing screen (or
/// the Home dashboard's Program Progress card). Shows the full picture
/// of a single Opportunity: who's hiring/sponsoring, domain & roles,
/// paid/unpaid + scholarship, rewards & badges, dates/timeline, apply
/// deadline, skills learnt, eligibility, fee, work mode, and description.
///
/// Frontend only — all data comes from the Opportunity passed in.
/// ---------------------------------------------------------------------
class ProgramDetailsScreen extends StatefulWidget {
  final Opportunity opportunity;

  const ProgramDetailsScreen({super.key, required this.opportunity});

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  bool _isEnrolling = false;

  Future<void> _enroll() async {
    if (widget.opportunity.dbId == null) return;
    
    setState(() => _isEnrolling = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('enrollments').insert({
        'student_id': user.id,
        'course_id': widget.opportunity.dbId,
        'status': 'applied',
        'progress': 0.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully applied!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      debugPrint('Error enrolling: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isEnrolling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.opportunity;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 160,
            backgroundColor: o.iconBackground,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
              title: Text(
                o.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      o.iconBackground,
                      o.iconBackground.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(o.icon, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickFactsRow(context, o),
                  const SizedBox(height: 16),
                  _sectionCard(
                    title: 'Description',
                    child: Text(
                      o.description,
                      style: const TextStyle(fontSize: 13.5, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Organization',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.business_outlined, 'Hired by', o.hiredBy),
                        const SizedBox(height: 10),
                        _infoRow(Icons.handshake_outlined, 'Sponsored by', o.sponsoredBy),
                        const SizedBox(height: 10),
                        _infoRow(Icons.category_outlined, 'Domain', o.domain),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Roles',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: o.roles.isEmpty
                          ? [const Text('Not specified', style: TextStyle(color: Colors.grey))]
                          : o.roles.map((r) => _chip(r, Colors.blue)).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Compensation & Scholarship',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(
                          o.compensationType == CompensationType.paid
                              ? Icons.payments_outlined
                              : Icons.volunteer_activism_outlined,
                          'Type',
                          o.compensationType == CompensationType.paid ? 'Paid' : 'Unpaid',
                        ),
                        const SizedBox(height: 10),
                        _infoRow(Icons.card_giftcard_outlined, 'Scholarship', o.scholarship),
                        const SizedBox(height: 10),
                        _infoRow(Icons.receipt_long_outlined, 'Fee', o.fee),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Rewards & Badges',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: o.rewardsAndBadges.isEmpty
                          ? [const Text('Not specified', style: TextStyle(color: Colors.grey))]
                          : o.rewardsAndBadges
                              .map((r) => _chip(r, Colors.amber, icon: Icons.emoji_events_outlined))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Dates & Timeline',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.play_circle_outline, 'Start date', o.startDate),
                        const SizedBox(height: 10),
                        _infoRow(Icons.timelapse_outlined, 'Duration', o.duration),
                        const SizedBox(height: 10),
                        _infoRow(Icons.event_busy_outlined, 'Deadline to apply', o.applyDeadline),
                        if (o.timeline.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _buildTimeline(context, o.timeline),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Skills You\'ll Learn',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: o.skillsLearnt.isEmpty
                          ? [const Text('Not specified', style: TextStyle(color: Colors.grey))]
                          : o.skillsLearnt.map((s) => _chip(s, Colors.green)).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Qualifications & Eligibility',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: o.qualifications.isEmpty
                          ? [const Text('Not specified', style: TextStyle(color: Colors.grey))]
                          : o.qualifications
                              .map((q) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_outline,
                                            size: 16, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(q, style: const TextStyle(fontSize: 13.5))),
                                      ],
                                    ),
                                  ))
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Mode',
                    child: _infoRow(
                      o.workMode == WorkMode.remote
                          ? Icons.home_work_outlined
                          : o.workMode == WorkMode.onsite
                              ? Icons.apartment_outlined
                              : Icons.sync_alt_outlined,
                      'Work mode',
                      o.workMode == WorkMode.remote
                          ? 'Remote'
                          : o.workMode == WorkMode.onsite
                              ? 'On-site'
                              : 'Hybrid',
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (o.status == ProgramStatus.available)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isEnrolling ? null : _enroll,
                        icon: _isEnrolling 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.arrow_circle_right_outlined),
                        label: Text(_isEnrolling ? 'Applying...' : 'Apply Now'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Small row of quick-glance stat chips near the top of the page.
  Widget _buildQuickFactsRow(BuildContext context, Opportunity o) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(o.category, o.category == 'Power Skill Courses' ? Colors.green : Colors.blue),
        _chip(o.scholarship, Colors.orange),
        _chip(
          o.compensationType == CompensationType.paid ? 'Paid' : 'Unpaid',
          Colors.purple,
        ),
        _chip(
          o.workMode == WorkMode.remote
              ? 'Remote'
              : o.workMode == WorkMode.onsite
                  ? 'On-site'
                  : 'Hybrid',
          Colors.teal,
        ),
      ],
    );
  }

  /// Reusable card container used for every section — keeps rounded
  /// corners, subtle shadow, and padding consistent across the page.
  Widget _sectionCard({required String title, required Widget child}) {
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
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, MaterialColor color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color.shade800),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, List<String> milestones) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(milestones.length, (i) {
        final isLast = i == milestones.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.grey.shade300,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    milestones[i],
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
