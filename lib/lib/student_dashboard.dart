import 'package:flutter/material.dart';
import 'dashboard_models.dart';
import 'meeting_widget.dart';
import '/weekly_actionables.dart';
import 'submissions_hub.dart';
import 'dashboard_calendar.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  // TEMP mock data — replace with real data from your backend / n8n workflows.
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hi, Alex 👋'),
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
            onPressed: () {}, // hook up: notifications feed
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
            const SizedBox(height: 80), // room above FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // hook up: chatbot sheet/screen
        icon: const Icon(Icons.chat_bubble_outline),
        label: const Text('Ask'),
      ),
    );
  }
}
