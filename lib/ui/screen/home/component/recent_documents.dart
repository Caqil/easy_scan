// recent_documents.dart
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/ui/widget/document_card.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../models/document.dart';

class RecentDocuments extends StatelessWidget {
  final List<Document> documents;
  final Function(Document) onDocumentTap;
  final Function(Document) onMorePressed;

  const RecentDocuments({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    required this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    // Limit to 10 items
    final limitedDocuments = documents.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AutoSizeText(
          'recent_documents'.tr(),
          style: GoogleFonts.slabo27px(
              fontSize: 14.adaptiveSp, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: limitedDocuments.length,
            itemBuilder: (context, index) {
              final document = limitedDocuments[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: 140,
                  child: DocumentCard(
                    document: document,
                    onTap: () => onDocumentTap(document),
                    onMorePressed: () => onMorePressed(document),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
