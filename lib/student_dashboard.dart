import 'model.dart';
import 'meeting_widget.dart';
import 'weekly_actionables.dart';
import 'submissions_hub.dart';
import 'dashboard_calendar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  String _userName = 'Student';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final studentRes = await Supabase.instance.client
          .from('students')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();

      if (studentRes != null && mounted) {
        setState(() {
          _userName = studentRes['first_name'] ?? 'Student';
        });
      } else {
        final metadataName = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                             user.userMetadata?['first_name'];
        if (metadataName != null && mounted) {
          setState(() => _userName = metadataName);
        }
      }
    } catch (e) {
      debugPrint('Error fetching student dashboard name: $e');
    }
  }

  // TEMP mock data
  List<MeetingSummary> get _mockMeetings => [
        MeetingSummary(
          title: 'Weekly Check-in',
          date: DateTime.now().subtract(const Duration(days: 1)),
          summary:
              'Discussed wireframe progress; agreed to finalize color scheme by Friday.',
        ),
        MeetingSummary(
          title: 'Sprint Planning',
          date: DateTime.now().subtract(const Duration(days: 4)),
          summary: 'Assigned submissions hub and calendar widget tasks.',
        ),
      ];

  List<ActionItem> get _mockActions => [
        ActionItem(title: 'Submit weekly report', dueDate: DateTime.now()),
        ActionItem(
            title: 'Review curriculum module 3',
            dueDate: DateTime.now().add(const Duration(days: 2))),
      ];

  List<SubmissionItem> get _mockSubmissions => [
        SubmissionItem(name: 'Week 4 Report', status: SubmissionStatus.draft),
        SubmissionItem(
            name: 'Week 3 Report', status: SubmissionStatus.reviewed),
      ];

  List<CalendarEvent> get _mockEvents => [
        CalendarEvent(
            title: 'Standup',
            date: DateTime.now(),
            tag: EventTag.placementA),
        CalendarEvent(
            title: 'Design review',
            date: DateTime.now().add(const Duration(days: 2)),
            tag: EventTag.placementB),
      ];

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
        title: Text('Hi, $_userName 👋'),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DashboardCalendar(events: _mockEvents),
            const SizedBox(height: 12),
            WeeklyActionables(items: _mockActions),
            const SizedBox(height: 12),
            MeetingWidget(meetings: _mockMeetings),
            const SizedBox(height: 12),
            SubmissionsHub(submissions: _mockSubmissions),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/messages'),
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask'),
      ),
    );
  }
}
