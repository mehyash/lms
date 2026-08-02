import 'model.dart';
import 'profile_form_widgets.dart';

/// ---------------------------------------------------------------------
/// MESSAGES SCREEN
/// ---------------------------------------------------------------------
/// Reached from the drawer's "Messages" destination and the Home
/// "Quick Links -> Messages" shortcut. Two tabs:
///   - Inbox              -> searchable list of received messages
///   - Draft a Message    -> compose a message; "Send via Gmail" is a
///                            stub for the Gmail-redirect teammates to
///                            wire up (see _sendViaGmail below).
///
/// Frontend only — Inbox uses static/dummy data, and the draft compose
/// doesn't persist or send anywhere yet.
/// ---------------------------------------------------------------------
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _role = 'student';
  List<Map<String, dynamic>> _announcements = [];
  bool _isLoading = true;
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    _role = user?.userMetadata?['role'] ?? 'student';
    _tabController = TabController(length: 1, vsync: this);
    
    _fetchName();
    if (_role == 'student') {
      _fetchAnnouncements();
    } else {
      _isLoading = false;
    }

    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  Future<void> _fetchName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    String name = user.userMetadata?['full_name']?.split(' ')[0] ?? 
                 user.userMetadata?['first_name'] ?? 'User';
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select('first_name')
          .eq('id', user.id)
          .maybeSingle();
      if (res != null && res['first_name'] != null) name = res['first_name'];
    } catch (_) {}
    if (mounted) setState(() => _userName = name);
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      // Logic: Fetch all announcements where course_id is NULL (broadcast)
      // OR announcements where the student is enrolled.
      final res = await Supabase.instance.client
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _announcements = List<Map<String, dynamic>>.from(res);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching announcements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, $_userName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.pushReplacementNamed(context, isAdmin ? '/admin' : '/home');
            }
          },
        ),
      ),
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.messages),
      body: isAdmin 
          ? const _DraftMessageTab() 
          : RefreshIndicator(
              onRefresh: _fetchAnnouncements,
              child: _isLoading 
                  ? const Center(child: CircularProgressIndicator()) 
                  : _buildInboxTab(context),
            ),
    );
  }

  Widget _buildInboxTab(BuildContext context) {
    final filtered = _announcements.where((m) {
      final q = _query.toLowerCase();
      return m['title'].toString().toLowerCase().contains(q) || 
             m['content'].toString().toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) => _AnnouncementCard(data: filtered[i]),
                ),
        ),
      ],
    );
  }

  /// Search field with an animated clear (X) button, matching the same
  /// pattern used by the Program Listing search bar.
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: _query.isNotEmpty
                  ? IconButton(
                      key: const ValueKey('clear'),
                      icon: const Icon(Icons.close),
                      onPressed: () => _searchController.clear(),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mark_email_read_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('No messages match your search.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

/// One row in the Inbox list.
class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _AnnouncementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final DateTime createdAt = DateTime.parse(data['created_at']);
    final timeStr = "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("From: ${data['sender_name']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const Divider(height: 32),
                  Text(data['content'], style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.12),
                child: const Icon(Icons.campaign_outlined, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data['sender_name'] ?? 'Admin',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                        Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['title'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['content'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// DRAFT A MESSAGE TAB
/// ---------------------------------------------------------------------
/// Lets the user type up a To / Subject / Message draft. "Send via
/// Gmail" is intentionally a stub — per this sprint's scope, the
/// Gmail-redirect teammates are wiring up the actual handoff to Gmail
/// (e.g. a prefilled compose URL / mailto intent). This tab only needs
/// to hand off the three field values once that's ready.
/// ---------------------------------------------------------------------
class _DraftMessageTab extends StatefulWidget {
  const _DraftMessageTab();

  @override
  State<_DraftMessageTab> createState() => _DraftMessageTabState();
}

class _DraftMessageTabState extends State<_DraftMessageTab> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String? _selectedCourseId; // NULL means "All Students"
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final res = await Supabase.instance.client.from('Courses').select('id, courseName');
      setState(() {
        _courses = List<Map<String, dynamic>>.from(res);
        _isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint('Error fetching courses: $e');
      setState(() => _isLoadingCourses = false);
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
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
              title: 'Send New Announcement',
              subtitle: 'Broadcast messages to specific programs or all students instantly.',
            ),
            
            const Text('Select Recipients', style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _isLoadingCourses 
              ? const LinearProgressIndicator()
              : DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    filled: true,
                    fillColor: const Color(0xFFF0F2F5),
                  ),
                  hint: const Text('All Students'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Students')),
                    ..._courses.map((c) => DropdownMenuItem(
                      value: c['id'].toString(),
                      child: Text(c['courseName']),
                    )),
                  ],
                  onChanged: (val) => setState(() => _selectedCourseId = val),
                ),
            const SizedBox(height: 20),

            LabeledTextField(
              label: 'Subject',
              required: true,
              controller: _subjectController,
              icon: Icons.subject_rounded,
            ),
            LabeledTextField(
              label: 'Message',
              required: true,
              controller: _bodyController,
              icon: Icons.edit_note_rounded,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: _isSending ? null : _sendMessage,
                icon: _isSending 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
                label: Text(_isSending ? 'Sending...' : 'Send Broadcast'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_subjectController.text.isEmpty || _bodyController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both subject and message')));
      return;
    }

    setState(() => _isSending = true);

    try {
      // 1. Save to Supabase announcements table
      await Supabase.instance.client.from('announcements').insert({
        'title': _subjectController.text.trim(),
        'content': _bodyController.text.trim(),
        'course_id': _selectedCourseId != null ? int.parse(_selectedCourseId!) : null,
        'sender_name': 'Admin',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!'), backgroundColor: Colors.green),
        );
        _subjectController.clear();
        _bodyController.clear();
        setState(() {
          _selectedCourseId = null;
          _isSending = false;
        });
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isSending = false);
      }
    }
  }
}
