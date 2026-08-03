import 'model.dart';

class AdminStudentTrackingScreen extends StatefulWidget {
  const AdminStudentTrackingScreen({super.key});

  @override
  State<AdminStudentTrackingScreen> createState() => _AdminStudentTrackingScreenState();
}

class _AdminStudentTrackingScreenState extends State<AdminStudentTrackingScreen> {
  List<Map<String, dynamic>> _courses = [];
  String? _selectedCourseId; // NULL means "All Programs"
  List<Map<String, dynamic>> _allStudents = [];
  bool _isLoading = true;
  String _userName = 'Admin';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await _fetchAdminName();
    await _fetchCourses();
    await _fetchAllStudents();
  }

  Future<void> _fetchAdminName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'Admin';
    if (mounted) setState(() => _userName = name);
  }

  Future<void> _fetchCourses() async {
    try {
      final res = await Supabase.instance.client.from('Courses').select('id, courseName');
      if (mounted) {
        setState(() {
          _courses = List<Map<String, dynamic>>.from(res);
        });
      }
    } catch (e) {
      debugPrint('Error fetching courses: $e');
    }
  }

  Future<void> _fetchAllStudents() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch all enrollments
      final enrollRes = await Supabase.instance.client
          .from('enrollments')
          .select('student_id, course_id, status, Courses(courseName)');

      final List<dynamic> enrollData = enrollRes as List<dynamic>;

      if (enrollData.isEmpty) {
        if (mounted) setState(() { _allStudents = []; _isLoading = false; });
        return;
      }

      // 2. Fetch profiles
      final List<String> studentIds = enrollData.map((e) => e['student_id'].toString()).toSet().toList();
      
      final profilesRes = await Supabase.instance.client
          .from('students')
          .select()
          .filter('id', 'in', '(${studentIds.join(",")})');
      
      final List<dynamic> profilesData = profilesRes as List;
      debugPrint('Step 2: Found ${profilesData.length} student profiles.');
      if (profilesData.isNotEmpty) {
        debugPrint('Step 2 Profile Keys: ${profilesData.first.keys.toList()}');
      }

      // 3. Fetch all submissions to get counts
      final subRes = await Supabase.instance.client.from('submissions').select('student_id, course_id, status');
      final List<dynamic> subData = subRes as List<dynamic>;

      if (mounted) {
        setState(() {
          _allStudents = enrollData.map((enrollment) {
            final sid = enrollment['student_id'].toString();
            final cid = enrollment['course_id'];
            
            // Safer profile matching with string conversion
            Map<String, dynamic>? profile;
            for (var p in profilesData) {
              if (p['id'].toString() == sid) {
                profile = p as Map<String, dynamic>;
                break;
              }
            }

            if (profile == null) {
              debugPrint('WARNING (Tracking Screen): No profile match for $sid');
            }

            String fName = profile?['firstName'] ?? profile?['first_name'] ?? '';
            String lName = profile?['lastName'] ?? profile?['last_name'] ?? '';
            String email = profile?['Email'] ?? profile?['email'] ?? 'No Email';
            
            debugPrint('Mapped (Tracking Screen): ID=$sid, Name=$fName $lName');

            final studentSubs = subData.where((s) => s['student_id'] == sid && s['course_id'] == cid).toList();
            final approvedCount = studentSubs.where((s) => s['status'] == 'approved').length;

            return {
              'student_id': sid,
              'course_id': cid.toString(),
              'course_name': enrollment['Courses']['courseName'],
              'name': '$fName $lName'.trim().isEmpty ? 'Student ($email)' : '$fName $lName',
              'email': email,
              'total_uploaded': studentSubs.length,
              'approved_count': approvedCount,
              'enrollment_status': enrollment['status'] ?? 'applied',
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error tracking students: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    if (_selectedCourseId == null) return _allStudents;
    return _allStudents.where((s) => s['course_id'] == _selectedCourseId).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Hi, $_userName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildFilterBar(),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filteredStudents.isEmpty
                ? const Center(child: Text('No students found for this selection.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredStudents.length,
                    itemBuilder: (context, index) => _buildStudentCard(_filteredStudents[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Student Tracking', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Monitor progress and grade submissions across all programs.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              value: _selectedCourseId,
              hint: const Text('All Programs'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Programs')),
                ..._courses.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['courseName']),
                )),
              ],
              onChanged: (val) => setState(() => _selectedCourseId = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () => _showStudentDetail(student),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.person, color: Colors.blue),
        ),
        title: Text(student['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(student['course_name'], style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text('${student['total_uploaded']}/5 Modules Uploaded', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: student['enrollment_status'] == 'completed' ? Colors.green.shade50 : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student['enrollment_status'].toString().toUpperCase(),
                  style: TextStyle(fontSize: 10, color: student['enrollment_status'] == 'completed' ? Colors.green : Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 4),
              Text('${student['approved_count']} Approved', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  void _showStudentDetail(Map<String, dynamic> student) {
    // Reusing the existing detail sheet logic (modal bottom sheet)
    // For now, navigating to detail sheet. In a larger app, this might be a full page.
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StudentSubmissionDetailModal(
        student: {
          'id': student['student_id'],
          'name': student['name'],
          'email': student['email'],
        }, 
        courseId: student['course_id'],
        onUpdate: () {
          _fetchAllStudents();
        },
      ),
    );
  }
}

// We need to move the detail widget out of admin_dashboard so it can be reused or exported
class StudentSubmissionDetailModal extends StatefulWidget {
  final Map<String, dynamic> student;
  final String courseId;
  final VoidCallback onUpdate;

  const StudentSubmissionDetailModal({super.key, required this.student, required this.courseId, required this.onUpdate});

  @override
  State<StudentSubmissionDetailModal> createState() => _StudentSubmissionDetailModalState();
}

class _StudentSubmissionDetailModalState extends State<StudentSubmissionDetailModal> {
  List<Map<String, dynamic>> _submissions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    try {
      final res = await Supabase.instance.client
          .from('submissions')
          .select()
          .eq('student_id', widget.student['id'])
          .eq('course_id', int.parse(widget.courseId))
          .order('module_number');
      
      setState(() {
        _submissions = List<Map<String, dynamic>>.from(res);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Detail error: $e');
    }
  }

  Future<void> _gradeSubmission(int subId, int marks) async {
    try {
      // 1. Mark submission as approved
      await Supabase.instance.client.from('submissions').update({
        'status': 'approved',
        'grade': marks,
      }).eq('id', subId);

      // 2. Fetch fresh submission count for this specific course & student
      final res = await Supabase.instance.client
          .from('submissions')
          .select('id')
          .eq('student_id', widget.student['id'])
          .eq('course_id', int.parse(widget.courseId))
          .eq('status', 'approved');
      
      final int approvedCount = (res as List).length;
      final double newProgress = (approvedCount / 5.0).clamp(0.0, 1.0);

      // 3. Update the enrollment progress
      await Supabase.instance.client.from('enrollments').update({
        'progress': newProgress,
        'status': approvedCount >= 5 ? 'completed' : 'applied',
      }).eq('student_id', widget.student['id']).eq('course_id', int.parse(widget.courseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module approved! Progress updated to ${(newProgress * 100).toInt()}%'),
            backgroundColor: Colors.green,
          ),
        );
      }

      _fetchSubmissions();
      widget.onUpdate();
    } catch (e) {
      debugPrint('Grading error: $e');
    }
  }

  Future<void> _checkIfAllCompleted() async {
    // Logic moved inside _gradeSubmission for better consistency
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.student['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(widget.student['email'], style: const TextStyle(color: Colors.grey)),
                ],
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(height: 32),
          const Text('Module Submissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _submissions.isEmpty 
                ? const Center(child: Text('No files uploaded yet.'))
                : ListView.builder(
                    itemCount: _submissions.length,
                    itemBuilder: (context, i) {
                      final s = _submissions[i];
                      return _buildSubmissionCard(s);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> s) {
    final TextEditingController marksController = TextEditingController(text: s['grade']?.toString() ?? '');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(child: Text('Module ${s['module_number']} Report', style: const TextStyle(fontWeight: FontWeight.bold))),
                TextButton(
                  onPressed: () async {
                    try {
                      // Use a signed URL to bypass regional/security 404s
                      // This generates a temporary 5-minute link
                      final String signedUrl = await Supabase.instance.client.storage
                          .from('submissions')
                          .createSignedUrl(s['file_path'], 300);
                      
                      await launchUrl(
                        Uri.parse(signedUrl),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (e) {
                      debugPrint('Error opening PDF: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not generate secure link for PDF.')),
                        );
                      }
                    }
                  },
                  child: const Text('View PDF'),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Text('Marks: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: marksController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '0-10', isDense: true, border: OutlineInputBorder()),
                  ),
                ),
                const Text(' / 10', style: TextStyle(color: Colors.grey)),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: s['status'] == 'approved' ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: s['status'] == 'approved' ? null : () {
                    final marks = int.tryParse(marksController.text);
                    if (marks != null && marks >= 0 && marks <= 10) {
                      _gradeSubmission(s['id'], marks);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter marks between 0 and 10')));
                    }
                  },
                  child: Text(s['status'] == 'approved' ? 'Approved' : 'Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
