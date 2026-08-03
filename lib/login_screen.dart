import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  String _selectedRole = 'student';
  final _usernameController = TextEditingController(text: 'admin@gmail.com');
  final _passwordController = TextEditingController(text: 'password123');
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isRedirecting = false;

  // Removed hardcoded masterAdminId - now checking Admins table in Supabase

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted || _isRedirecting) return;
      
      final Session? session = data.session;
      if (session != null) {
        final user = session.user;
        debugPrint('Auth State Change: ${user.email}');
        
        // DATABASE CHECK: Only emails in the 'Admins' table can be admins
        // Using .ilike for case-insensitive matching
        final adminCheck = await Supabase.instance.client
            .from('Admins')
            .select()
            .ilike('Email', user.email!)
            .maybeSingle();

        final bool isActuallyAdmin = adminCheck != null;
        debugPrint('Listener Check - Is Admin? $isActuallyAdmin');
        
        // If they are in the Admins table, we prioritize the Admin role
        // unless they specifically selected 'student' on the login screen
        final String role = isActuallyAdmin ? 'admin' : 'student';
        debugPrint('Listener Check - Assigned Role: $role');

        if (role == 'admin') {
          _isRedirecting = true;
          // Ensure role is updated in metadata for other screens
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'role': 'admin'}),
          );
          if (mounted) {
            debugPrint('Redirecting to /admin');
            Navigator.pushReplacementNamed(context, '/admin');
          }
          return;
        }
        
        // If not admin, proceed with student flow
        _isRedirecting = true;
        debugPrint('Redirecting to Student flow');
        final bool formCompleted = user.userMetadata?['form_completed'] == true;

        if (formCompleted) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // If not completed, check if it's a new user as a secondary check
          final createdAt = DateTime.parse(user.createdAt);
          final lastSignIn = user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null;
          
          // Use a small buffer to determine if it's a very first sign-in
          bool isNewUser = lastSignIn == null || lastSignIn.difference(createdAt).inSeconds.abs() < 10;

          if (isNewUser) {
            Navigator.pushReplacementNamed(context, '/registration');
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // Prevent the auth listener from taking over navigation during this flow
      _isRedirecting = true;

      // 1. Try Native Google Sign In first (the "popup" experience on Android)
      if (!kIsWeb && Platform.isAndroid) {
        const webClientId = '23593043956-qtpub2karpff4rltg7qf3aqrr2h1426t.apps.googleusercontent.com';

        final GoogleSignIn googleSignIn = GoogleSignIn(
          serverClientId: webClientId,
        );
        
        // Force account selection by signing out first
        await googleSignIn.signOut();
        
        final googleUser = await googleSignIn.signIn();
        final googleAuth = await googleUser?.authentication;
        final accessToken = googleAuth?.accessToken;
        final idToken = googleAuth?.idToken;

        if (accessToken == null || idToken == null) {
          _isRedirecting = false;
          throw 'No Access Token or ID Token found.';
        }

        final AuthResponse response = await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (response.user != null) {
          final user = response.user!;
          debugPrint('Google Login Success: ${user.email}');

          // DATABASE CHECK: Verify if the user's email exists in the Admins table
          final adminCheck = await Supabase.instance.client
              .from('Admins')
              .select()
              .ilike('Email', user.email!)
              .maybeSingle();
          
          final bool isActuallyAdmin = adminCheck != null;
          debugPrint('Is Email in Admin table? $isActuallyAdmin');
          debugPrint('Role Selected on Screen: $_selectedRole');

          final roleToAssign = (isActuallyAdmin && _selectedRole == 'admin') ? 'admin' : 'student';
          debugPrint('Assigning Role: $roleToAssign');
          
          if (_selectedRole == 'admin' && !isActuallyAdmin) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Access Denied: Your email is not in the Admin database.'), backgroundColor: Colors.red),
              );
            }
          }

          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'role': roleToAssign}),
          );

          if (mounted) {
            if (roleToAssign == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin');
            } else {
              // Student flow logic duplicated from listener
              final bool formCompleted = user.userMetadata?['form_completed'] == true;
              if (formCompleted) {
                Navigator.pushReplacementNamed(context, '/home');
              } else {
                final createdAt = DateTime.parse(user.createdAt);
                final lastSignIn = user.lastSignInAt != null ? DateTime.parse(user.lastSignInAt!) : null;
                bool isNewUser = lastSignIn == null || lastSignIn.difference(createdAt).inSeconds.abs() < 10;
                
                if (isNewUser) {
                  Navigator.pushReplacementNamed(context, '/registration');
                } else {
                  Navigator.pushReplacementNamed(context, '/home');
                }
              }
            }
          }
        }
      } else {
        // 2. Fallback to OAuth Redirect for iOS, Web, etc.
        // We set _isRedirecting to false because we're leaving the app
        _isRedirecting = false;
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'https://symnszfbwkhldwoeukyg.supabase.co/auth/v1/callback',
          queryParams: {
            'role': _selectedRole,
            'prompt': 'select_account', // Forces Google to ask for account selection
          },
        );
      }
    } catch (error) {
      _isRedirecting = false;
      debugPrint('Google Sign-In Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static const Color primaryRed = Color(0xFFC41E2A);
  static const Color darkBrown = Color(0xFF3D2B25);
  static const Color fieldFill = Color(0xFFF3EDEE);
  static const Color fieldBorder = Color(0xFFE8B4B8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEDED),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fieldBorder, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo
                    Center(
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                          children: [
                            TextSpan(
                                text: 'Intern',
                                style: TextStyle(color: Color(0xFFE07A2E))),
                            TextSpan(
                                text: 'L',
                                style: TextStyle(color: Color(0xFFD6336C))),
                            TextSpan(
                                text: 'i',
                                style: TextStyle(color: Color(0xFFD6336C))),
                            TextSpan(
                                text: 'nk',
                                style: TextStyle(color: Color(0xFFD6336C))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Title
                    const Text(
                      'InternLink',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // Subtitle
                    const Text(
                      'Bridge the gap between student\nlife and professional success.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                    ),
                    const SizedBox(height: 28),

                    // Role selection
                    const Text('Login as',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                            value: 'student',
                            label: Text('Student'),
                            icon: Icon(Icons.school_outlined)),
                        ButtonSegment<String>(
                            value: 'admin',
                            label: Text('Admin'),
                            icon: Icon(Icons.admin_panel_settings_outlined)),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: primaryRed,
                        selectedForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Username label + field
                    const Text('Username',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'intern.name@college.edu',
                        hintStyle: const TextStyle(color: Colors.black38),
                        prefixIcon:
                            const Icon(Icons.person_outline, color: darkBrown),
                        filled: true,
                        fillColor: fieldFill,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: fieldBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password label + field
                    const Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkBrown,
                            fontSize: 15)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline, color: darkBrown),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: fieldBorder,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: fieldFill,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: fieldBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: fieldBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: primaryRed),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot password?',
                            style: TextStyle(
                                color: primaryRed, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Login button -> navigates to Home Screen
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            final response = await Supabase.instance.client.auth.signInWithPassword(
                              email: _usernameController.text.trim(),
                              password: _passwordController.text.trim(),
                            );
                            
                            if (response.user != null) {
                              // DATABASE CHECK: Verify if the user's email exists in the Admins table
                              final adminCheck = await Supabase.instance.client
                                  .from('Admins')
                                  .select()
                                  .ilike('Email', response.user!.email!)
                                  .maybeSingle();

                              final bool isActuallyAdmin = adminCheck != null;
                              final roleToAssign = (isActuallyAdmin && _selectedRole == 'admin') ? 'admin' : 'student';

                              if (_selectedRole == 'admin' && !isActuallyAdmin) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Access Denied: You are not registered as an Admin.'), backgroundColor: Colors.red),
                                  );
                                }
                              }

                              await Supabase.instance.client.auth.updateUser(
                                UserAttributes(data: {'role': roleToAssign}),
                              );
                              // Auth listener will handle redirection
                            }
                          } catch (error) {
                            // Before redirecting to registration, check if it's an admin email
                            try {
                              final email = _usernameController.text.trim();
                              final adminCheck = await Supabase.instance.client
                                  .from('Admins')
                                  .select()
                                  .ilike('Email', email)
                                  .maybeSingle();

                              if (adminCheck != null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Admin account not found. Please sign up or contact support.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                return;
                              }
                            } catch (_) {}

                            // If not an admin, redirect to n8n form
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('User not found. Redirecting to application form...'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              Navigator.pushReplacementNamed(context, '/registration');
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryRed,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Login',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            SizedBox(width: 8),
                            Icon(Icons.login, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // OR divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: fieldBorder, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR',
                              style: TextStyle(
                                  color: Colors.black45, fontWeight: FontWeight.bold)),
                        ),
                        const Expanded(child: Divider(color: fieldBorder, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                            child: _SocialButton(
                                icon: Icons.email_outlined,
                                label: 'Gmail',
                                onTap: _handleGoogleSignIn)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _SocialButton(
                                icon: Icons.code,
                                label: 'GitHub',
                                onTap: () {})),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _SocialButton(
                                icon: Icons.badge_outlined,
                                label: 'LinkedIn',
                                onTap: () {})),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Sign up
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/registration'),
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black87, fontSize: 14),
                          children: [
                            TextSpan(text: "Don't have an account? "),
                            TextSpan(
                              text: 'Apply for Cohort',
                              style:
                                  TextStyle(color: primaryRed, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Help footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.help_outline, size: 16, color: Colors.black54),
                  SizedBox(width: 6),
                  Text('Need help? Contact Program Support',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Color(0xFFE8B4B8)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF3D2B25)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF3D2B25),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
