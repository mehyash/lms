import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'student_dashboard.dart';
import 'admin_dashboard.dart';
import 'curriculum_ai_screen.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://symnszfbwkhldwoeukyg.supabase.co',
    anonKey: 'sb_publishable_3z-EMwDx7P7VGOjfCCSyQg_wyAQ6WtB', // TODO: Replace with your actual Anon Key
  );

  runApp(const ExcelerateApp());
}

class ExcelerateApp extends StatelessWidget {
  const ExcelerateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excelerate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        useMaterial3: true,
      ),
      // Login is the entry point of the app.
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/registration': (context) => const RegistrationScreen(),
        '/dashboard': (context) => const StudentDashboard(),
        '/admin': (context) => const AdminDashboard(),
        '/curriculum-ai': (context) => const CurriculumAIScreen(),
      },
    );
  }
}

// ---------------------------------------------------------------------
// NOTE FOR LOGIN TEAMMATE:
// Inside login_screen.dart, in the login button's onPressed, after your
// existing auth check succeeds, add this ONE line:
//
//   Navigator.pushReplacementNamed(context, '/home');
//
// pushReplacementNamed (not pushNamed) removes Login from the nav stack
// so the back button can't return to it after a successful login.
// ---------------------------------------------------------------------
