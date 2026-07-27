import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dashboard_models.dart';

class WeeklyActionables extends StatefulWidget {
  final List<ActionItem> items;

  const WeeklyActionables({super.key, required this.items});

  @override
  State<WeeklyActionables> createState() => _WeeklyActionablesState();
}

class _WeeklyActionablesState extends State<WeeklyActionables> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Week',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...widget.items.map((item) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: item.isDone,
                  title: Text(
                    item.title,
                    style: TextStyle(
                      decoration: item.isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Text('Due ${DateFormat('MMM d').format(item.dueDate)}'),
                  onChanged: (val) => setState(() => item.isDone = val ?? false),
                )),
          ],
        ),
      ),
    );
  }
}
