// empty_state.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const EmptyState({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          Text(
            'no_documents_yet'.tr(),
            style: GoogleFonts.slabo27px(
                fontSize: 20.sp, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(
            'scan_or_import_prompt'.tr(),
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: Colors.grey),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt),
            label: Text('scan.start_scanning'.tr()),
          ),
        ],
      ),
    );
  }
}
