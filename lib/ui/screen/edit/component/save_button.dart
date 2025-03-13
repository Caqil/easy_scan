import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// A stylized save button for the edit screen
class SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final ColorScheme colorScheme;

  const SaveButton({
    super.key,
    required this.onSave,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: OutlinedButton.icon(
        onPressed: onSave,
        icon: const Icon(Icons.save_alt_rounded),
        label: const Text('Save as PDF'),
        style: OutlinedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.notoSerif(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
