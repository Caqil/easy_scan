// Add this to your lib/ui/common/folders_grid.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../models/folder.dart';
import '../../providers/document_provider.dart';
import '../widget/folder_card.dart';

/// A globally accessible component to show all folders in a grid view
class FoldersGrid {
  /// Show a modal bottom sheet with all folders in a grid layout
  static Future<void> showAllFolders(
    BuildContext context,
    List<Folder> folders,
    WidgetRef ref, {
    String title = 'All Folders',
    Function(Folder)? onFolderTap,
    Function(Folder)? onFolderOptions,
    Function()? onCreateNewFolder,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AllFoldersSheet(
        folders: folders,
        ref: ref,
        title: title,
        onFolderTap: onFolderTap,
        onFolderOptions: onFolderOptions,
        onCreateNewFolder: onCreateNewFolder,
      ),
    );
  }
}

class _AllFoldersSheet extends ConsumerWidget {
  final List<Folder> folders;
  final String title;
  final Function(Folder)? onFolderTap;
  final Function(Folder)? onFolderOptions;
  final Function()? onCreateNewFolder;

  const _AllFoldersSheet({
    required this.folders,
    required this.ref,
    required this.title,
    this.onFolderTap,
    this.onFolderOptions,
    this.onCreateNewFolder,
  });

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            height: 2.h,
            width: 30.w,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header with title and optional "Create New" button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 30.w,
                  height: 30.h,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder_outlined,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.slabo27px(
                          fontSize: 16.sp.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${folders.length} folders',
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onCreateNewFolder != null)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onCreateNewFolder!();
                    },
                    icon: const Icon(Icons.add),
                    label: Text('new'.tr()),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Search field (optional)
          if (folders.length > 5)
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'folder.search_folders'.tr(),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

          // Folders grid
          Expanded(
            child: folders.isEmpty
                ? _buildEmptyState(context)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: folders.length,
                      itemBuilder: (context, index) {
                        final folder = folders[index];
                        return FolderCard(
                          folder: folder,
                          documentCount: ref
                              .read(documentsInFolderProvider(folder.id))
                              .length,
                          onTap: () {
                            Navigator.pop(context);
                            if (onFolderTap != null) {
                              onFolderTap!(folder);
                            }
                          },
                          onMorePressed: onFolderOptions != null
                              ? () {
                                  Navigator.pop(context);
                                  onFolderOptions!(folder);
                                }
                              : null,
                        );
                      },
                    ),
                  ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'folder_screen.no_folders_yet'.tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'folder_screen.create_folder_prompt'.tr(),
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          if (onCreateNewFolder != null) ...[
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onCreateNewFolder!();
              },
              icon: const Icon(Icons.add),
              label: Text('folder.create_new_folder'.tr()),
            ),
          ],
        ],
      ),
    );
  }
}
