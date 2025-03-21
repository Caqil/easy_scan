// Add this file to your project as lib/ui/common/folder_actions.dart

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:scanpro/ui/widget/option_tile.dart';

import '../../../../models/folder.dart';
import '../../../../providers/folder_provider.dart';
import '../../../../utils/constants.dart';

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

  static Future<void> addDocumentsToFolder(
    BuildContext context,
    Folder targetFolder,
    WidgetRef ref,
  ) async {
    // Get all documents that are not already in the target folder
    final allDocuments = ref.read(documentsProvider);
    final documentsNotInFolder =
        allDocuments.where((doc) => doc.folderId != targetFolder.id).toList();

    if (documentsNotInFolder.isEmpty) {
      AppDialogs.showSnackBar(
        context,
        message: 'folder_actions.no_documents_available'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    // Track selected documents for moving
    final selectedDocuments = <Document>[];

    // Show document selection dialog
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: AutoSizeText('folder_actions.add_documents_to'
              .tr(namedArgs: {'folderName': targetFolder.name})),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoSizeText(
                  'folder_actions.select_documents'.tr(),
                  style: GoogleFonts.slabo27px(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: documentsNotInFolder.length,
                    itemBuilder: (context, index) {
                      final doc = documentsNotInFolder[index];
                      final isSelected = selectedDocuments.contains(doc);

                      return CheckboxListTile(
                        title: AutoSizeText(
                          doc.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: AutoSizeText(
                          doc.folderId == null
                              ? 'folder_actions.root_folder'.tr()
                              : 'folder_actions.from_folder'.tr(namedArgs: {
                                  'folderName':
                                      _getFolderName(ref, doc.folderId)
                                }),
                          style: TextStyle(fontSize: 12),
                        ),
                        secondary: doc.thumbnailPath != null
                            ? SizedBox(
                                width: 40,
                                height: 40,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(
                                    File(doc.thumbnailPath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : const Icon(Icons.description),
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value!) {
                              selectedDocuments.add(doc);
                            } else {
                              selectedDocuments.remove(doc);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(targetFolder.color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Color(targetFolder.color).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder,
                        color: Color(targetFolder.color),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AutoSizeText(
                          'folder_actions.move_to_folder'
                              .tr(namedArgs: {'folderName': targetFolder.name}),
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(targetFolder.color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: AutoSizeText('common.cancel'.tr()),
            ),
            TextButton(
              onPressed: selectedDocuments.isEmpty
                  ? null
                  : () => Navigator.pop(context, true),
              child: AutoSizeText('folder_actions.add_to_folder'.tr(
                  namedArgs: {'count': selectedDocuments.length.toString()})),
            ),
          ],
        ),
      ),
    ).then((result) async {
      if (result == true && selectedDocuments.isNotEmpty) {
        // Update documents to be in the target folder
        for (var doc in selectedDocuments) {
          final updatedDoc = doc.copyWith(
            folderId: targetFolder.id,
            modifiedAt: DateTime.now(),
          );

          await ref.read(documentsProvider.notifier).updateDocument(updatedDoc);
        }

        // Show success message
        if (context.mounted) {
          AppDialogs.showSnackBar(
            context,
            type: SnackBarType.success,
            message: 'folder_actions.added_documents'.tr(namedArgs: {
              'count': selectedDocuments.length.toString(),
              'plural': selectedDocuments.length == 1 ? '' : 's',
              'folderName': targetFolder.name
            }),
          );
        }
      }
    });
  }

// Helper function to get folder name from ID
  static String _getFolderName(WidgetRef ref, String? folderId) {
    if (folderId == null) return 'Root';

    final folders = ref.read(foldersProvider);
    final folder = folders.firstWhere(
      (f) => f.id == folderId,
      orElse: () => Folder(name: "Unknown"),
    );

    return folder.name;
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
              title: AutoSizeText('folder_actions.rename_folder'.tr()),
              content: CupertinoTextField(
                controller: controller,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: AutoSizeText('common.cancel'.tr()),
                ),
                TextButton(
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      Navigator.pop(dialogContext, controller.text.trim());
                    }
                  },
                  child: AutoSizeText('common.rename'.tr()),
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
              message: 'folder_actions.folder_renamed'.tr());
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
            title: AutoSizeText('folder_actions.change_folder_color'.tr()),
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
                child: AutoSizeText('common.cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: AutoSizeText('folder_actions.apply'.tr()),
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
            message: 'folder_actions.folder_color_updated'.tr());
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
                    title: AutoSizeText('folder_actions.delete_folder'.tr()),
                    content: documentsInFolder.isNotEmpty ||
                            subfolders.isNotEmpty
                        ? AutoSizeText(
                            'folder_actions.delete_folder_content_warning'
                                .tr(namedArgs: {
                            'docCount': documentsInFolder.length.toString(),
                            'subfolderCount': subfolders.length.toString()
                          }))
                        : AutoSizeText('folder_actions.delete_folder_confirm'
                            .tr(namedArgs: {'folderName': folder.name})),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: AutoSizeText('common.cancel'.tr()),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {});
                          Navigator.pop(context, true);
                        },
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.red),
                        child: AutoSizeText('common.delete'.tr()),
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
            type: SnackBarType.success,
            message: 'folder_actions.folder_deleted'.tr());

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
                  child: AutoSizeText(
                    folder.name,
                    style: GoogleFonts.slabo27px(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OptionTile(
                  icon: Icons.edit_outlined,
                  title: 'folder_actions.rename_folder_option'.tr(),
                  description: 'folder_actions.change_folder_name'.tr(),
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
                OptionTile(
                  icon: Icons.palette_outlined,
                  title: 'folder_actions.change_color_option'.tr(),
                  description: 'folder_actions.customize_appearance'.tr(),
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
                  OptionTile(
                    icon: Icons.drive_file_move_outlined,
                    title: 'folder_actions.move_folder'.tr(),
                    description: 'folder_actions.change_location'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      // Implement move folder functionality
                    },
                  ),
                OptionTile(
                  icon: Icons.note_add,
                  title: 'folder_actions.add_documents_option'.tr(),
                  description: 'folder_actions.move_documents_to'
                      .tr(namedArgs: {'folderName': folder.name}),
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!(folder);
                    } else {
                      FolderActions.addDocumentsToFolder(
                        context,
                        folder,
                        ref,
                      );
                    }
                  },
                ),
                const Divider(),
                OptionTile(
                  icon: Icons.delete_outlined,
                  iconColor: Colors.red,
                  title: 'folder_actions.delete_folder_option'.tr(),
                  description: 'folder_actions.remove_folder'.tr(),
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
}
