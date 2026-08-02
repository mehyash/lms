import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'model.dart';

class CurriculumAIScreen extends StatefulWidget {
  const CurriculumAIScreen({super.key});

  @override
  State<CurriculumAIScreen> createState() => _CurriculumAIScreenState();
}

class _CurriculumAIScreenState extends State<CurriculumAIScreen> {
  String? _selectedProgram;
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
  final String _n8nWebhookUrl = 'https://gunaranjan.app.n8n.cloud/webhook/curriculum-gen';

  Future<void> _generateCurriculum() async {
    if (_selectedProgram == null) {
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
      // 1. Send request to n8n
      final response = await http.post(
        Uri.parse(_n8nWebhookUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'programName': _selectedProgram,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? pdfUrl = data['pdfUrl']; // Expecting n8n to return a 'pdfUrl' key

        if (pdfUrl != null && pdfUrl.isNotEmpty) {
          setState(() => _downloadMessage = 'Curriculum generated! Downloading PDF...');
          await _downloadFile(pdfUrl);
        } else {
          throw 'No PDF link received from AI service.';
        }
      } else {
        throw 'Failed to connect to AI service (Status: ${response.statusCode})';
      }
    } catch (e) {
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

  Future<void> _downloadFile(String url) async {
    try {
      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'Curriculum_${_selectedProgram?.replaceAll(' ', '_')}.pdf';
      final filePath = '${dir.path}/$fileName';

      await dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadMessage = 'Downloading: ${(received / total * 100).toStringAsFixed(0)}%';
            });
          }
        },
      );

      setState(() => _downloadMessage = 'Saved to: $fileName');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded successfully!'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                final Uri uri = Uri.file(filePath);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  // Fallback for some platforms: try launching the original URL
                  await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      throw 'Download failed: $e';
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
                    value: _selectedProgram,
                    items: _supabaseCourses.map((c) => DropdownMenuItem(
                      value: c['courseName'] as String,
                      child: Text(c['courseName'] as String, overflow: TextOverflow.ellipsis),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedProgram = val),
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
