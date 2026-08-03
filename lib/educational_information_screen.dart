import 'package:flutter/material.dart';
import 'model.dart';
import 'profile_form_widgets.dart';

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
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _fetchEducation();
  }

  Future<void> _fetchEducation() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final res = await Supabase.instance.client
          .from('students')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (res != null && mounted) {
        setState(() {
          _currentStatus = res['current_status'];
          _institutionController.text = res['institution'] ?? '';
          _gradYearController.text = res['graduation_year']?.toString() ?? '';
          _major = res['major'];
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching education: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEducation() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('students').upsert({
        'id': user.id,
        'current_status': _currentStatus,
        'institution': _institutionController.text.trim(),
        'graduation_year': int.tryParse(_gradYearController.text.trim()),
        'major': _major,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Educational information saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving education: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

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
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
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
                  onSave: _saveEducation,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
