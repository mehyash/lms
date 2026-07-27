import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

/// ---------------------------------------------------------------------
/// PERSONAL INFORMATION SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Profile hub's "Personal Information" menu item.
/// Lets the user review/update their avatar, name, date of birth,
/// gender, contact info, and permanent address.
///
/// Frontend only — Save Changes just confirms via a SnackBar and pops
/// back to Profile; there is no backend to persist to yet.
/// ---------------------------------------------------------------------
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final _nameController = TextEditingController(text: 'Haasini Kunamneni');
  final _dobController = TextEditingController();
  final _phoneController = TextEditingController();
  final _altEmailController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipController = TextEditingController();

  String? _gender;
  bool _nameLocked = true;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _altEmailController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2003, 1, 1),
      firstDate: DateTime(1960),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
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
                  title: 'Personal Information',
                  subtitle: 'Update your personal information',
                ),
                const Text(
                  '* All fields are mandatory to fill.',
                  style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                const ProfileSectionLabel('User Info'),
                Center(child: _buildAvatarPicker(context)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Allowed file types: png, jpg, jpeg.',
                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(height: 20),
                LabeledTextField(
                  label: 'Name',
                  required: true,
                  controller: _nameController,
                  icon: Icons.badge_outlined,
                  readOnly: _nameLocked,
                  trailingLabelAction: TextButton.icon(
                    onPressed: () => setState(() => _nameLocked = !_nameLocked),
                    icon: Icon(_nameLocked ? Icons.edit_outlined : Icons.check_rounded, size: 15),
                    label: Text(_nameLocked ? 'Edit Name' : 'Done', style: const TextStyle(fontSize: 12.5)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  ),
                ),
                LabeledTextField(
                  label: 'Date of Birth',
                  required: true,
                  controller: _dobController,
                  icon: Icons.calendar_today_outlined,
                  readOnly: true,
                  onTap: _pickDob,
                ),
                LabeledDropdown(
                  label: 'Gender',
                  required: true,
                  value: _gender,
                  options: const ['Female', 'Male', 'Non-binary', 'Prefer not to say'],
                  icon: Icons.wc_outlined,
                  onChanged: (v) => setState(() => _gender = v),
                ),
                const ProfileSectionLabel('Contact Info'),
                LabeledTextField(
                  label: 'Contact Phone',
                  required: true,
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                LabeledTextField(
                  label: 'Alternate Email Address',
                  controller: _altEmailController,
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const ProfileSectionLabel('Permanent Address Info'),
                LabeledTextField(
                  label: 'Address Line 1',
                  required: true,
                  controller: _address1Controller,
                  icon: Icons.home_outlined,
                ),
                LabeledTextField(
                  label: 'Address Line 2',
                  controller: _address2Controller,
                  icon: Icons.badge_outlined,
                ),
                LabeledTextField(
                  label: 'City',
                  required: true,
                  controller: _cityController,
                  icon: Icons.location_city_outlined,
                ),
                LabeledTextField(
                  label: 'State',
                  required: true,
                  controller: _stateController,
                  icon: Icons.account_balance_outlined,
                ),
                LabeledTextField(
                  label: 'Country of Nationality',
                  required: true,
                  controller: _countryController,
                  icon: Icons.public_outlined,
                ),
                LabeledTextField(
                  label: 'Zip Code',
                  required: true,
                  controller: _zipController,
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                FormActionButtons(
                  onCancel: () => Navigator.pop(context),
                  onSave: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Personal information saved')),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primary, primary.withOpacity(0.6)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 44),
        ),
        Positioned(top: -6, right: -6, child: _avatarActionButton(icon: Icons.edit_outlined, onTap: () => _showAvatarComingSoon(context))),
        Positioned(bottom: -6, right: -6, child: _avatarActionButton(icon: Icons.close_rounded, onTap: () => _showAvatarComingSoon(context))),
      ],
    );
  }

  void _showAvatarComingSoon(BuildContext context) {
    // TODO (Future Team): wire up a real image picker + upload once
    // backend/file storage support exists.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload coming soon')),
    );
  }

  Widget _avatarActionButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4)],
        ),
        child: Icon(icon, size: 14, color: Colors.grey.shade700),
      ),
    );
  }
}
