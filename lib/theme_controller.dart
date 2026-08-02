import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// THEME CONTROLLER
/// ---------------------------------------------------------------------
/// App-wide light/dark mode switch. A single ValueNotifier that
/// ExcelerateApp listens to (see main.dart) to rebuild MaterialApp's
/// `themeMode`, and that the Appearance screen updates when the user
/// picks Light Mode or Dark Mode. Kept as a plain static notifier
/// (no state management package) since this is the only piece of
/// truly global UI state in the app right now.
/// ---------------------------------------------------------------------
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);
}
