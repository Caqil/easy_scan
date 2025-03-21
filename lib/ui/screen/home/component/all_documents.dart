// all_documents.dart
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
        Row(
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
                AutoSizeText(
                  'all_documents'.tr(),
                  style: GoogleFonts.slabo27px(
                    fontSize: 16.sp,
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
                    AutoSizeText(
                      'view_all'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.primary,
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

        // Count indicator
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: AutoSizeText(
            'documents_count'
                .tr(namedArgs: {'count': documents.length.toString()}),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
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
                              AutoSizeText(
                                document.name,
                                style: GoogleFonts.slabo27px(
                                  fontWeight: FontWeight.w700,
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
                                  AutoSizeText(
                                    DateTimeUtils.getFriendlyDate(
                                        document.modifiedAt),
                                    style: GoogleFonts.slabo27px(
                                      fontWeight: FontWeight.w700,
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
                                  AutoSizeText(
                                    'pages_count'.tr(namedArgs: {
                                      'count': document.pageCount.toString()
                                    }),
                                    style: GoogleFonts.slabo27px(
                                      fontWeight: FontWeight.w700,
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
                  AutoSizeText(
                    'No documents yet',
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  AutoSizeText(
                    'Scan or import your first document',
                    style: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700,
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
