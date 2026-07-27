import 'package:flutter/material.dart';
import 'dashboard_models.dart';

class SubmissionsHub extends StatelessWidget {
  final List<SubmissionItem> submissions;

  const SubmissionsHub({super.key, required this.submissions});

  Color _statusColor(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.draft:
        return Colors.orange;
      case SubmissionStatus.submitted:
        return Colors.blue;
      case SubmissionStatus.reviewed:
        return Colors.green;
    }
  }

  String _statusLabel(SubmissionStatus status) {
    switch (status) {
      case SubmissionStatus.draft:
        return 'Draft';
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.reviewed:
        return 'Reviewed';
    }
  }

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
                const Text('Submissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {}, // hook up: new submission flow
                ),
              ],
            ),
            ...submissions.map((s) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description_outlined),
                  title: Text(s.name),
                  trailing: Chip(
                    label: Text(
                      _statusLabel(s.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _statusColor(s.status),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
