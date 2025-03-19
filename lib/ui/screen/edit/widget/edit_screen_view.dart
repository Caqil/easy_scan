import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/component/scanned_documents_view.dart';
import 'package:scanpro/ui/screen/edit/component/document_action_button.dart';
import 'package:scanpro/ui/screen/edit/component/document_action_handler.dart';
import 'package:scanpro/ui/screen/edit/component/document_name_input.dart';
import 'package:scanpro/ui/screen/edit/component/document_preview.dart';
import 'package:scanpro/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:scanpro/ui/screen/edit/component/save_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as path;

class EditScreenView extends StatefulWidget {
  final EditScreenController controller;

  const EditScreenView({super.key, required this.controller});

  @override
  State<EditScreenView> createState() => _EditScreenViewState();
}

class _EditScreenViewState extends State<EditScreenView> {
  late final DocumentActionHandler actionHandler;

  @override
  void initState() {
    super.initState();
    actionHandler = DocumentActionHandler(widget.controller);
    widget.controller.setStateCallback(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.controller.pages.isEmpty && widget.controller.isProcessing) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: CustomAppBar(
        title: _buildAppBarTitle(colorScheme),
        elevation: 0,
        actions: [
          // Edit mode toggle - only show if switching is allowed
          if (widget.controller.canSwitchEditMode)
            PopupMenuButton<EditMode>(
              tooltip: 'edit_screen.editor.change_edit_mode'.tr(),
              icon: Icon(
                widget.controller.currentEditMode == EditMode.imageEdit
                    ? Icons.image
                    : Icons.picture_as_pdf,
              ),
              onSelected: (EditMode mode) {
                widget.controller.switchEditMode(mode);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: EditMode.imageEdit,
                  child: ListTile(
                    leading: Icon(Icons.image,
                        color: widget.controller.currentEditMode ==
                                EditMode.imageEdit
                            ? colorScheme.primary
                            : null),
                    title: Text('edit_screen.editor.edit_as_images'.tr()),
                    selected:
                        widget.controller.currentEditMode == EditMode.imageEdit,
                  ),
                ),
                PopupMenuItem(
                  value: EditMode.pdfEdit,
                  child: ListTile(
                    leading: Icon(Icons.picture_as_pdf,
                        color: widget.controller.currentEditMode ==
                                EditMode.pdfEdit
                            ? colorScheme.primary
                            : null),
                    title: Text('edit_screen.editor.edit_as_pdf'.tr()),
                    selected:
                        widget.controller.currentEditMode == EditMode.pdfEdit,
                  ),
                ),
              ],
            ),

          !widget.controller.canSwitchEditMode &&
                  widget.controller.isPdfInputFile
              ? SizedBox.shrink()
              : IconButton(
                  icon: Icon(widget.controller.isEditView
                      ? Icons.grid_view
                      : Icons.edit),
                  tooltip: widget.controller.isEditView
                      ? 'edit_screen.view_mode.grid_view'.tr()
                      : 'edit_screen.view_mode.edit_view'.tr(),
                  onPressed: () {
                    widget.controller.toggleViewMode();
                  },
                ),
        ],
      ),
      body: widget.controller.isEditView
          ? _buildEditView(colorScheme)
          : _buildGridView(colorScheme),
    );
  }

  Widget _buildAppBarTitle(ColorScheme colorScheme) {
    // Show edit mode indicator in the title
    return Row(
      children: [
        Text(
          widget.controller.isEditingExistingDocument
              ? 'edit_screen.edit_document'.tr()
              : 'edit_screen.new_document'.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (widget.controller.isImageOnlyDocument) ...[
          const SizedBox(width: 8),
          Chip(
            label: Text('edit_screen.image_editor'.tr(),
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700, fontSize: 10)),
            backgroundColor: colorScheme.primaryContainer,
            labelStyle: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ] else if (!widget.controller.canSwitchEditMode &&
            widget.controller.isPdfInputFile) ...[
          const SizedBox(width: 8),
          Chip(
            label: Text('edit_screen.pdf_only'.tr(),
                style: GoogleFonts.slabo27px(
                    fontWeight: FontWeight.w700, fontSize: 10)),
            backgroundColor: colorScheme.primaryContainer,
            labelStyle: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildEditView(ColorScheme colorScheme) {
    return Column(
      children: [
        DocumentNameInput(
          controller: widget.controller.documentNameController,
          colorScheme: colorScheme,
        ),
        Expanded(
          child: DocumentPreview(
            pages: widget.controller.pages,
            currentPageIndex: widget.controller.currentPageIndex,
            pageController: widget.controller.pageController,
            isProcessing: widget.controller.isProcessing,
            colorScheme: colorScheme,
            onPageChanged: (index) {
              widget.controller.currentPageIndex = index;
              setState(() {});
            },
            onDeletePage: widget.controller.deletePageAtIndex,
            isPdfPreviewMode:
                widget.controller.currentEditMode == EditMode.pdfEdit &&
                    _containsPdfFiles(),
            password: widget.controller.isPasswordProtected
                ? widget.controller.passwordController.text
                : null,
          ),
        ),
        DocumentActionButtons(
          colorScheme: colorScheme,
          isPasswordProtected: widget.controller.isPasswordProtected,
          onPasswordTap: actionHandler.showPasswordOptions,
          onSignatureTap: actionHandler.showSignatureOptions,
          onWatermarkTap: actionHandler.showWatermarkOptions,
          onExtractTextTap: actionHandler.showExtractTextOptions,
          onFindTextTap: actionHandler.showFindTextOptions,
          onShareTap: () {},
        ),
        SaveButton(
          onSave: widget.controller.saveDocument,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildGridView(ColorScheme colorScheme) {
    return Column(
      children: [
        DocumentNameInput(
          controller: widget.controller.documentNameController,
          colorScheme: colorScheme,
        ),
        Expanded(
          child: ScannedDocumentsView(
            pages: widget.controller.pages,
            currentIndex: widget.controller.currentPageIndex,
            isProcessing: widget.controller.isProcessing,
            onPageTap: (index) {
              widget.controller.currentPageIndex = index;
              widget.controller.openImageEditor();
            },
            onPageRemove: widget.controller.deletePageAtIndex,
            onPagesReorder: widget.controller.reorderPages,
            onAddMore: widget.controller.addMorePages,
          ),
        ),
        SaveButton(
          onSave: widget.controller.saveDocument,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  bool _containsPdfFiles() {
    if (widget.controller.pages.isEmpty) return false;

    for (final page in widget.controller.pages) {
      final extension = path.extension(page.path).toLowerCase();
      if (extension == '.pdf') return true;
    }

    return false;
  }
}
