import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_models.dart';

class MeetingWidget extends StatelessWidget {
  final List<MeetingSummary> meetings;

  const MeetingWidget({super.key, required this.meetings});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Meetings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/calendar'), 
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ...meetings.take(2).map((m) => _MeetingTile(meeting: m)),
          ],
        ),
      ),
    );
  }
}

class _MeetingTile extends StatelessWidget {
  final MeetingSummary meeting;
  const _MeetingTile({required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(meeting.title,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Text(
                DateFormat('MMM d').format(meeting.date),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            meeting.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
