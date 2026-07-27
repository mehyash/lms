import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  Future<void> _markAsRegisteredAndNavigate() async {
    try {
      // Update user metadata so we know they've completed the form
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'form_completed': true},
        ),
      );
    } catch (e) {
      debugPrint('Error updating metadata: $e');
    }
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FormSubmitChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'submitted') {
            _markAsRegisteredAndNavigate();
          }
        },
      )
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            
            _controller.runJavaScript("""
              const observer = new MutationObserver((mutations) => {
                if (document.body.innerText.toLowerCase().includes('submitted') || 
                    document.body.innerText.toLowerCase().includes('recorded') ||
                    document.body.innerText.toLowerCase().includes('thank you')) {
                  FormSubmitChannel.postMessage('submitted');
                }
              });
              observer.observe(document.body, { childList: true, subtree: true });
              
              // Also check immediately in case it loaded already
              if (document.body.innerText.toLowerCase().includes('submitted') || 
                  document.body.innerText.toLowerCase().includes('recorded') ||
                  document.body.innerText.toLowerCase().includes('thank you')) {
                FormSubmitChannel.postMessage('submitted');
              }
            """);

            if (!url.contains('5ba7d362-ddb2-438a-9860-29ad6e72189b') && url != 'about:blank') {
               _markAsRegisteredAndNavigate();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (!request.url.contains('5ba7d362-ddb2-438a-9860-29ad6e72189b')) {
              _markAsRegisteredAndNavigate();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://gunaranjan.app.n8n.cloud/form/5ba7d362-ddb2-438a-9860-29ad6e72189b'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apply for Cohort'),
        backgroundColor: const Color(0xFFC41E2A),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          TextButton(
            onPressed: _markAsRegisteredAndNavigate,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFC41E2A),
              ),
            ),
        ],
      ),
    );
  }
}
