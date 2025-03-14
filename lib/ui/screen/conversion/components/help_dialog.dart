import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HelpDialog extends StatelessWidget {
  const HelpDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Advanced Options Help"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _helpItem("OCR (Optical Character Recognition)",
              "Extracts text from images or scanned PDFs. Enables searching and text selection."),
          SizedBox(height: 8.h),
          _helpItem("Image Quality",
              "Higher quality produces larger files with better details. Lower quality reduces file size."),
          SizedBox(height: 8.h),
          _helpItem("PDF Password",
              "Required only if your source PDF is password-protected."),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }

  Widget _helpItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(description),
      ],
    );
  }
}
