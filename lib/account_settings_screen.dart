import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

/// ---------------------------------------------------------------------
/// ACCOUNT SETTINGS SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Profile hub's "Account Settings" menu item.
/// Covers changing the account password and deleting the account.
///
/// Frontend only — Save Changes / Delete Account just confirm via a
/// SnackBar / dialog; there is no backend to call yet.
/// ---------------------------------------------------------------------
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _verifyPasswordController = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showVerify = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _verifyPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                      title: 'Change Password',
                      subtitle: 'Change your account password',
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.red.shade400, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The users are recommended to change their password on a regular basis for security reasons',
                              style: TextStyle(fontSize: 12.5, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    LabeledTextField(
                      label: 'Current Password',
                      required: true,
                      controller: _currentPasswordController,
                      icon: Icons.visibility_outlined,
                      obscureText: !_showCurrent,
                      obscureToggle: IconButton(
                        icon: Icon(
                          _showCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => setState(() => _showCurrent = !_showCurrent),
                      ),
                    ),
                    LabeledTextField(
                      label: 'New Password',
                      required: true,
                      controller: _newPasswordController,
                      icon: Icons.visibility_outlined,
                      obscureText: !_showNew,
                      obscureToggle: IconButton(
                        icon: Icon(
                          _showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => setState(() => _showNew = !_showNew),
                      ),
                      trailingLabelAction: Tooltip(
                        message: 'At least 8 characters, one number and one symbol',
                        child: Icon(Icons.help_outline_rounded, size: 15, color: Colors.grey.shade500),
                      ),
                    ),
                    LabeledTextField(
                      label: 'Verify Password',
                      required: true,
                      controller: _verifyPasswordController,
                      icon: Icons.visibility_outlined,
                      obscureText: !_showVerify,
                      obscureToggle: IconButton(
                        icon: Icon(
                          _showVerify ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          size: 19,
                          color: Colors.grey.shade600,
                        ),
                        onPressed: () => setState(() => _showVerify = !_showVerify),
                      ),
                      trailingLabelAction: Tooltip(
                        message: 'Must match the new password',
                        child: Icon(Icons.help_outline_rounded, size: 15, color: Colors.grey.shade500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FormActionButtons(
                      onCancel: () => Navigator.pop(context),
                      onSave: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated')),
                        );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Delete Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Deleting your account is permanent and cannot be undone',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => _confirmDelete(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red.shade600,
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Delete Account'),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This action is permanent and cannot be undone. Are you sure you want to delete your account?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO (Future Team): call the real delete-account API,
              // then sign the user out and clear the nav stack.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion requested')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
