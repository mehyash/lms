import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

/// A single toggleable email preference category.
class _EmailPreference {
  final String title;
  final String description;
  bool enabled;

  _EmailPreference({required this.title, required this.description, required this.enabled});
}

/// ---------------------------------------------------------------------
/// EMAIL PREFERENCES SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Settings hub's "Email Preferences" menu item.
/// Each category applies instantly when toggled (standard settings-
/// switch UX) — there's no separate Save button, matching the
/// reference design.
///
/// Frontend only — toggles don't persist anywhere yet.
/// ---------------------------------------------------------------------
class EmailPreferencesScreen extends StatefulWidget {
  const EmailPreferencesScreen({super.key});

  @override
  State<EmailPreferencesScreen> createState() => _EmailPreferencesScreenState();
}

class _EmailPreferencesScreenState extends State<EmailPreferencesScreen> {
  final List<_EmailPreference> _preferences = [
    _EmailPreference(
      title: 'Marketing and Promotion',
      description:
          "You'll receive emails about exciting opportunities, featured programs, scholarships, "
          "internships and career opportunities available through Excelerate. These will help you "
          "discover new ways to enhance your learning experience and career prospects.",
      enabled: true,
    ),
    _EmailPreference(
      title: 'Importants',
      description:
          'These emails will keep you informed about critical updates, including application '
          'results, deadlines, and major platform changes. Make sure to check them, as they may '
          'require immediate action.',
      enabled: true,
    ),
    _EmailPreference(
      title: 'Reminder Emails',
      description:
          "You'll get gentle reminders about upcoming deadlines, pending tasks, or opportunities "
          "you've shown interest in. These emails will help you stay on track and make the most of "
          "your experience with Excelerate.",
      enabled: true,
    ),
    _EmailPreference(
      title: 'Guides And Updates',
      description:
          "You'll receive step-by-step guides, platform updates, career insights, and learning "
          "resources to help you navigate Excelerate smoothly and get the most out of your "
          "experiential learning journey.",
      enabled: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Email Preferences')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileFormHeader(
                  title: 'Email Preferences',
                  subtitle: "Choose the emails you'd like to receive:",
                ),
                for (int i = 0; i < _preferences.length; i++) ...[
                  _buildPreferenceCard(context, _preferences[i]),
                  if (i != _preferences.length - 1) const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreferenceCard(BuildContext context, _EmailPreference pref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pref.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  pref.description,
                  style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: pref.enabled,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (v) => setState(() => pref.enabled = v),
          ),
        ],
      ),
    );
  }
}
