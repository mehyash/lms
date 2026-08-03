import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'model.dart';

class PdfPreviewScreen extends StatefulWidget {
  final Uint8List pdfBytes;
  final String courseName;
  final String courseId;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.courseName,
    required this.courseId,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  bool _isSaving = false;

  Future<void> _saveCurriculum() async {
    setState(() => _isSaving = true);
    try {
      final fileName = 'Curriculum_${widget.courseName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      
      // Removed the 'curriculums/' prefix from filePath because .from('curriculums') already points to the bucket
      final filePath = fileName;

      // 1. Upload to Supabase Storage
      await Supabase.instance.client.storage
          .from('curriculums')
          .uploadBinary(filePath, widget.pdfBytes);

      // 2. Get Public URL
      final publicUrl = Supabase.instance.client.storage
          .from('curriculums')
          .getPublicUrl(filePath);

      // 3. Update Courses table
      await Supabase.instance.client
          .from('Courses')
          .update({'curriculum_url': publicUrl})
          .eq('id', int.parse(widget.courseId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Curriculum saved and published successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      debugPrint('Save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${widget.courseName}'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton(
              onPressed: _saveCurriculum,
              child: const Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SfPdfViewer.memory(widget.pdfBytes),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('RETRY / DISCARD'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveCurriculum,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('SAVE & PUBLISH'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
