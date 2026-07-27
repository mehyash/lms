import 'package:flutter/material.dart';
import 'app_drawer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final List<String> _filters = ['All', 'In-Progress', 'Completed', 'Pending Review'];
  String _activeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.settings), // Reusing Settings slot for now
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP ANALYTICS OVERVIEW ---
            Row(
              children: [
                _buildStatCard('Active Interns', '124', Colors.blue),
                const SizedBox(width: 12),
                _buildStatCard('Pending Submissions', '18', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),

            // --- QUICK ACTIONS: ANNOUNCEMENTS & MEETINGS ---
            const Text('Management Tools', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildActionButton(
                  context,
                  'Post Announcement',
                  Icons.campaign_rounded,
                  Colors.purple,
                  () => _showAnnouncementDialog(context),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  context,
                  'Schedule Meeting',
                  Icons.calendar_month_rounded,
                  Colors.teal,
                  () => _showScheduleDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- CURRICULUM AI (N8N) ---
            _buildCurriculumAICard(),
            const SizedBox(height: 24),

            // --- INTERNSHIP & STUDENT SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Student Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: _activeFilter,
                  items: _filters.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
                  onChanged: (val) => setState(() => _activeFilter = val!),
                  underline: const SizedBox(),
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStudentList(),
            const SizedBox(height: 24),

            // --- DRAFTS / TEMPLATES ---
            const Text('Report Templates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTemplateSection(),
          ],
        ),
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
          border: Border.all(color: color.withOpacity(0.2), width: 2),
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
            color: color.withOpacity(0.1),
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

  Widget _buildCurriculumAICard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.white),
              SizedBox(width: 10),
              Text('Curriculum AI (n8n Power)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Automatically generate curriculum paths and modules based on industry trends.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/curriculum-ai'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.purple),
            child: const Text('Configure AI Flow'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    final List<Map<String, String>> students = [
      {'name': 'Arjun Mehta', 'program': 'UI/UX Design', 'status': 'Pending Review'},
      {'name': 'Sarah Khan', 'program': 'Data Analytics', 'status': 'In-Progress'},
      {'name': 'Rahul Verma', 'program': 'Prompt Eng.', 'status': 'Completed'},
    ];

    return Column(
      children: students.map((s) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(s['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(s['program']!),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: s['status'] == 'Completed' ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(s['status']!, style: TextStyle(fontSize: 11, color: s['status'] == 'Completed' ? Colors.green : Colors.orange)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTemplateSection() {
    return Column(
      children: [
        _templateItem('Weekly Report Format', 'PDF/DOCX'),
        _templateItem('Final Project Proposal', 'Interactive'),
        _templateItem('Exit Interview Draft', 'Form'),
      ],
    );
  }

  Widget _templateItem(String title, String type) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.insert_drive_file_outlined),
      title: Text(title),
      subtitle: Text('Type: $type'),
      trailing: IconButton(icon: const Icon(Icons.edit_note_rounded), onPressed: () {}),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Announcement'),
        content: const TextField(
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Type your message to all students...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Post')),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(decoration: InputDecoration(labelText: 'Meeting Title')),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: 'Date & Time')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Schedule')),
        ],
      ),
    );
  }
}
