// all_documents.dart
import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:flutter/material.dart';
import '../../../../utils/date_utils.dart';

class AllDocuments extends StatelessWidget {
  final List<Document> documents;
  final Function(Document) onDocumentTap;
  final Function(Document) onMorePressed;

  const AllDocuments({
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
        const Text(
          'All Documents',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedDocuments.length,
          itemBuilder: (context, index) {
            final document = limitedDocuments[index];
            return ListTile(
              leading: document.thumbnailPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(
                        File(document.thumbnailPath!),
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(Icons.picture_as_pdf),
              title: Text(document.name),
              subtitle:
                  Text(DateTimeUtils.getFriendlyDate(document.modifiedAt)),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => onMorePressed(document),
              ),
              onTap: () => onDocumentTap(document),
            );
          },
        ),
      ],
    );
  }
}
