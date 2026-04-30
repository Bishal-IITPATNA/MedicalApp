import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Reusable "Upload Prescription" picker.
///
/// - Lets the user pick an image (jpg/png/webp) or a PDF.
/// - Validates size client-side (<= 3 MB to match backend).
/// - Reports the picked file to the parent via [onChanged] as a base64
///   data URL plus a filename. Both are `null` once the user clears the
///   selection.
class PrescriptionPicker extends StatefulWidget {
  final void Function(String? dataUrl, String? filename) onChanged;
  final bool dense;

  const PrescriptionPicker({
    super.key,
    required this.onChanged,
    this.dense = false,
  });

  @override
  State<PrescriptionPicker> createState() => _PrescriptionPickerState();
}

class _PrescriptionPickerState extends State<PrescriptionPicker> {
  static const int _maxBytes = 3 * 1024 * 1024;
  static const Map<String, String> _mimeByExt = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'pdf': 'application/pdf',
  };

  String? _filename;
  Uint8List? _bytes;
  String? _mime;

  Future<void> _pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _mimeByExt.keys.toList(),
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;

      final f = result.files.single;
      final bytes = f.bytes;
      if (bytes == null) {
        _showError('Could not read the selected file.');
        return;
      }
      if (bytes.lengthInBytes > _maxBytes) {
        _showError(
          'File is ${(bytes.lengthInBytes / 1024 / 1024).toStringAsFixed(1)} MB. Max allowed is 3 MB.',
        );
        return;
      }

      final ext = (f.extension ?? '').toLowerCase();
      final mime = _mimeByExt[ext];
      if (mime == null) {
        _showError('Unsupported file type. Use JPG, PNG, WEBP or PDF.');
        return;
      }

      setState(() {
        _filename = f.name;
        _bytes = bytes;
        _mime = mime;
      });

      final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';
      widget.onChanged(dataUrl, f.name);
    } catch (e) {
      _showError('Could not pick file: $e');
    }
  }

  void _clear() {
    setState(() {
      _filename = null;
      _bytes = null;
      _mime = null;
    });
    widget.onChanged(null, null);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _bytes != null;
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: widget.dense ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasFile ? theme.colorScheme.primary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasFile ? Icons.description : Icons.upload_file_outlined,
            color: hasFile ? theme.colorScheme.primary : Colors.grey.shade700,
            size: widget.dense ? 22 : 28,
            semanticLabel: 'Prescription',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasFile ? 'Prescription attached' : 'Optional: attach prescription',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasFile ? theme.colorScheme.primary : null,
                  ),
                ),
                if (hasFile && _filename != null)
                  Text(
                    '${_filename!}  ·  ${(_bytes!.lengthInBytes / 1024).toStringAsFixed(0)} KB',
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                  )
                else
                  Text(
                    'JPG, PNG, WEBP or PDF · up to 3 MB',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (hasFile) ...[
            IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close, size: 20),
              onPressed: _clear,
            ),
            TextButton.icon(
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Replace'),
              onPressed: _pick,
            ),
          ] else
            ElevatedButton.icon(
              icon: const Icon(Icons.upload, size: 18),
              label: const Text('Upload'),
              onPressed: _pick,
            ),
        ],
      ),
    );
  }
}
