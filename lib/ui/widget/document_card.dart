import 'dart:io';
import 'package:scanpro/models/document.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/date_utils.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Thumbnail or placeholder
                  if (document.thumbnailPath != null &&
                      File(document.thumbnailPath!).existsSync())
                    Image.file(
                      File(document.thumbnailPath!),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.picture_as_pdf,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),

                  // Favorite icon
                  if (document.isFavorite)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                      ),
                    ),

                  // Password indicator
                  if (document.isPasswordProtected)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Document info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          document.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.bold,
                            fontSize: 10.adaptiveSp,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AutoSizeText(
                          DateTimeUtils.getFriendlyDate(document.modifiedAt),
                          style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 7.adaptiveSp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // More options button
                  if (onMorePressed != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onMorePressed,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
