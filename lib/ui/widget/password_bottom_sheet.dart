import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_scan/models/document.dart';
import 'package:easy_scan/providers/document_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../services/pdf_service.dart';

class PasswordBottomSheet extends ConsumerStatefulWidget {
  final Document document;

  const PasswordBottomSheet({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<PasswordBottomSheet> createState() =>
      _PasswordBottomSheetState();
}

class _PasswordBottomSheetState extends ConsumerState<PasswordBottomSheet> {
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
                  child:  Text('common.cancel'.tr()),
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
                      :  Text('common.save'.tr()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _applyPassword() async {
    if (_passwordController.text.trim().isEmpty) {
      AppDialogs.showSnackBar(context,
          type: SnackBarType.error, message: 'Please enter a password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the PDF service
      final pdfService = PdfService();
      final String password = _passwordController.text.trim();

      print(
          'Applying password: "${password}" to document: ${widget.document.name}');

      // Apply the password to the actual PDF file
      final protectedPdfPath = await pdfService.protectPdf(
        widget.document.pdfPath,
        password,
      );

      if (protectedPdfPath.isEmpty) {
        throw Exception('Failed to protect PDF - returned path is empty');
      }

      print('Protected PDF path: $protectedPdfPath');

      // Update document with password
      final updatedDoc = Document(
        id: widget.document.id,
        name: widget.document.name,
        pdfPath: protectedPdfPath, // Use the protected PDF path
        pagesPaths: widget.document.pagesPaths,
        pageCount: widget.document.pageCount,
        thumbnailPath: widget.document.thumbnailPath,
        createdAt: widget.document.createdAt,
        modifiedAt: DateTime.now(),
        tags: widget.document.tags,
        folderId: widget.document.folderId,
        isFavorite: widget.document.isFavorite,
        isPasswordProtected: true,
        password: password, // Store the actual password
      );

      print('Updating document with password, document ID: ${updatedDoc.id}');

      await ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Close the sheet and show success message
      if (mounted) {
        Navigator.pop(context);
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success,
            message: widget.document.isPasswordProtected
                ? 'Password updated successfully'
                : 'Password added successfully');
      }
    } catch (e) {
      print('Error in _applyPassword: $e');
      if (mounted) {
        AppDialogs.showSnackBar(context,
            type: SnackBarType.error,
            message: 'Failed to apply password: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
