import 'dart:io';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import '../../models/document.dart';
import '../../providers/document_provider.dart';
import '../../utils/date_utils.dart';
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
      ),
    );
  }
}

class _DocumentOptionsSheet extends ConsumerWidget {
  final Document document;
  final WidgetRef ref;
  final Function(Document)? onRename;
  final Function(Document)? onEdit;
  final Function(Document)? onMoveToFolder;
  final Function(Document)? onShare;
  final Function(Document)? onDelete;

  const _DocumentOptionsSheet({
    required this.document,
    required this.ref,
    this.onRename,
    this.onEdit,
    this.onMoveToFolder,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extension = path.extension(document.pdfPath).toLowerCase();
    final isPdf = extension == '.pdf';
    final List<String> editableExtensions = ['jpg', 'jpeg', 'png'];
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
                        style: GoogleFonts.notoSerif(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${document.pageCount} pages • ${DateTimeUtils.formatDateTime(document.modifiedAt)}',
                        style: GoogleFonts.notoSerif(
                          color: Colors.grey.shade600,
                          fontSize: 10.sp,
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
                    }
                  },
                ),
                !editableExtensions.contains(extension)
                    ? _buildOptionTile(
                        context,
                        icon: Icons.share_outlined,
                        title: 'Edit',
                        description: 'Edit document',
                        onTap: () {
                          Navigator.pop(context);
                          if (onEdit != null) {
                            onEdit!(document);
                          }
                        },
                      )
                    : SizedBox.shrink(),
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

                    AppDialogs.showSnackBar(
                      context,
                      type: SnackBarType.success,
                      message: document.isFavorite
                          ? 'Removed from favorites'
                          : 'Added to favorites',
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
                if (isPdf)
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
        child: PasswordBottomSheet(document: document, ref: ref),
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
              width: 30.w,
              height: 30.h,
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
                    style: GoogleFonts.notoSerif(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.notoSerif(
                      fontSize: 10.sp,
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
