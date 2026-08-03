import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'model.dart';

class CurriculumAIScreen extends StatefulWidget {
  const CurriculumAIScreen({super.key});

  @override
  State<CurriculumAIScreen> createState() => _CurriculumAIScreenState();
}

class _CurriculumAIScreenState extends State<CurriculumAIScreen> {
  String? _selectedCourseId;
  String? _selectedCourseName;
  bool _isGenerating = false;
  String? _downloadMessage;
  List<Map<String, dynamic>> _supabaseCourses = [];
  bool _isLoadingCourses = true;
  String _userName = 'Admin';

  @override
  void initState() {
    super.initState();
    _fetchName();
    _fetchCourses();
  }

  Future<void> _fetchName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'Admin';
    if (mounted) setState(() => _userName = name);
  }

  Future<void> _fetchCourses() async {
    try {
      final response = await Supabase.instance.client.from('Courses').select();
      setState(() {
        _supabaseCourses = List<Map<String, dynamic>>.from(response);
        _isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  // Replace with your actual n8n webhook URL
  final String _n8nWebhookUrl = 'https://pgunaranjan.app.n8n.cloud/webhook/generate-course';

  Future<void> _generateCurriculum() async {
    if (_selectedCourseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program first')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _downloadMessage = 'Sending request to AI...';
    });

    try {
      debugPrint('AI Request URL: $_n8nWebhookUrl');
      final requestBody = json.encode({
        'programName': _selectedCourseName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      debugPrint('AI Request Body: $requestBody');

      // 1. Send request to n8n
      final response = await http.post(
        Uri.parse(_n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      debugPrint('AI Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        
        if (contentType != null && contentType.contains('application/pdf')) {
          // Webhook returned the PDF binary directly
          debugPrint('AI Response: PDF Binary detected');
          
          if (mounted) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PdfPreviewScreen(
                  pdfBytes: response.bodyBytes,
                  courseName: _selectedCourseName!,
                  courseId: _selectedCourseId!,
                ),
              ),
            );

            if (result == true) {
              setState(() => _downloadMessage = 'Curriculum published successfully!');
            } else {
              setState(() => _downloadMessage = 'Generation cancelled.');
            }
          }
        } else {
          // Webhook returned JSON with a URL
          debugPrint('AI Response Body: ${response.body}');
          final data = json.decode(response.body);
          final String? pdfUrl = data['pdfUrl'];

          if (pdfUrl != null && pdfUrl.isNotEmpty) {
            setState(() => _downloadMessage = 'Curriculum generated! Downloading for preview...');
            
            // Download the file to bytes using Dio
            final dio = Dio();
            final downloadRes = await dio.get<List<int>>(
              pdfUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            
            if (mounted && downloadRes.data != null) {
               final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(
                    pdfBytes: Uint8List.fromList(downloadRes.data!),
                    courseName: _selectedCourseName!,
                    courseId: _selectedCourseId!,
                  ),
                ),
              );
               if (result == true) {
                setState(() => _downloadMessage = 'Curriculum published successfully!');
              } else {
                setState(() => _downloadMessage = 'Generation cancelled.');
              }
            }
          } else {
            throw 'No PDF link or file received from AI service.';
          }
        }
      } else {
        debugPrint('AI Error Response Body: ${response.body}');
        throw 'Failed to connect to AI service (Status: ${response.statusCode}).';
      }
    } catch (e) {
      debugPrint('AI General Exception: $e');
      setState(() => _downloadMessage = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final role = user?.userMetadata?['role'];

    // Integrity check: if not admin, redirect back to home
    if (role != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/home');
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
              Navigator.pushReplacementNamed(context, '/admin');
            }
          },
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.curriculumAi),
      body: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.blue.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Generate Custom Curriculum',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select a program and our AI will generate a tailored learning path for you.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // Dropdown Menu
            _isLoadingCourses
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Select Program',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.school),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    value: _selectedCourseId,
                    items: _supabaseCourses.map((c) => DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['courseName'] as String, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) {
                      final course = _supabaseCourses.firstWhere((c) => c['id'].toString() == val);
                      setState(() {
                        _selectedCourseId = val;
                        _selectedCourseName = course['courseName'];
                      });
                    },
                  ),
            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generateCurriculum,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: _isGenerating
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      )
                    : const Text('Generate & Download PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            if (_downloadMessage != null) ...[
              const SizedBox(height: 24),
              Text(
                _downloadMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _downloadMessage!.contains('Error') ? Colors.red : Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
