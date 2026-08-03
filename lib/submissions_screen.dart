import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'model.dart';
import 'submissions_hub.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  List<Map<String, dynamic>> _appliedCourses = [];
  String? _selectedCourseId;
  int _selectedModule = 1;
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  bool _isLoadingCourses = true;
  List<SubmissionItem> _previousSubmissions = [];
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchName();
    _fetchAppliedCourses();
    _fetchPreviousSubmissions();
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

  Future<void> _fetchAppliedCourses() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final res = await Supabase.instance.client
          .from('enrollments')
          .select('course_id, Courses(id, courseName)')
          .eq('student_id', user.id)
          .eq('status', 'applied');

      final List<dynamic> data = res as List<dynamic>;
      setState(() {
        _appliedCourses = data.map((e) => e['Courses'] as Map<String, dynamic>).toList();
        if (_appliedCourses.isNotEmpty) {
          _selectedCourseId = _appliedCourses.first['id'].toString();
        }
        _isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _fetchPreviousSubmissions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final res = await Supabase.instance.client
          .from('submissions')
          .select('*, Courses(courseName)')
          .eq('student_id', user.id)
          .order('created_at', ascending: false);

      final List<dynamic> data = res as List<dynamic>;
      setState(() {
        _previousSubmissions = data.map((s) {
          final courseName = s['Courses']['courseName'] ?? 'Unknown';
          final module = s['module_number'];
          return SubmissionItem(
            name: '$courseName - Module $module',
            status: _mapStatus(s['status']),
          );
        }).toList();
      });
    } catch (e) {
      debugPrint('Error fetching submissions: $e');
    }
  }

  SubmissionStatus _mapStatus(String? status) {
    switch (status) {
      case 'reviewed': return SubmissionStatus.reviewed;
      case 'draft': return SubmissionStatus.draft;
      default: return SubmissionStatus.submitted;
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  Future<void> _uploadSubmission() async {
    if (_selectedCourseId == null || _pickedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a course and a PDF file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final courseName = _appliedCourses.firstWhere((c) => c['id'].toString() == _selectedCourseId)['courseName'];
      
      // Clean file name
      final safeCourseName = courseName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${user!.id}_${safeCourseName}_Mod${_selectedModule}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Removed the 'reports/' prefix to match the curriculum fix (save directly in bucket)
      final filePath = fileName;

      // 1. Upload to Storage
      if (kIsWeb) {
        await Supabase.instance.client.storage
            .from('submissions')
            .uploadBinary(filePath, _pickedFile!.bytes!);
      } else {
        await Supabase.instance.client.storage
            .from('submissions')
            .upload(filePath, File(_pickedFile!.path!));
      }

      // 2. Get Public URL
      final fileUrl = Supabase.instance.client.storage
          .from('submissions')
          .getPublicUrl(filePath);

      // 3. Save to Database
      await Supabase.instance.client.from('submissions').insert({
        'student_id': user.id,
        'course_id': int.parse(_selectedCourseId!),
        'module_number': _selectedModule,
        'file_path': filePath,
        'file_url': fileUrl,
        'status': 'submitted',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green),
        );
        setState(() {
          _pickedFile = null;
          _isUploading = false;
        });
        _fetchPreviousSubmissions();
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isUploading = false);
      }
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
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.submissions),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadCard(),
            const SizedBox(height: 24),
            const Text(
              'Your History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SubmissionsHub(submissions: _previousSubmissions),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'New Submission',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Course Selection
          const Text('Select Program', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _isLoadingCourses 
            ? const LinearProgressIndicator()
            : DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                items: _appliedCourses.map((c) => DropdownMenuItem(
                  value: c['id'].toString(),
                  child: Text(c['courseName'], overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (val) => setState(() => _selectedCourseId = val),
              ),
          const SizedBox(height: 20),

          // Module Selection
          const Text('Select Module', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedModule,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: [1, 2, 3, 4, 5].map((m) => DropdownMenuItem(
              value: m,
              child: Text('Module $m'),
            )).toList(),
            onChanged: (val) => setState(() => _selectedModule = val!),
          ),
          const SizedBox(height: 24),

          // File Picker
          InkWell(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(Icons.upload_file, size: 40, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    _pickedFile?.name ?? 'Tap to select PDF report',
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadSubmission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isUploading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Submit Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
