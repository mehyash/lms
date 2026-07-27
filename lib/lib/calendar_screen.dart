import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'dashboard_calendar.dart';
import 'dashboard_models.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final List<CalendarEvent> mockEvents = [
      CalendarEvent(
          title: 'Standup',
          date: DateTime.now(),
          tag: EventTag.placementA),
      CalendarEvent(
          title: 'Design review',
          date: DateTime.now().add(const Duration(days: 2)),
          tag: EventTag.placementB),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.calendar),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DashboardCalendar(events: mockEvents),
      ),
    );
  }
}
