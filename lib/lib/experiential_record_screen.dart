import 'package:flutter/material.dart';
import 'profile_form_widgets.dart';

/// A single field that can be included on the public experiential
/// record. Mandatory fields are always included and can't be unchecked.
class _RecordField {
  final String label;
  final bool mandatory;
  bool included;

  _RecordField({required this.label, this.mandatory = false, required this.included});
}

/// ---------------------------------------------------------------------
/// MY EXPERIENTIAL RECORD SCREEN
/// ---------------------------------------------------------------------
/// Reached from the Settings hub's "My Experiential Record" menu item.
/// Lets the user choose which of their fields appear on their
/// experiential record, and whether the record is openly verifiable.
///
/// Frontend only — Save just confirms via a SnackBar and pops back to
/// Settings; there is no backend to persist to yet.
/// ---------------------------------------------------------------------
class ExperientialRecordScreen extends StatefulWidget {
  const ExperientialRecordScreen({super.key});

  @override
  State<ExperientialRecordScreen> createState() => _ExperientialRecordScreenState();
}

class _ExperientialRecordScreenState extends State<ExperientialRecordScreen> {
  final List<_RecordField> _fields = [
    _RecordField(label: 'First Name', mandatory: true, included: true),
    _RecordField(label: 'Last Name', mandatory: true, included: true),
    _RecordField(label: 'Email', mandatory: true, included: true),
    _RecordField(label: 'Contact Info', included: false),
    _RecordField(label: 'Permanent Address Info', included: false),
    _RecordField(label: 'City', included: false),
    _RecordField(label: 'State', included: false),
    _RecordField(label: 'Country of Nationality', mandatory: true, included: true),
    _RecordField(label: 'Profile Picture', included: false),
  ];

  bool _openlyVerifiable = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Experiential Record')),
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
                  title: 'My Experiential Record',
                  subtitle: 'Select the information which you want to add in record.',
                ),
                _buildFieldGrid(context),
                const SizedBox(height: 8),
                _buildVerifiableToggle(context),
                const SizedBox(height: 20),
                FormActionButtons(
                  onCancel: () => Navigator.pop(context),
                  saveLabel: 'Experiential Record',
                  onSave: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Experiential record updated')),
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

  /// Two fields per row, matching the reference two-column layout.
  Widget _buildFieldGrid(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < _fields.length; i += 2) {
      final left = _fields[i];
      final right = i + 1 < _fields.length ? _fields[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Expanded(child: _buildFieldCheckbox(context, left)),
              const SizedBox(width: 12),
              Expanded(child: right != null ? _buildFieldCheckbox(context, right) : const SizedBox()),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildFieldCheckbox(BuildContext context, _RecordField field) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: field.mandatory ? null : () => setState(() => field.included = !field.included),
      child: Row(
        children: [
          Checkbox(
            value: field.included,
            onChanged: field.mandatory ? null : (v) => setState(() => field.included = v ?? false),
            activeColor: Theme.of(context).colorScheme.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    field.label,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (field.mandatory)
                  const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiableToggle(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Switch(
          value: _openlyVerifiable,
          activeColor: Theme.of(context).colorScheme.primary,
          onChanged: (v) => setState(() => _openlyVerifiable = v),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Make my experiential record openly verifiable (By clicking this option you are '
              'allowing your records and personal information selected above to be publicly '
              'accessible for verification purposes.)',
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
