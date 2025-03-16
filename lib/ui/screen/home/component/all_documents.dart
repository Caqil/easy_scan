// all_documents.dart
import 'dart:io';
import 'package:easy_scan/models/document.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../utils/date_utils.dart';

class AllDocuments extends StatelessWidget {
  final List<Document> documents;
  final Function(Document) onDocumentTap;
  final Function(Document) onMorePressed;
  final bool showViewAll;
  final VoidCallback? onViewAllPressed;

  const AllDocuments({
    super.key,
    required this.documents,
    required this.onDocumentTap,
    required this.onMorePressed,
    this.showViewAll = true,
    this.onViewAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Limit to 10 items
    final limitedDocuments = documents.take(5).toList();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with View All option
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder_special_rounded,
                    size: 24.sp,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'All Documents',
                    style: GoogleFonts.notoSerif(
                      fontSize: 16.sp.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (showViewAll && documents.length > 5)
                TextButton(
                  onPressed: onViewAllPressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.notoSerif(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12.sp,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // Count indicator
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            '${documents.length} documents',
            style: GoogleFonts.notoSerif(
              color: Colors.grey,
              fontSize: 12.sp,
            ),
          ),
        ),

        SizedBox(height: 12.h),

        // Document list
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedDocuments.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 70.w,
                endIndent: 0,
              ),
              itemBuilder: (context, index) {
                final document = limitedDocuments[index];

                return InkWell(
                  onTap: () => onDocumentTap(document),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        // Document thumbnail
                        Container(
                          width: 45.w,
                          height: 45.h,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.r),
                            color: Colors.grey.withOpacity(0.1),
                          ),
                          child: document.thumbnailPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Hero(
                                    tag: 'doc_${document.id}',
                                    child: Image.file(
                                      File(document.thumbnailPath!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.picture_as_pdf,
                                  color: colorScheme.primary.withOpacity(0.7),
                                  size: 28.sp,
                                ),
                        ),

                        SizedBox(width: 16.w),

                        // Document info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                document.name,
                                style: GoogleFonts.notoSerif(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 10.sp,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    DateTimeUtils.getFriendlyDate(
                                        document.modifiedAt),
                                    style: GoogleFonts.notoSerif(
                                      color: Colors.grey.shade600,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Icon(
                                    Icons.description_outlined,
                                    size: 10.sp,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    '${document.pageCount} pages',
                                    style: GoogleFonts.notoSerif(
                                      color: Colors.grey.shade600,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Document actions
                        _buildDocumentActions(context, document),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // Empty state
        if (documents.isEmpty)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48.sp,
                    color: Colors.grey.withOpacity(0.6),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No documents yet',
                    style: GoogleFonts.notoSerif(
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Scan or import your first document',
                    style: GoogleFonts.notoSerif(
                      fontSize: 14.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentActions(BuildContext context, Document document) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (document.isFavorite)
          Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 15.sp,
          ),
        if (document.isPasswordProtected)
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: Icon(
              Icons.lock_outline,
              color: Colors.blue,
              size: 15.sp,
            ),
          ),
        IconButton(
          icon: Icon(
            Icons.more_vert,
            color: Colors.grey.shade700,
          ),
          onPressed: () => onMorePressed(document),
        ),
      ],
    );
  }
}
