import 'dart:io';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../utils/file_utils.dart';
import '../widget/password_bottom_sheet.dart';

/// A globally accessible class to handle document-related actions
class DocumentActions {
  /// Show document options bottom sheet
  static void showDocumentOptions(
    BuildContext context,
    Document document,
    WidgetRef ref, {
    Function(Document)? onRename,
    Function(Document)? onEdit,
    Function(Document)? onMoveToFolder,
    Function(Document)? onShare,
    Function(Document)? onDelete,
    Function(Document)? onCompress,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DocumentOptionsSheet(
        document: document,
        ref: ref,
        onRename: onRename,
        onEdit: onEdit,
        onMoveToFolder: onMoveToFolder,
        onShare: onShare,
        onDelete: onDelete,
        onCompress: onCompress,
      ),
    );
  }
}

class _DocumentOptionsSheet extends ConsumerStatefulWidget {
  final Document document;
  final WidgetRef ref;
  final Function(Document)? onRename;
  final Function(Document)? onEdit;
  final Function(Document)? onMoveToFolder;
  final Function(Document)? onShare;
  final Function(Document)? onDelete;
  final Function(Document)? onCompress;

  const _DocumentOptionsSheet({
    required this.document,
    required this.ref,
    this.onRename,
    this.onEdit,
    this.onMoveToFolder,
    this.onShare,
    this.onDelete,
    this.onCompress,
  });

  @override
  ConsumerState<_DocumentOptionsSheet> createState() =>
      _DocumentOptionsSheetState();
}

class _DocumentOptionsSheetState extends ConsumerState<_DocumentOptionsSheet> {
  String fileSize = "Calculating...";

  @override
  void initState() {
    super.initState();
    _getFileSize();
  }

  Future<void> _getFileSize() async {
    try {
      final size = await FileUtils.getFileSize(widget.document.pdfPath);
      if (mounted) {
        setState(() {
          fileSize = size;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          fileSize = "Unknown";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = path.extension(widget.document.pdfPath).toLowerCase();
    final isPdf = extension == '.pdf';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with document info and close button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Document thumbnail
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: widget.document.thumbnailPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(widget.document.thumbnailPath!),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.picture_as_pdf,
                          color: Colors.red.shade700,
                        ),
                ),
                const SizedBox(width: 12),
                // Document name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.document.name,
                        style: GoogleFonts.notoSerif(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.document.pageCount} pages • $fileSize',
                        style: GoogleFonts.notoSerif(
                          fontSize: 10.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.close,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // First row of actions
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionItem(
                  context: context,
                  icon: Icons.drive_file_move_outlined,
                  label: 'Move',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onMoveToFolder != null) {
                      widget.onMoveToFolder!(widget.document);
                    }
                  },
                ),
                _buildActionItem(
                  context: context,
                  icon: Icons.edit_outlined,
                  label: 'Rename',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onRename != null) {
                      widget.onRename!(widget.document);
                    } else {
                      _showRenameDialog();
                    }
                  },
                ),
                _buildActionItem(
                  context: context,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onDelete != null) {
                      widget.onDelete!(widget.document);
                    } else {
                      _showDeleteConfirmation();
                    }
                  },
                ),
                _buildActionItem(
                  context: context,
                  icon: widget.document.isFavorite
                      ? Icons.star
                      : Icons.star_border,
                  label: widget.document.isFavorite ? 'Unfavorite' : 'Favorite',
                  onTap: () {
                    Navigator.pop(context);
                    _toggleFavorite();
                  },
                ),
                _buildActionItem(
                  context: context,
                  icon: Icons.info_outline,
                  label: 'Info',
                  onTap: () {
                    Navigator.pop(context);
                    // Show document info implementation
                    AppDialogs.showSnackBar(context,
                        message: 'Info feature not implemented yet');
                  },
                ),
                isPdf
                    ? _buildActionItem(
                        context: context,
                        icon: widget.document.isPasswordProtected
                            ? Icons.lock_outline
                            : Icons.lock_open_outlined,
                        label: widget.document.isPasswordProtected
                            ? 'Change Password'
                            : 'Add Password',
                        onTap: () {
                          Navigator.pop(context);
                          _showPasswordBottomSheet();
                        },
                      )
                    : const SizedBox(width: 60),
              ],
            ),
          ),

          const Divider(height: 1),

          // Sharing options
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareItem(
                  context: context,
                  icon: Icons.email_outlined,
                  label: 'Email',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onShare != null) {
                      widget.onShare!(widget.document);
                    }
                  },
                ),
                _buildShareItem(
                  context: context,
                  icon: Icons.print,
                  label: 'Print',
                  onTap: () {
                    Navigator.pop(context);
                    // Print document implementation
                    AppDialogs.showSnackBar(context,
                        message: 'Print feature not implemented yet');
                  },
                ),
                _buildShareItem(
                  context: context,
                  icon: Icons.fax_outlined,
                  label: 'Fax',
                  onTap: () {
                    Navigator.pop(context);
                    // Fax document implementation
                    AppDialogs.showSnackBar(context,
                        message: 'Fax feature not implemented yet');
                  },
                ),
                _buildShareItem(
                  context: context,
                  icon: Icons.share,
                  label: 'Share',
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.onShare != null) {
                      widget.onShare!(widget.document);
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom handle indicator
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Safe area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  // Helper method to toggle favorite status
  void _toggleFavorite() {
    final updatedDoc = widget.document.copyWith(
      isFavorite: !widget.document.isFavorite,
      modifiedAt: DateTime.now(),
    );

    ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

    AppDialogs.showSnackBar(
      context,
      type: SnackBarType.success,
      message: widget.document.isFavorite
          ? 'Removed from favorites'
          : 'Added to favorites',
    );
  }

  void _showPasswordBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: PasswordBottomSheet(document: widget.document),
      ),
    );
  }

  Future<void> _showRenameDialog() async {
    final textController = TextEditingController(text: widget.document.name);

    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: CupertinoTextField(
          style: GoogleFonts.notoSerif(color: Theme.of(context).primaryColor),
          controller: textController,
          placeholder: 'Document Name',
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                Navigator.pop(context, textController.text.trim());
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != widget.document.name) {
      final updatedDoc = widget.document.copyWith(
        name: newName,
        modifiedAt: DateTime.now(),
      );

      ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message: 'Document renamed successfully',
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final bool confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Document'),
            content: Text(
                'Are you sure you want to delete "${widget.document.name}"?'),
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

    if (confirm) {
      await ref
          .read(documentsProvider.notifier)
          .deleteDocument(widget.document.id);

      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          type: SnackBarType.success,
          message: 'Document deleted successfully',
        );
      }
    }
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
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
              label,
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

  // Helper method to build share items in the bottom row
  Widget _buildShareItem({
    required BuildContext context,
    required IconData icon,
    required String label,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.amber.shade800,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontSize: 12.sp,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
