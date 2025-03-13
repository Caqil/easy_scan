// Add this to your lib/ui/common/folder_creator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/folder.dart';
import '../../providers/folder_provider.dart';
import '../../utils/constants.dart';

/// A globally accessible class to handle folder creation
class FolderCreator {
  /// Show a bottom sheet to create a new folder
  static Future<Folder?> showCreateFolderBottomSheet(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Create New Folder',
    String? parentId,
  }) async {
    final TextEditingController controller = TextEditingController();
    Folder? createdFolder;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return _CreateFolderBottomSheet(
              controller: controller,
              parentId: parentId,
              title: title,
              ref: ref,
              onFolderCreated: (folder) {
                createdFolder = folder;
              },
            );
          },
        );
      },
    );

    controller.dispose();
    return createdFolder;
  }
}

class _CreateFolderBottomSheet extends StatefulWidget {
  final TextEditingController controller;
  final String? parentId;
  final String title;
  final WidgetRef ref;
  final Function(Folder) onFolderCreated;

  const _CreateFolderBottomSheet({
    required this.controller,
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
  int selectedColor = AppConstants.folderColors[0];
  bool isLoading = false;

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
                height: 4,
                width: 40,
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
                    width: 40,
                    height: 40,
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
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 20,
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
                      controller: widget.controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: 'Folder Name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Enter folder name',
                        prefixIcon: const Icon(Icons.folder_outlined),
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Select Color:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
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
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createFolder,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Create'),
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
    if (widget.controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a folder name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final newFolder = Folder(
        name: widget.controller.text.trim(),
        color: selectedColor,
        parentId: widget.parentId,
      );

      await widget.ref.read(foldersProvider.notifier).addFolder(newFolder);
      widget.onFolderCreated(newFolder);

      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Folder created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating folder: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Example usage:
/*
void _showCreateFolderBottomSheet() async {
  final folder = await FolderCreator.showCreateFolderBottomSheet(
    context, 
    ref,
    title: 'Create New Folder',
    parentId: currentFolder?.id,  // Optional parent folder ID
  );
  
  if (folder != null) {
    // Use the created folder
    print('Created folder: ${folder.name}');
  }
}
*/
