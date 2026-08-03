import 'model.dart';
import 'dashboard_calendar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  String _userName = 'User';
  List<CalendarEvent> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchName();
    await _fetchMeetings();
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

  Future<void> _fetchMeetings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Fetch student's enrollments to filter course-specific meetings
      final enrollRes = await Supabase.instance.client
          .from('enrollments')
          .select('course_id')
          .eq('student_id', user.id);
      
      final List<int> enrolledCourseIds = (enrollRes as List).map((e) => e['course_id'] as int).toList();

      final res = await Supabase.instance.client
          .from('meetings')
          .select()
          .order('meeting_date', ascending: true);

      final List<dynamic> data = res as List<dynamic>;
      
      final List<CalendarEvent> filtered = data.where((m) {
        final cid = m['course_id'];
        return cid == null || enrolledCourseIds.contains(cid);
      }).map((m) {
        return CalendarEvent(
          title: m['title'],
          date: DateTime.parse(m['meeting_date']),
          tag: m['course_id'] == null ? EventTag.personal : EventTag.placementA,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _meetings = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching meetings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'];

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
              Navigator.pushReplacementNamed(
                context,
                role == 'admin' ? '/admin' : '/home',
              );
            }
          },
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.calendar),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchMeetings,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: DashboardCalendar(events: _meetings),
            ),
          ),
    );
  }
}
