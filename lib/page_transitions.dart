import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// SHARED PAGE TRANSITION HELPER
/// ---------------------------------------------------------------------
/// Centralizes the fade + slide-up transition originally written inline
/// inside OpportunitiesPreview ("View All" button) so the same animated
/// navigation feel can be reused anywhere in the app (Drawer, Quick
/// Links, opportunity rows, etc.) without duplicating the PageRouteBuilder.
/// ---------------------------------------------------------------------
Route<T> fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.05),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
