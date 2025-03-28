// search_results.dart
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/routes.dart';
import '../../../../utils/date_utils.dart';

class SearchResults extends StatelessWidget {
  final List<dynamic> documents;

  const SearchResults({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            AutoSizeText('no_documents_yet'.tr(),
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700, fontSize: 16.adaptiveSp)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final document = documents[index];
        return ListTile(
          leading: document.thumbnailPath != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(document.thumbnailPath!),
                    width: 30.w,
                    height: 30.h,
                    fit: BoxFit.cover,
                  ),
                )
              : const Icon(Icons.picture_as_pdf),
          title: AutoSizeText(document.name),
          subtitle:
              AutoSizeText(DateTimeUtils.getFriendlyDate(document.modifiedAt)),
          trailing: const Icon(Icons.more_vert),
          onTap: () => AppRoutes.navigateToView(context, document),
        );
      },
    );
  }
}
