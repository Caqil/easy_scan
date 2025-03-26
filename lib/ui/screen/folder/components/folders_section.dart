// folders_section.dart
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/ui/widget/folder_card.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../models/folder.dart';

class FoldersSection extends ConsumerWidget {
  final List<Folder> folders;
  final Function(Folder) onFolderTap;
  final Function(Folder) onMorePressed;
  final VoidCallback onCreateFolder;
  final VoidCallback onSeeAll;

  const FoldersSection({
    super.key,
    required this.folders,
    required this.onFolderTap,
    required this.onMorePressed,
    required this.onCreateFolder,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Limit to 5 items (changed from 10 to match your code)
    final limitedFolders = folders.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AutoSizeText(
              'folder.folders'.tr(),
              style: GoogleFonts.slabo27px(
                  fontSize: 14.adaptiveSp, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: onCreateFolder,
                  child: AutoSizeText('folder.create_new'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.adaptiveSp,
                      )),
                ),
                if (folders.length > 5)
                  TextButton(
                    onPressed: onSeeAll,
                    child: AutoSizeText('folder.see_all'.tr()),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120, // Adjust height as needed
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: limitedFolders.length,
            itemBuilder: (context, index) {
              final folder = limitedFolders[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: SizedBox(
                  width: 140, // Adjust width as needed
                  child: FolderCard(
                    folder: folder,
                    documentCount:
                        ref.read(documentsInFolderProvider(folder.id)).length,
                    onTap: () => onFolderTap(folder),
                    onMorePressed: () => onMorePressed(folder),
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
