import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// SHARED PROFILE FORM WIDGETS
/// ---------------------------------------------------------------------
/// Small reusable pieces used by the Profile sub-screens (Personal
/// Information, Educational Information, Account Settings) so all three
/// forms share one consistent look instead of each re-implementing the
/// same field / section / button styling.
/// ---------------------------------------------------------------------

/// Page header block: bold title + grey subtitle + divider — matches the
/// "Personal Information / Update your personal information" style from
/// the reference screens.
class ProfileFormHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const ProfileFormHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600)),
        const SizedBox(height: 14),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 18),
      ],
    );
  }
}

/// Small bold section label, e.g. "User Info", "Contact Info".
class ProfileSectionLabel extends StatelessWidget {
  final String label;
  const ProfileSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
    );
  }
}

/// Label-above-field text input with a trailing icon inside the field.
/// `readOnly` + `onTap` recreate the reference "Name" field's
/// locked-until-you-tap-Edit behaviour, and date pickers.
class LabeledTextField extends StatelessWidget {
  final String label;
  final bool required;
  final TextEditingController controller;
  final IconData icon;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? trailingLabelAction;
  final bool obscureText;
  final Widget? obscureToggle;

  const LabeledTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.required = false,
    this.readOnly = false,
    this.onTap,
    this.keyboardType,
    this.maxLines = 1,
    this.trailingLabelAction,
    this.obscureText = false,
    this.obscureToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (trailingLabelAction != null) trailingLabelAction!,
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            maxLines: maxLines,
            obscureText: obscureText,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF0F2F5),
              suffixIcon: obscureToggle ?? Icon(icon, size: 19, color: Colors.grey.shade600),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label-above-field dropdown, styled to match [LabeledTextField].
class LabeledDropdown extends StatelessWidget {
  final String label;
  final bool required;
  final String? value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final Widget? trailingLabelAction;

  const LabeledDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
    this.required = false,
    this.trailingLabelAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              if (required)
                const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (trailingLabelAction != null) trailingLabelAction!,
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: value,
            isExpanded: true,
            icon: Icon(icon, size: 19, color: Colors.grey.shade600),
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF0F2F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            hint: const Text('Select', style: TextStyle(fontSize: 14)),
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Cancel / Save Changes button row shown at the bottom of every form.
/// Uses the app's theme primary color for Save (matching the "Apply Now"
/// button style on Program Details) rather than introducing a one-off
/// accent color, to keep branding consistent across the app.
class FormActionButtons extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onCancel;
  final String saveLabel;

  const FormActionButtons({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.saveLabel = 'Save Changes',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: BorderSide(color: Colors.grey.shade300),
              foregroundColor: Colors.grey.shade800,
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(saveLabel),
          ),
        ),
      ],
    );
  }
}
