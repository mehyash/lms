import 'package:url_launcher/url_launcher.dart';
import 'model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId;
  List<Map<String, dynamic>> _enrolledStudents = [];
  bool _isLoadingCourses = true;
  bool _isLoadingStudents = false;
  String _adminName = 'Admin';
  bool _isAuthorized = false;
  bool _checkingAuth = true;

  // Stats
  int _activeInternsCount = 0;
  int _pendingSubmissionsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final role = user.userMetadata?['role'];
    if (role == 'admin') {
      setState(() {
        _isAuthorized = true;
        _checkingAuth = false;
      });
      _fetchInitialData();
      return;
    }

    // Secondary check: verify in DB in case metadata is stale
    try {
      final adminCheck = await Supabase.instance.client
          .from('Admins')
          .select()
          .ilike('Email', user.email!)
          .maybeSingle();

      if (adminCheck != null) {
        setState(() {
          _isAuthorized = true;
          _checkingAuth = false;
        });
        _fetchInitialData();
      } else {
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _fetchInitialData() async {
    await _fetchAdminName();
    await _fetchCourses();
    await _fetchGlobalStats();
  }

  Future<void> _fetchAdminName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Fallback from metadata
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'Admin';

    if (mounted) setState(() => _adminName = name);
  }

  Future<void> _fetchGlobalStats() async {
    try {
      final studentsRes = await Supabase.instance.client
          .from('enrollments')
          .select('student_id');
      
      final pendingRes = await Supabase.instance.client
          .from('submissions')
          .select('id')
          .eq('status', 'submitted');
      
      if (mounted) {
        setState(() {
          _activeInternsCount = (studentsRes as List).length;
          _pendingSubmissionsCount = (pendingRes as List).length;
        });
      }
    } catch (e) {
      debugPrint('Stats error: $e');
    }
  }

  Future<void> _fetchCourses() async {
    try {
      final res = await Supabase.instance.client.from('Courses').select('id, courseName');
      if (mounted) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(res);
          if (_courses.isNotEmpty) {
            _selectedCourseId = _courses.first['id'].toString();
            _fetchStudentsForCourse(_selectedCourseId!);
          }
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchStudentsForCourse(String courseId) async {
    if (mounted) setState(() => _isLoadingStudents = true);
    try {
      debugPrint('--- Fetching Students via Join ---');
      
      // We use a join: fetch from enrollments and automatically pull the student profile
      final res = await Supabase.instance.client
          .from('enrollments')
          .select('*, student:student_id(*)') 
          .eq('course_id', int.parse(courseId));

      final List<dynamic> data = res as List<dynamic>;
      debugPrint('Found ${data.length} enrolled students.');

      // Fetch submissions for module counts
      final subRes = await Supabase.instance.client
          .from('submissions')
          .select('student_id, status')
          .eq('course_id', int.parse(courseId));
      final List<dynamic> subData = subRes as List<dynamic>;

      if (mounted) {
        setState(() {
          _enrolledStudents = data.map((enrollment) {
            final sid = enrollment['student_id'];
            final profile = enrollment['student']; // The joined student data

            String name = 'New User';
            String email = 'No Email';

            if (profile != null) {
              final fName = profile['firstName'] ?? profile['first_name'] ?? '';
              final lName = profile['lastName'] ?? profile['last_name'] ?? '';
              email = profile['Email'] ?? profile['email'] ?? 'No Email';
              name = '$fName $lName'.trim().isEmpty ? 'Student ($email)' : '$fName $lName';
            } else {
              debugPrint('Warning: Profile data missing for student $sid. Check RLS policies!');
              name = 'User ($sid)';
            }

            final studentSubs = subData.where((s) => s['student_id'] == sid).toList();
            final approvedCount = studentSubs.where((s) => s['status'] == 'approved').length;

            return {
              'id': sid,
              'name': name,
              'email': email,
              'total_uploaded': studentSubs.length,
              'approved_count': approvedCount,
              'enrollment_status': enrollment['status'] ?? 'applied',
            };
          }).toList();
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      debugPrint('Tracking Error: $e');
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized) {
      return const Scaffold(body: Center(child: Text('Access Denied')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Hi, $_adminName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.admin),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchGlobalStats();
          if (_selectedCourseId != null) await _fetchStudentsForCourse(_selectedCourseId!);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- STATS ---
              Row(
                children: [
                  _buildStatCard('Active Interns', _activeInternsCount.toString(), Colors.blue),
                  const SizedBox(width: 12),
                  _buildStatCard('Pending Grading', _pendingSubmissionsCount.toString(), Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // --- MANAGEMENT TOOLS ---
              const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildActionButton(context, 'Post Announcement', Icons.campaign_rounded, Colors.purple, () => _showAnnouncementDialog(context)),
                  const SizedBox(width: 12),
                  _buildActionButton(context, 'Schedule Meeting', Icons.calendar_month_rounded, Colors.teal, () => _showScheduleDialog(context)),
                ],
              ),
              const SizedBox(height: 24),

              // --- STUDENT TRACKING SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Student Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin/tracking'),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCourseSelector(),
              const SizedBox(height: 16),
              _buildStudentList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: _isLoadingCourses 
        ? const LinearProgressIndicator()
        : DropdownButton<String>(
            isExpanded: true,
            underline: const SizedBox(),
            value: _selectedCourseId,
            items: _courses.map((c) => DropdownMenuItem(
              value: c['id'].toString(),
              child: Text(c['courseName']),
            )).toList(),
            onChanged: (val) {
              setState(() => _selectedCourseId = val);
              _fetchStudentsForCourse(val!);
            },
          ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoadingStudents) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
    if (_enrolledStudents.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No students enrolled in this program.')));

    return Column(
      children: _enrolledStudents.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: () => _showStudentDetail(s),
          leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
          title: Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('${s['total_uploaded']}/5 Modules Uploaded'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: s['enrollment_status'] == 'completed' ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  s['enrollment_status'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 10, color: s['enrollment_status'] == 'completed' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text('${s['approved_count']} Approved', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  void _showStudentDetail(Map<String, dynamic> student) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StudentSubmissionDetailModal(
        student: student, 
        courseId: _selectedCourseId!,
        onUpdate: () {
          _fetchStudentsForCourse(_selectedCourseId!);
          _fetchGlobalStats();
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    String? dialogSelectedCourseId;
    final contentController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: dialogSelectedCourseId,
                hint: const Text('Select Course (Optional)'),
                decoration: const InputDecoration(labelText: 'Target Course'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Students')),
                  ..._courses.map((c) => DropdownMenuItem(
                    value: c['id'].toString(),
                    child: Text(c['courseName']),
                  )),
                ],
                onChanged: (val) => setDialogState(() => dialogSelectedCourseId = val),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(hintText: 'Announcement Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Type your message...'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || contentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }
                
                try {
                  // In a real app, you'd save this to an 'announcements' table
                  // For now, we'll simulate the "Send to all students" logic
                  if (dialogSelectedCourseId != null) {
                    // Logic to target students in 'dialogSelectedCourseId'
                  }
                  
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Announcement posted successfully!'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  debugPrint('Error posting announcement: $e');
                }
              },
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    String? dialogSelectedCourseId;
    final titleController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Schedule Meeting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: dialogSelectedCourseId,
                  hint: const Text('Select Target Recipients'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Students')),
                    ..._courses.map((c) => DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['courseName']),
                    )),
                  ],
                  onChanged: (val) => setDialogState(() => dialogSelectedCourseId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Meeting Title', hintText: 'e.g., Weekly Sync'),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedDate == null ? 'Select Date' : 'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setDialogState(() => selectedDate = picked);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(selectedTime == null ? 'Select Time' : 'Time: ${selectedTime!.format(context)}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) setDialogState(() => selectedTime = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
                  return;
                }

                try {
                  final combinedDateTime = DateTime(
                    selectedDate!.year,
                    selectedDate!.month,
                    selectedDate!.day,
                    selectedTime!.hour,
                    selectedTime!.minute,
                  );

                  await Supabase.instance.client.from('meetings').insert({
                    'title': titleController.text.trim(),
                    'meeting_date': combinedDateTime.toIso8601String(),
                    'course_id': dialogSelectedCourseId != null ? int.parse(dialogSelectedCourseId!) : null,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meeting scheduled successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  debugPrint('Error scheduling meeting: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to schedule meeting')));
                  }
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
