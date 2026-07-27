class MeetingSummary {
  final String title;
  final DateTime date;
  final String summary;

  MeetingSummary({
    required this.title,
    required this.date,
    required this.summary,
  });
}

class ActionItem {
  final String title;
  final DateTime dueDate;
  bool isDone;

  ActionItem({
    required this.title,
    required this.dueDate,
    this.isDone = false,
  });
}

class SubmissionItem {
  final String name;
  final SubmissionStatus status;

  SubmissionItem({required this.name, required this.status});
}

enum SubmissionStatus { draft, submitted, reviewed }

class CalendarEvent {
  final String title;
  final DateTime date;
  final EventTag tag;

  CalendarEvent({required this.title, required this.date, required this.tag});
}

// Colour-codes events by which "hat" the intern is wearing across placements
enum EventTag { placementA, placementB, personal }
