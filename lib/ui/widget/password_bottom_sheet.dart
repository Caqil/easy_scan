import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordBottomSheet extends StatefulWidget {
  final Document document;
  final WidgetRef ref;

  const PasswordBottomSheet({
    Key? key,
    required this.document,
    required this.ref,
  }) : super(key: key);

  @override
  State<PasswordBottomSheet> createState() => _PasswordBottomSheetState();
}

class _PasswordBottomSheetState extends State<PasswordBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.document.isPasswordProtected
                ? 'Change Password'
                : 'Add Password',
            style: GoogleFonts.notoSerif(
              fontSize: 16.sp.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.document.isPasswordProtected
                ? 'Enter a new password for "${widget.document.name}"'
                : 'Add a password to protect "${widget.document.name}"',
            style: GoogleFonts.notoSerif(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            autofocus: true,
            onSubmitted: (_) => _applyPassword(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _applyPassword,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _applyPassword() {
    if (_passwordController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(context,
          type: SnackBarType.error, message: 'Please enter a password');

      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Apply password to document
    final updatedDoc = Document(
      id: widget.document.id,
      name: widget.document.name,
      pdfPath: widget.document.pdfPath,
      pagesPaths: widget.document.pagesPaths,
      pageCount: widget.document.pageCount,
      thumbnailPath: widget.document.thumbnailPath,
      createdAt: widget.document.createdAt,
      modifiedAt: DateTime.now(),
      tags: widget.document.tags,
      folderId: widget.document.folderId,
      isFavorite: widget.document.isFavorite,
      isPasswordProtected: true,
      password: _passwordController.text.trim(),
    );

    // Add a slight delay to simulate processing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Update document with password
      widget.ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Close the sheet and show success message
      Navigator.pop(context);
      AppDialogs.showSnackBar(context,
          type: SnackBarType.success,
          message: widget.document.isPasswordProtected
              ? 'Password updated successfully'
              : 'Password added successfully');
    });
  }
}
