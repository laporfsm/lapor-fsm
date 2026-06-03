import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile/core/theme.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final IconData? icon;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Lanjutkan',
    this.cancelLabel = 'Batal',
    this.confirmColor = AppTheme.primaryColor,
    this.icon,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Lanjutkan',
    String cancelLabel = 'Batal',
    Color confirmColor = AppTheme.primaryColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: confirmColor, size: 24),
            const Gap(12),
          ],
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          color: Colors.grey.shade700,
          fontSize: 15,
          height: 1.5,
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(cancelLabel),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ReasonDialog extends StatefulWidget {
  final String title;
  final String message;
  final String hintText;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;
  final IconData? icon;
  final bool required;

  const ReasonDialog({
    super.key,
    required this.title,
    required this.message,
    this.hintText = 'Masukkan alasan...',
    this.confirmLabel = 'Kirim',
    this.cancelLabel = 'Batal',
    this.confirmColor = Colors.red,
    this.icon,
    this.required = true,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String message,
    String hintText = 'Masukkan alasan...',
    String confirmLabel = 'Kirim',
    String cancelLabel = 'Batal',
    Color confirmColor = Colors.red,
    IconData? icon,
    bool required = true,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => ReasonDialog(
        title: title,
        message: message,
        hintText: hintText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
        icon: icon,
        required: required,
      ),
    );
  }

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Row(
        children: [
          if (widget.icon != null) ...[
            Icon(widget.icon, color: widget.confirmColor, size: 24),
            const Gap(12),
          ],
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const Gap(16),
          TextField(
            controller: _controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.confirmColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(widget.cancelLabel),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  final text = _controller.text.trim();
                  if (widget.required && text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Alasan wajib diisi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.confirmColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(widget.confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class SuccessDialog extends StatelessWidget {
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback? onConfirm;

  const SuccessDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonLabel = 'OK',
    this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'OK',
    VoidCallback? onConfirm,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        buttonLabel: buttonLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.checkCircle2, color: Colors.green, size: 48),
          ),
          const Gap(20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Gap(12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5),
          ),
          const Gap(32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onConfirm != null) onConfirm!();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class SplitReportDialog extends StatefulWidget {
  final String originalTitle;
  final String originalDescription;
  final List<Map<String, dynamic>> categories;
  final Color themeColor;

  const SplitReportDialog({
    super.key,
    required this.originalTitle,
    required this.originalDescription,
    required this.categories,
    required this.themeColor,
  });

  static Future<List<Map<String, dynamic>>?> show(
    BuildContext context, {
    required String originalTitle,
    required String originalDescription,
    required List<Map<String, dynamic>> categories,
    Color themeColor = AppTheme.primaryColor,
  }) {
    return showDialog<List<Map<String, dynamic>>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SplitReportDialog(
        originalTitle: originalTitle,
        originalDescription: originalDescription,
        categories: categories,
        themeColor: themeColor,
      ),
    );
  }

  @override
  State<SplitReportDialog> createState() => _SplitReportDialogState();
}

class _SplitReportDialogState extends State<SplitReportDialog> {
  final List<Map<String, dynamic>> _splits = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Initialize with 2 splits by default
    _splits.add({
      'title': widget.originalTitle,
      'description': widget.originalDescription,
      'categoryId': widget.categories.isNotEmpty ? widget.categories[0]['id'] : null,
    });
    _splits.add({
      'title': '',
      'description': '',
      'categoryId': widget.categories.isNotEmpty ? widget.categories[0]['id'] : null,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(LucideIcons.split, color: widget.themeColor, size: 24),
          const Gap(12),
          const Expanded(
            child: Text(
              'Pecah Laporan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original: "${widget.originalTitle}"',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                const Gap(16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _splits.length,
                  separatorBuilder: (context, index) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final split = _splits[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pecahan #${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: widget.themeColor,
                              ),
                            ),
                            if (_splits.length > 2)
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                                onPressed: () {
                                  setState(() {
                                    _splits.removeAt(index);
                                  });
                                },
                              ),
                          ],
                        ),
                        const Gap(8),
                        DropdownButtonFormField<int>(
                          initialValue: split['categoryId'],
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: widget.categories.map((cat) {
                            return DropdownMenuItem<int>(
                              value: cat['id'] as int,
                              child: Text(cat['name'] as String),
                            );
                          }).toList(),
                          onChanged: (val) {
                            split['categoryId'] = val;
                          },
                        ),
                        const Gap(12),
                        TextFormField(
                          initialValue: split['title'],
                          decoration: InputDecoration(
                            labelText: 'Judul Laporan',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Judul wajib diisi' : null,
                          onChanged: (val) {
                            split['title'] = val.trim();
                          },
                        ),
                        const Gap(12),
                        TextFormField(
                          initialValue: split['description'],
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Masalah',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Deskripsi wajib diisi' : null,
                          onChanged: (val) {
                            split['description'] = val.trim();
                          },
                        ),
                      ],
                    );
                  },
                ),
                const Gap(16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _splits.add({
                        'title': '',
                        'description': '',
                        'categoryId': widget.categories.isNotEmpty ? widget.categories[0]['id'] : null,
                      });
                    });
                  },
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Tambah Pecahan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.themeColor,
                    side: BorderSide(color: widget.themeColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const Gap(12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Navigator.pop(context, _splits);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Pecah'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

