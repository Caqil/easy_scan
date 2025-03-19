import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom input field for document name entry
class DocumentNameInput extends StatelessWidget {
  final TextEditingController controller;
  final ColorScheme colorScheme;

  const DocumentNameInput({
    super.key,
    required this.controller,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: TextField(
        controller: controller,
        style: GoogleFonts.notoSerif(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'documents.document_name'.tr(),
          labelStyle: GoogleFonts.notoSerif(color: colorScheme.primary),
          prefixIcon:
              Icon(Icons.description_outlined, color: colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
