import 'package:flutter/material.dart';
import 'theme_controller.dart';
import 'profile_form_widgets.dart';

/// ---------------------------------------------------------------------
/// APPEARANCE SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Settings hub's "Appearance" menu item. Lets the
/// user switch between Light Mode and Dark Mode. This one is fully
/// functional — selecting an option updates [ThemeController.mode],
/// which ExcelerateApp listens to and applies app-wide immediately.
///
/// Note: card backgrounds and the Scaffold background across the app
/// already respond to this (see main.dart's light/dark ThemeData), but
/// a few older screens still use fixed accent/chip colors that haven't
/// been re-tuned for dark backgrounds yet — a good follow-up for
/// whoever picks up full dark-theme polish next.
/// ---------------------------------------------------------------------
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
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
                  title: 'Appearance',
                  subtitle: 'Choose how Excelerate looks on this device.',
                ),
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: ThemeController.mode,
                  builder: (context, currentMode, _) {
                    return Column(
                      children: [
                        _ModeOption(
                          icon: Icons.light_mode_outlined,
                          title: 'Light Mode',
                          description: 'Bright background with dark text.',
                          selected: currentMode == ThemeMode.light,
                          onTap: () => ThemeController.mode.value = ThemeMode.light,
                        ),
                        const SizedBox(height: 12),
                        _ModeOption(
                          icon: Icons.dark_mode_outlined,
                          title: 'Dark Mode',
                          description: 'Dark background that\'s easier on the eyes at night.',
                          selected: currentMode == ThemeMode.dark,
                          onTap: () => ThemeController.mode.value = ThemeMode.dark,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? primary.withOpacity(isDark ? 0.18 : 0.08)
              : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF0F2F5)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? primary : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? primary : Colors.grey.shade600),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? primary : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
