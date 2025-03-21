import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/ui/widget/password_verification_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../models/document.dart';

class PDFViewerWidget extends StatefulWidget {
  final Document document;
  final bool showAppBar;
  final VoidCallback? onShare;

  const PDFViewerWidget({
    super.key,
    required this.document,
    this.showAppBar = true,
    this.onShare,
  });

  @override
  State<PDFViewerWidget> createState() => _PDFViewerWidgetState();
}

class _PDFViewerWidgetState extends State<PDFViewerWidget> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkPasswordProtection();
  }

  void _checkPasswordProtection() {
    if (widget.document.isPasswordProtected) {
      Future.delayed(const Duration(milliseconds: 500), () {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PasswordVerificationDialog(
            correctPassword: widget.document.password ?? "",
            onVerified: () {
              setState(() {
                _isLoading = false;
                _errorMessage = null;
              });
            },
            onCancelled: () {
              setState(() {
                _isLoading = false;
                _errorMessage = 'pdf.password_cancelled'.tr();
              });
            },
          ),
        );
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            AutoSizeText(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: AutoSizeText('common.go_back'.tr()),
            ),
          ],
        ),
      );
    }

    final file = File(widget.document.pdfPath);
    if (!file.existsSync()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            AutoSizeText(
              'pdf.file_not_found'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontSize: 14.sp),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        SfPdfViewer.file(
          file,
          password: widget.document.isPasswordProtected
              ? widget.document.password ?? ""
              : null,
          controller: _pdfViewerController,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            setState(() {
              _isLoading = false;
              if (details.error.contains('Password required') ||
                  details.error.contains('invalid password')) {
                _errorMessage = 'pdf.incorrect_password'.tr();
              } else {
                _errorMessage = 'pdf.failed_to_load'
                    .tr(namedArgs: {'error': details.error});
              }
            });
          },
        ),
        if (widget.showAppBar)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: AutoSizeText(
                        widget.document.name,
                        style: GoogleFonts.slabo27px(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.onShare != null)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: widget.onShare,
                      ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        // _pdfViewerController.openSearchTextField();
                      },
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'bookmark':
                            break;
                          case 'print':
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'bookmark',
                          child: Row(
                            children: [
                              Icon(Icons.bookmark),
                              SizedBox(width: 8),
                              Text('common.add_bookmark'.tr()),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'print',
                          child: Row(
                            children: [
                              Icon(Icons.print),
                              SizedBox(width: 8),
                              Text('share.print'.tr()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
