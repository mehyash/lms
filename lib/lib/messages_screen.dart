import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'profile_form_widgets.dart';

/// A single dummy inbox message.
class _Message {
  final String sender;
  final String subject;
  final String preview;
  final String time;
  final bool unread;

  const _Message({
    required this.sender,
    required this.subject,
    required this.preview,
    required this.time,
    this.unread = false,
  });
}

const List<_Message> _dummyMessages = [
  _Message(
    sender: 'Excelerate Team',
    subject: 'Welcome to Excelerate!',
    preview: "We're excited to have you onboard — here's how to get started.",
    time: '9:02 AM',
    unread: true,
  ),
  _Message(
    sender: 'Mentor - Aditi Rao',
    subject: 'Feedback on your submission',
    preview: 'Great work on the last milestone — a few notes before the next one.',
    time: 'Yesterday',
    unread: true,
  ),
  _Message(
    sender: 'Program Coordinator',
    subject: 'Orientation reminder',
    preview: "Don't forget tomorrow's orientation session at 10:00 AM.",
    time: 'Mon',
  ),
  _Message(
    sender: 'Support',
    subject: 'Your ticket has been resolved',
    preview: "Thanks for reaching out — we've fixed the issue you reported.",
    time: 'Last week',
  ),
];

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_Message> get _filteredMessages {
    if (_query.isEmpty) return _dummyMessages;
    return _dummyMessages.where((m) {
      return m.sender.toLowerCase().contains(_query) ||
          m.subject.toLowerCase().contains(_query) ||
          m.preview.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        bottom: TabBar(
          controller: _tabController,
          // Same pill-style indicator used on Programs, for consistency.
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Inbox', icon: Icon(Icons.inbox_outlined, size: 18)),
            Tab(text: 'Draft a Message', icon: Icon(Icons.edit_note_rounded, size: 18)),
          ],
        ),
      ),
      // Messages is a primary drawer destination, so it gets the same
      // shared drawer as Home/Programs, with "Messages" highlighted.
      drawer: const AppDrawer(currentDestination: AppDrawerDestination.messages),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInboxTab(context),
          const _DraftMessageTab(),
        ],
      ),
    );
  }

  Widget _buildInboxTab(BuildContext context) {
    final messages = _filteredMessages;
    return Column(
      children: [
        _buildSearchBar(context),
        Expanded(
          child: messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: messages.length,
                  itemBuilder: (context, i) => _MessageCard(message: messages[i]),
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
class _MessageCard extends StatelessWidget {
  final _Message message;

  const _MessageCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
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
          // TODO (Future Team): open the full message thread once a
          // thread/detail view exists.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message thread view coming soon')),
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
                child: Text(
                  message.sender.isNotEmpty ? message.sender[0] : '?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary),
                ),
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
                            message.sender,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: message.unread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(message.time, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      message.subject,
                      style: TextStyle(
                        fontWeight: message.unread ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (message.unread) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
                  ),
                ),
              ],
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
  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _toController.dispose();
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
              title: 'Draft a Message',
              subtitle: 'Compose your message here — sending it opens Gmail with everything filled in.',
            ),
            LabeledTextField(
              label: 'To',
              required: true,
              controller: _toController,
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _discardDraft,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Discard'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                      foregroundColor: Colors.grey.shade800,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _sendViaGmail(context),
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send via Gmail'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _discardDraft() {
    _toController.clear();
    _subjectController.clear();
    _bodyController.clear();
  }

  void _sendViaGmail(BuildContext context) {
    // TODO (Gmail-integration teammates):
    // Replace this stub with the real redirect into Gmail, prefilled
    // with the drafted fields above — e.g. launching a Gmail compose
    // URL or a `mailto:` intent (via url_launcher) built from
    // _toController.text, _subjectController.text, and
    // _bodyController.text. Keep the surrounding UI/validation as-is;
    // only this action needs to be wired up to the real redirect.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gmail redirect coming soon')),
    );
  }
}
