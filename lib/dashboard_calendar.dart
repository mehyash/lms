import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './dashboard_models.dart';

class DashboardCalendar extends StatelessWidget {
  final List<CalendarEvent> events;

  const DashboardCalendar({super.key, required this.events});

  Color _tagColor(EventTag tag) {
    switch (tag) {
      case EventTag.placementA:
        return const Color(0xFF3D5AFE);
      case EventTag.placementB:
        return const Color(0xFF00BFA5);
      case EventTag.personal:
        return const Color(0xFFFF6D00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = List.generate(7, (i) => today.add(Duration(days: i)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Week',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: weekDays.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final day = weekDays[i];
                  final dayEvents = events
                      .where((e) =>
                          e.date.year == day.year &&
                          e.date.month == day.month &&
                          e.date.day == day.day)
                      .toList();

                  return Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: i == 0
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(day),
                            style: const TextStyle(fontSize: 11)),
                        Text(DateFormat('d').format(day),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 2,
                          children: dayEvents
                              .map((e) => Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: _tagColor(e.tag),
                                      shape: BoxShape.circle,
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
