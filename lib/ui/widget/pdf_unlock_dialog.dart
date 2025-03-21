import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/main.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/services/pdf_unlock_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';

class PdfUnlockDialog extends ConsumerStatefulWidget {
  final Document document;
  final Function(Document)? onSuccess;

  const PdfUnlockDialog({
    Key? key,
    required this.document,
    this.onSuccess,
  }) : super(key: key);

  @override
  ConsumerState<PdfUnlockDialog> createState() => _PdfUnlockDialogState();
}

class _PdfUnlockDialogState extends ConsumerState<PdfUnlockDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isProcessing = false;
  String _errorMessage = '';
  double _progress = 0.0;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _unlockPdf() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      setState(() {
        _errorMessage = 'pdf.unlock.error_empty_password'.tr();
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = '';
      _progress = 0.0;
    });

    try {
      final pdfUnlockService = ref.read(pdfUnlockServiceProvider);

      logger.info(
          'Starting PDF unlock process for document: ${widget.document.name}');

      final unlockedDocument = await pdfUnlockService.unlockDocument(
        document: widget.document,
        password: password,
        ref: ref,
        onProgress: (progress) {
          setState(() {
            _progress = progress;
          });
        },
      );

      logger.info(
          'PDF unlock completed successfully. New path: ${unlockedDocument.pdfPath}');

      if (mounted) {
        // Pop the dialog first
        Navigator.of(context).pop();

        // Show success message
        AppDialogs.showSnackBar(
          context,
          message: 'pdf.unlock.success'.tr(),
          type: SnackBarType.success,
        );

        // Wait a moment to ensure dialog is dismissed before calling the callback
        await Future.delayed(const Duration(milliseconds: 300));

        // Call the success callback if provided
        if (widget.onSuccess != null && mounted) {
          logger.info('Calling onSuccess callback with unlocked document');
          widget.onSuccess!(unlockedDocument);
        }
      }
    } catch (e) {
      logger.error('Error in unlock PDF: $e');

      if (mounted) {
        setState(() {
          _isProcessing = false;
          // Show a more specific error message
          if (e.toString().contains('Invalid position')) {
            _errorMessage = 'pdf.unlock.error_invalid_pdf'.tr();
          } else if (e.toString().contains('password')) {
            _errorMessage = 'pdf.unlock.error_wrong_password'.tr();
          } else {
            _errorMessage = 'pdf.unlock.error_unlock_failed'.tr();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Container(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.lock_open_outlined,
                  color: Theme.of(context).primaryColor,
                  size: 24.r,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'pdf.unlock.title'.tr(),
                    style: GoogleFonts.slabo27px(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Description
            Text(
              'pdf.unlock.description'
                  .tr(namedArgs: {'name': widget.document.name}),
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),

            SizedBox(height: 20.h),

            // Password input
            TextField(
              controller: _passwordController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'pdf.unlock.password_label'.tr(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
                enabled: !_isProcessing,
              ),
              autofocus: true,
              onSubmitted: (_) => _unlockPdf(),
            ),

            if (_errorMessage.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.slabo27px(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            if (_isProcessing) ...[
              SizedBox(height: 16.h),
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                borderRadius: BorderRadius.circular(4.r),
              ),
              SizedBox(height: 8.h),
              Center(
                child: Text(
                  'pdf.unlock.processing'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],

            SizedBox(height: 24.h),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isProcessing ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text('common.cancel'.tr()),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _unlockPdf,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.r),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isProcessing
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('pdf.unlock.unlock_button'.tr()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Show PDF unlock dialog
void showPdfUnlockDialog(BuildContext context, Document document,
    {Function(Document)? onSuccess}) {
  showDialog(
    context: context,
    builder: (context) => PdfUnlockDialog(
      document: document,
      onSuccess: onSuccess,
    ),
  );
}
