// Add this file to your project as lib/ui/common/folder_actions.dart

import 'package:easy_scan/providers/document_provider.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../models/folder.dart';
import '../../providers/folder_provider.dart';
import '../../utils/constants.dart';

/// A globally accessible class to handle folder-related actions
class FolderActions {
  /// Show folder options bottom sheet
  static Future<void> showFolderOptions(
    BuildContext context,
    Folder folder,
    WidgetRef ref, {
    Function(Folder)? onRename,
    Function(Folder)? onChangeColor,
    Function(Folder)? onDelete,
  }) async {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FolderOptionsSheet(
        folder: folder,
        ref: ref,
        onRename: onRename,
        onChangeColor: onChangeColor,
        onDelete: onDelete,
      ),
    );
  }

  static Future<void> showRenameFolderDialog(
    BuildContext context,
    Folder folder,
    WidgetRef ref,
  ) async {
    // Move the controller inside the builder to ensure it stays alive
    // throughout the dialog's lifecycle
    return showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) {
        // Create controller inside the builder
        final controller = TextEditingController(text: folder.name);

        return StatefulBuilder(
          builder: (context, setState) {
            return CupertinoAlertDialog(
              title: const Text('Rename Folder'),
              content: CupertinoTextField(
                controller: controller,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, controller.text.trim());
                    }
                  },
                  child: const Text('Rename'),
                ),
              ],
            );
          },
        );
      },
    ).then((newName) {
      // Handle the result after dialog is closed
      if (newName != null && newName.isNotEmpty) {
        final updatedFolder = Folder(
          id: folder.id,
          name: newName,
          parentId: folder.parentId,
          color: folder.color,
          iconName: folder.iconName,
          createdAt: folder.createdAt,
        );

        ref.read(foldersProvider.notifier).updateFolder(updatedFolder);

        // Show success message
        if (context.mounted) {
          AppDialogs.showSnackBar(context,
              type: SnackBarType.success,
              message: 'Folder renamed successfully');
        }
      }
    });
  }

  /// Show change folder color dialog
  static Future<void> showChangeFolderColorDialog(
    BuildContext context,
    Folder folder,
    WidgetRef ref,
  ) async {
    int selectedColor = folder.color;

    final bool? result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return CupertinoAlertDialog(
            title: const Text('Change Folder Color'),
            content: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: AppConstants.folderColors.map((color) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(color),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selectedColor == color
                            ? Colors.white
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedColor == color
                              ? Color(color).withOpacity(0.6)
                              : Colors.transparent,
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: selectedColor == color
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      final updatedFolder = Folder(
        id: folder.id,
        name: folder.name,
        parentId: folder.parentId,
        color: selectedColor,
        iconName: folder.iconName,
        createdAt: folder.createdAt,
      );

      ref.read(foldersProvider.notifier).updateFolder(updatedFolder);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(context,
            message: 'Folder color updated successfully');
      }
    }
  }

  /// Show delete folder confirmation dialog
  static Future<void> showDeleteFolderConfirmation(
    BuildContext context,
    Folder folder,
    WidgetRef ref, {
    bool popNavigatorOnSuccess = false,
  }) async {
    final documentsInFolder = ref.read(documentsInFolderProvider(folder.id));
    final subfolders = ref.read(subFoldersProvider(folder.id));

    final bool confirm = await showCupertinoDialog<bool>(
          context: context,
          builder: (context) => StatefulBuilder(
              builder: (context, setState) => CupertinoAlertDialog(
                    title: const Text('Delete Folder'),
                    content: documentsInFolder.isNotEmpty ||
                            subfolders.isNotEmpty
                        ? Text(
                            'This folder contains ${documentsInFolder.length} documents and ${subfolders.length} subfolders. '
                            'All contents will be moved to the parent folder. Continue?')
                        : Text(
                            'Are you sure you want to delete "${folder.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context, true);
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Delete'),
                      ),
                    ],
                  )),
        ) ??
        false;

    if (confirm) {
      // Move documents to parent folder
      if (documentsInFolder.isNotEmpty) {
        for (var document in documentsInFolder) {
          final updatedDoc = document.copyWith(folderId: folder.parentId);
          ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
        }
      }

      // Move subfolders to parent folder
      if (subfolders.isNotEmpty) {
        for (var subfolder in subfolders) {
          final updatedFolder = Folder(
            id: subfolder.id,
            name: subfolder.name,
            parentId: folder.parentId,
            color: subfolder.color,
            iconName: subfolder.iconName,
            createdAt: subfolder.createdAt,
          );
          ref.read(foldersProvider.notifier).updateFolder(updatedFolder);
        }
      }

      // Delete the folder
      await ref.read(foldersProvider.notifier).deleteFolder(folder.id);

      // Show success message
      if (context.mounted) {
        AppDialogs.showSnackBar(context,
            type: SnackBarType.success, message: 'Folder deleted successfully');

        if (popNavigatorOnSuccess) {
          Navigator.pop(context);
        }
      }
    }
  }
}

/// Internal widget for folder options sheet
class _FolderOptionsSheet extends StatelessWidget {
  final Folder folder;
  final WidgetRef ref;
  final Function(Folder)? onRename;
  final Function(Folder)? onChangeColor;
  final Function(Folder)? onDelete;

  const _FolderOptionsSheet({
    required this.folder,
    required this.ref,
    this.onRename,
    this.onChangeColor,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        mainAxisSize: MainAxisSize.min,
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

          // Folder info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                // Folder icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(folder.color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    folder.iconName != null
                        ? IconData(
                            int.parse('0x${folder.iconName}'),
                            fontFamily: 'MaterialIcons',
                          )
                        : Icons.folder,
                    color: Color(folder.color),
                  ),
                ),
                const SizedBox(width: 16),

                // Folder name
                Expanded(
                  child: Text(
                    folder.name,
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Options list
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Rename Folder',
                  description: 'Change folder name',
                  onTap: () {
                    Navigator.pop(context);
                    if (onRename != null) {
                      onRename!(folder);
                    } else {
                      FolderActions.showRenameFolderDialog(
                          context, folder, ref);
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Change Color',
                  description: 'Customize folder appearance',
                  onTap: () {
                    Navigator.pop(context);
                    if (onChangeColor != null) {
                      onChangeColor!(folder);
                    } else {
                      FolderActions.showChangeFolderColorDialog(
                          context, folder, ref);
                    }
                  },
                ),
                if (folder.parentId != null)
                  _buildOptionTile(
                    context,
                    icon: Icons.drive_file_move_outlined,
                    title: 'Move Folder',
                    description: 'Change folder location',
                    onTap: () {
                      Navigator.pop(context);
                      // Implement move folder functionality
                    },
                  ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildOptionTile(
                  context,
                  icon: Icons.delete_outlined,
                  iconColor: Colors.red,
                  title: 'Delete Folder',
                  description: 'Remove folder and move contents',
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!(folder);
                    } else {
                      FolderActions.showDeleteFolderConfirmation(
                        context,
                        folder,
                        ref,
                        popNavigatorOnSuccess: true,
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    Color? iconColor,
    required String title,
    required String description,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                icon,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              style: GoogleFonts.notoSerif(
                fontSize: 10.sp,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
