import 'model.dart';

/// ---------------------------------------------------------------------
/// OPPORTUNITIES PREVIEW WIDGET  (Dashboard short overview)
/// ---------------------------------------------------------------------
class OpportunitiesPreview extends StatefulWidget {
  const OpportunitiesPreview({super.key});

  @override
  State<OpportunitiesPreview> createState() => _OpportunitiesPreviewState();
}

class _OpportunitiesPreviewState extends State<OpportunitiesPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  List<Opportunity> _previewItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Get user's enrolled course IDs
      final enrollmentsRes = await Supabase.instance.client
          .from('enrollments')
          .select('course_id')
          .eq('student_id', user.id);
      
      final enrolledIds = (enrollmentsRes as List).map((e) => e['course_id'].toString()).toList();

      // 2. Fetch courses not in that list
      var query = Supabase.instance.client.from('Courses').select();
      
      if (enrolledIds.isNotEmpty) {
        query = query.filter('id', 'not.in', '(${enrolledIds.join(',')})');
      }

      final res = await query.limit(3);
      
      final List<dynamic> data = res as List<dynamic>;
      final List<Opportunity> mapped = data.map((course) {
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
          skillIcons: const [],
          status: ProgramStatus.available,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _previewItems = mapped;
          _isLoading = false;
        });
        _controller.forward();
      }
    } catch (e) {
      debugPrint('Error fetching preview: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enroll(int courseId) async {
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
          const SnackBar(content: Text('Successfully applied!'), backgroundColor: Colors.green),
        );
        _fetchPreview(); 
      }
    } catch (e) {
      debugPrint('Error enrolling from home: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              TextButton.icon(
                onPressed: () {
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
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_previewItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No recommendations yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ...List.generate(_previewItems.length, (index) {
              final start = index * 0.15;
              final end = (start + 0.6).clamp(0.0, 1.0);
              final animation = CurvedAnimation(
                parent: _controller,
                curve: Interval(start, end, curve: Curves.easeOut),
              );
              return _AnimatedOpportunityRow(
                opportunity: _previewItems[index],
                animation: animation,
                onApply: () => _enroll(_previewItems[index].dbId!),
              );
            }),
        ],
      ),
    );
  }
}

class _AnimatedOpportunityRow extends StatefulWidget {
  final Opportunity opportunity;
  final Animation<double> animation;
  final VoidCallback onApply;

  const _AnimatedOpportunityRow({
    required this.opportunity,
    required this.animation,
    required this.onApply,
  });

  @override
  State<_AnimatedOpportunityRow> createState() =>
      _AnimatedOpportunityRowState();
}

class _AnimatedOpportunityRowState extends State<_AnimatedOpportunityRow> {
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
                Navigator.push(
                  context,
                  fadeSlideRoute(ProgramDetailsScreen(opportunity: o)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          o.scholarship,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: widget.onApply,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(50, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Apply', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
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
