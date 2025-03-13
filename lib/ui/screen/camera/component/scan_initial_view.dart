import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget for showing the initial scan view
class ScanInitialView extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onImportPressed;

  const ScanInitialView({
    super.key,
    required this.onScanPressed,
    required this.onImportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScanIcon(context),
            const SizedBox(height: 24),
            _buildTitle(),
            const SizedBox(height: 16),
            _buildSubtitle(),
            const SizedBox(height: 40),
            _buildScanButton(),
            const SizedBox(height: 24),
            _buildImportButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildScanIcon(BuildContext context) {
    return Icon(
      Icons.document_scanner,
      size: 80,
      color: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTitle() {
    return Text(
      'Ready to Scan',
      style: GoogleFonts.notoSerif(fontSize: 24, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Tap the button below to scan a document',
      textAlign: TextAlign.center,
      style: GoogleFonts.notoSerif(fontSize: 14.sp),
    );
  }

  Widget _buildScanButton() {
    return OutlinedButton.icon(
      onPressed: onScanPressed,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Start Scanning'),
    );
  }

  Widget _buildImportButton() {
    return OutlinedButton.icon(
      onPressed: onImportPressed,
      icon: const Icon(Icons.photo_library),
      label: const Text('Import from Gallery'),
    );
  }
}
