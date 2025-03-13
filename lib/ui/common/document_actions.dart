import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../providers/folder_provider.dart';
import '../../utils/date_utils.dart';
import 'folder_creator.dart';
import 'folder_selection.dart';

/// A globally accessible class to handle document-related actions
class DocumentActions {
  /// Show document options bottom sheet
  static void showDocumentOptions(
    BuildContext context,
    Document document,
    WidgetRef ref, {
    Function(Document)? onRename,
    Function(Document)? onMoveToFolder,
    Function(Document)? onShare,
    Function(Document)? onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentOptionsSheet(
        document: document,
        ref: ref,
        onRename: onRename,
        onMoveToFolder: onMoveToFolder,
        onShare: onShare,
        onDelete: onDelete,
      ),
    );
  }

  /// Show rename document dialog
  static Future<void> showRenameDocumentDialog(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    final TextEditingController controller =
        TextEditingController(text: document.name);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Document Name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, controller.text.trim());
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (newName != null && newName.isNotEmpty) {
      final updatedDoc = document.copyWith(
        name: newName,
        modifiedAt: DateTime.now(),
      );

      ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document renamed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Show folder selection dialog to move a document
  static Future<void> showMoveToFolderDialog(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    // Get all folders
    final allFolders = ref.read(foldersProvider);

    // Show folder selection dialog
    final selectedFolder = await FolderSelector.showFolderSelectionDialog(
      context,
      allFolders,
      ref,
      onCreateFolder: () async {
        // Create a new folder directly as a destination
        await FolderCreator.showCreateFolderBottomSheet(
          context,
          ref,
          title: 'Create Destination Folder',
        );
      },
    );

    // If user selected a folder, move the document
    if (selectedFolder != null && context.mounted) {
      // Update document with new folder ID
      final updatedDoc = document.copyWith(
        folderId: selectedFolder.id,
        modifiedAt: DateTime.now(),
      );

      // Save the updated document
      await ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Moved to ${selectedFolder.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Show delete confirmation dialog
  static Future<void> showDeleteConfirmation(
    BuildContext context,
    Document document,
    WidgetRef ref,
  ) async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text(
                'Are you sure you want to delete "${document.name}"? This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm && context.mounted) {
      await ref.read(documentsProvider.notifier).deleteDocument(document.id);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}

/// Internal widget for the document options sheet
class _DocumentOptionsSheet extends ConsumerWidget {
  final Document document;
  final WidgetRef ref;
  final Function(Document)? onRename;
  final Function(Document)? onMoveToFolder;
  final Function(Document)? onShare;
  final Function(Document)? onDelete;

  const _DocumentOptionsSheet({
    required this.document,
    required this.ref,
    this.onRename,
    this.onMoveToFolder,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            height: 4,
            width: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Document info header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                // Document thumbnail
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: document.thumbnailPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.file(
                            File(document.thumbnailPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(Icons.picture_as_pdf,
                          color: Colors.blueGrey),
                ),
                const SizedBox(width: 16),

                // Document name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document.pageCount} pages • ${DateTimeUtils.formatDateTime(document.modifiedAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Rename',
                  description: 'Change document name',
                  onTap: () {
                    Navigator.pop(context);
                    if (onRename != null) {
                      onRename!(document);
                    } else {
                      DocumentActions.showRenameDocumentDialog(
                          context, document, ref);
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: document.isFavorite ? Icons.star : Icons.star_outline,
                  iconColor: document.isFavorite ? Colors.amber : null,
                  title: document.isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  description: document.isFavorite
                      ? 'Remove from your favorites list'
                      : 'Easy access in favorites',
                  onTap: () {
                    Navigator.pop(context);
                    // Toggle favorite status
                    final updatedDoc = document.copyWith(
                      isFavorite: !document.isFavorite,
                      modifiedAt: DateTime.now(),
                    );
                    ref
                        .read(documentsProvider.notifier)
                        .updateDocument(updatedDoc);

                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(document.isFavorite
                            ? 'Removed from favorites'
                            : 'Added to favorites'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.folder_outlined,
                  title: 'Move to Folder',
                  description: 'Organize your documents',
                  onTap: () {
                    Navigator.pop(context);
                    if (onMoveToFolder != null) {
                      onMoveToFolder!(document);
                    } else {
                      DocumentActions.showMoveToFolderDialog(
                          context, document, ref);
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.share_outlined,
                  title: 'Share',
                  description: 'Share via apps or link',
                  onTap: () {
                    Navigator.pop(context);
                    if (onShare != null) {
                      onShare!(document);
                    }
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: document.isPasswordProtected
                      ? Icons.lock_outline
                      : Icons.lock_open_outlined,
                  title: document.isPasswordProtected
                      ? 'Change Password'
                      : 'Add Password',
                  description: document.isPasswordProtected
                      ? 'Update document security'
                      : 'Protect with a password',
                  onTap: () {
                    Navigator.pop(context);
                    _showPasswordBottomSheet(context, document);
                  },
                ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildOptionTile(
                  context,
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  title: 'Delete Document',
                  description: 'Permanently delete this document',
                  textColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    if (onDelete != null) {
                      onDelete!(document);
                    } else {
                      DocumentActions.showDeleteConfirmation(
                          context, document, ref);
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

  void _showPasswordBottomSheet(BuildContext context, Document document) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _PasswordBottomSheet(document: document, ref: ref),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? Theme.of(context).primaryColor)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Password input bottom sheet component
class _PasswordBottomSheet extends StatefulWidget {
  final Document document;
  final WidgetRef ref;

  const _PasswordBottomSheet({
    required this.document,
    required this.ref,
  });

  @override
  State<_PasswordBottomSheet> createState() => _PasswordBottomSheetState();
}

class _PasswordBottomSheetState extends State<_PasswordBottomSheet> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.document.isPasswordProtected
                ? 'Change Password'
                : 'Add Password',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.document.isPasswordProtected
                ? 'Enter a new password for "${widget.document.name}"'
                : 'Add a password to protect "${widget.document.name}"',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            autofocus: true,
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
                  onPressed: _isLoading ? null : _applyPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _applyPassword() {
    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Apply password to document
    final updatedDoc = widget.document.copyWith(
      isPasswordProtected: true,
      password: _passwordController.text.trim(),
      modifiedAt: DateTime.now(),
    );

    // Add a slight delay to simulate processing
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      // Update document with password
      widget.ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      // Close the sheet and show success message
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.document.isPasswordProtected
                ? 'Password updated successfully'
                : 'Password added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
}
