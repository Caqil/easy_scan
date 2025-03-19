import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/screen/compression/components/compression_tools.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart' as path;
import 'package:scanpro/ui/widget/option_tile.dart';
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

class _DocumentOptionsSheet extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final extension = path.extension(document.pdfPath).toLowerCase();
    final isPdf = extension == '.pdf';
    final List<String> editableExtensions = ['.pdf', '.jpg', '.jpeg', '.png'];
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
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${document.pageCount} pages • ${DateTimeUtils.formatDateTime(document.modifiedAt)}',
                        style: GoogleFonts.slabo27px(
                          fontWeight: FontWeight.w700,
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
                OptionTile(
                  icon: Icons.edit_outlined,
                  title: 'common.rename'.tr(),
                  description: 'document.change_document_name'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    if (onRename != null) {
                      onRename!(document);
                    }
                  },
                ),
                if (editableExtensions.contains(extension))
                  OptionTile(
                    icon: Icons.edit_attributes,
                    title: 'common.edit'.tr(),
                    description: 'document.edit_document'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      if (onEdit != null) {
                        onEdit!(document);
                      }
                    },
                  ),
                OptionTile(
                  icon: document.isFavorite ? Icons.star : Icons.star_outline,
                  iconColor: document.isFavorite ? Colors.amber : null,
                  title: document.isFavorite
                      ? 'document.remove_from_favorites'.tr()
                      : 'document.add_to_favorites'.tr(),
                  description: document.isFavorite
                      ? 'document.remove_from_favorites_desc'.tr()
                      : 'document.easy_access_favorites'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    final updatedDoc = document.copyWith(
                      isFavorite: !document.isFavorite,
                      modifiedAt: DateTime.now(),
                      folderId: document.folderId, // Preserve the folder ID
                    );
                    ref
                        .read(documentsProvider.notifier)
                        .updateDocument(updatedDoc);

                    AppDialogs.showSnackBar(
                      context,
                      type: SnackBarType.success,
                      message: document.isFavorite
                          ? 'document.removed_from_favorites'.tr()
                          : 'document.added_to_favorites'.tr(),
                    );
                  },
                ),
                OptionTile(
                  icon: Icons.folder_outlined,
                  title: 'document.move_to_folder'.tr(),
                  description: 'document.organize_documents'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    if (onMoveToFolder != null) {
                      onMoveToFolder!(document);
                    }
                  },
                ),
                OptionTile(
                  icon: Icons.share_outlined,
                  title: 'common.share'.tr(),
                  description: 'share.share_via_apps'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    if (onShare != null) {
                      onShare!(document);
                    }
                  },
                ),
                if (isPdf)
                  OptionTile(
                    icon: Icons.compress,
                    title: 'compression.compress_pdf'.tr(),
                    description: 'compression.reduce_file_size'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      if (onCompress != null) {
                        onCompress!(document);
                      } else {
                        PdfCompressionUtils.showQuickCompressionDialog(
                            context, ref, document);
                      }
                    },
                  ),
                if (isPdf)
                  OptionTile(
                    icon: document.isPasswordProtected
                        ? Icons.lock_outline
                        : Icons.lock_open_outlined,
                    title: document.isPasswordProtected
                        ? 'pdf.change_password'.tr()
                        : 'pdf.add_password'.tr(),
                    description: document.isPasswordProtected
                        ? 'pdf.update_security'.tr()
                        : 'pdf.protect_with_password'.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      _showPasswordBottomSheet(context, document);
                    },
                  ),
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                OptionTile(
                  icon: Icons.delete_outline,
                  iconColor: Colors.red,
                  title: 'document.delete_document'.tr(),
                  description: 'document.permanent_delete'.tr(),
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
        child: PasswordBottomSheet(document: document),
      ),
    );
  }
}
