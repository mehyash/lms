import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

/// ---------------------------------------------------------------------
/// EDUCATIONAL INFORMATION SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Profile hub's "Educational Information" menu item.
/// Lets the user set their current status, institution, graduation
/// year, and major.
///
/// Frontend only — Save Changes just confirms via a SnackBar and pops
/// back to Profile; there is no backend to persist to yet.
/// ---------------------------------------------------------------------
class EducationalInformationScreen extends StatefulWidget {
  const EducationalInformationScreen({super.key});

  @override
  State<EducationalInformationScreen> createState() => _EducationalInformationScreenState();
}

class _EducationalInformationScreenState extends State<EducationalInformationScreen> {
  final _institutionController = TextEditingController();
  final _gradYearController = TextEditingController();

  String? _currentStatus;
  String? _major;

  static const _statusOptions = [
    'High School Student',
    'Undergraduate Student',
    'Graduate Student',
    'Working Professional',
    'Other',
  ];

  static const _majorOptions = [
    'Computer Science',
    'Business Administration',
    'Engineering',
    'Design',
    'Others',
  ];

  @override
  void dispose() {
    _institutionController.dispose();
    _gradYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Educational Information')),
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
                  title: 'Educational Information',
                  subtitle: 'Update your educational information',
                ),
                const Text(
                  '* All fields are mandatory to fill.',
                  style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                LabeledDropdown(
                  label: 'What best describes you currently?',
                  required: true,
                  value: _currentStatus,
                  options: _statusOptions,
                  icon: Icons.badge_outlined,
                  onChanged: (v) => setState(() => _currentStatus = v),
                ),
                LabeledTextField(
                  label: 'Institution Name',
                  required: true,
                  controller: _institutionController,
                  icon: Icons.account_balance_outlined,
                ),
                LabeledTextField(
                  label: 'Year of Graduation',
                  required: true,
                  controller: _gradYearController,
                  icon: Icons.school_outlined,
                  keyboardType: TextInputType.number,
                ),
                LabeledDropdown(
                  label: 'Current Major',
                  required: true,
                  value: _major,
                  options: _majorOptions,
                  icon: Icons.menu_book_outlined,
                  onChanged: (v) => setState(() => _major = v),
                  trailingLabelAction: Tooltip(
                    message: 'Choose the major closest to your field of study',
                    child: Icon(Icons.info_outline_rounded, size: 15, color: Colors.grey.shade500),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    '(Choose Others, if major is missing)',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  ),
                ),
                FormActionButtons(
                  onCancel: () => Navigator.pop(context),
                  onSave: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Educational information saved')),
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
}
