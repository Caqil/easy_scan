import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../models/folder.dart';
import '../../../../providers/folder_provider.dart';
import '../../../../utils/constants.dart';

/// A globally accessible class to handle folder creation
class FolderCreator {
  /// Show a bottom sheet to create a new folder
  static Future<Folder?> showCreateFolderBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    String title = '', // Updated default value
    String? parentId,
  }) async {
    Folder? createdFolder;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _CreateFolderBottomSheet(
          parentId: parentId,
          title: title,
          ref: ref,
          onFolderCreated: (folder) {
            createdFolder = folder;
          },
        );
      },
    );

    return createdFolder;
  }
}

class _CreateFolderBottomSheet extends StatefulWidget {
  final String? parentId;
  final String title;
  final WidgetRef ref;
  final Function(Folder) onFolderCreated;

  const _CreateFolderBottomSheet({
    required this.parentId,
    required this.title,
    required this.ref,
    required this.onFolderCreated,
  });

  @override
  State<_CreateFolderBottomSheet> createState() =>
      _CreateFolderBottomSheetState();
}

class _CreateFolderBottomSheetState extends State<_CreateFolderBottomSheet> {
  late final TextEditingController _controller; // Managed internally
  int selectedColor = AppConstants.folderColors[0];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(); // Initialize here
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                height: 2.h,
                width: 30.w,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Header
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
                      Icons.create_new_folder_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AutoSizeText(
                    widget.title,
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.adaptiveSp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              const Padding(
                padding: EdgeInsets.all(32.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller, // Use internal controller
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'folder_creator.folder_name'.tr(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'folder_creator.enter_folder_name'.tr(),
                        prefixIcon: const Icon(Icons.folder_outlined),
                      ),
                      style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700, fontSize: 14.adaptiveSp),
                    ),
                    const SizedBox(height: 20),
                    AutoSizeText(
                      'folder_creator.select_color'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.adaptiveSp,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: AppConstants.folderColors.length,
                        itemBuilder: (context, index) {
                          final color = AppConstants.folderColors[index];
                          final isSelected = selectedColor == color;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Color(color).withOpacity(0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        )
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.white)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context); // Simply pop the context
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: AutoSizeText('common.cancel'.tr()),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _createFolder,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: AutoSizeText('folder_creator.create'.tr()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Future<void> _createFolder() async {
    if (_controller.text.trim().isEmpty) {
      AppDialogs.showSnackBar(context,
          type: SnackBarType.error,
          message: 'folder_creator.folder_name_empty'.tr());
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final newFolder = Folder(
        name: _controller.text.trim(),
        color: selectedColor,
        parentId: widget.parentId,
      );

      await widget.ref.read(foldersProvider.notifier).addFolder(newFolder);
      widget.onFolderCreated(newFolder);

      if (!mounted) return; // Ensure widget is still mounted
      Navigator.pop(context);

      AppDialogs.showSnackBar(context,
          type: SnackBarType.success,
          message: 'folder_creator.folder_created_success'.tr());
    } catch (e) {
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        isLoading = false;
      });

      AppDialogs.showSnackBar(context,
          type: SnackBarType.error,
          message: 'folder_creator.error_creating_folder'
              .tr(namedArgs: {'error': e.toString()}));
    }
  }
}
