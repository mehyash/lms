import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'submissions_hub.dart';
import 'dashboard_models.dart';

class SubmissionsScreen extends StatelessWidget {
  const SubmissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final List<SubmissionItem> mockSubmissions = [
      SubmissionItem(name: 'Week 4 Report', status: SubmissionStatus.draft),
      SubmissionItem(name: 'Week 3 Report', status: SubmissionStatus.reviewed),
      SubmissionItem(name: 'Module 1 Assessment', status: SubmissionStatus.submitted),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Submissions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.submissions),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SubmissionsHub(submissions: mockSubmissions),
      ),
    );
  }
}
