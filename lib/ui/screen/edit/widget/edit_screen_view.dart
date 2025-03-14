import 'package:easy_scan/ui/common/app_bar.dart';
import 'package:easy_scan/ui/screen/camera/component/scanned_documents_view.dart';
import 'package:easy_scan/ui/screen/edit/component/document_action_button.dart';
import 'package:easy_scan/ui/screen/edit/component/document_action_handler.dart';
import 'package:easy_scan/ui/screen/edit/component/document_name_input.dart';
import 'package:easy_scan/ui/screen/edit/component/document_preview.dart';
import 'package:easy_scan/ui/screen/edit/component/edit_screen_controller.dart';
import 'package:easy_scan/ui/screen/edit/component/save_button.dart';
import 'package:flutter/material.dart';

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
          IconButton(
            icon: Icon(
                widget.controller.isEditView ? Icons.grid_view : Icons.edit),
            tooltip: widget.controller.isEditView ? 'Grid View' : 'Edit View',
            onPressed: () {
              widget.controller.toggleViewMode();
              setState(() {});
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
    return Text(
      widget.controller.isEditingExistingDocument
          ? 'Edit Document'
          : 'New Document',
      style: const TextStyle(fontWeight: FontWeight.bold),
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
}
