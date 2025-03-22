import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/document.dart';
import 'package:scanpro/providers/document_provider.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:scanpro/ui/common/document_actions.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AllDocumentsScreen extends ConsumerStatefulWidget {
  const AllDocumentsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AllDocumentsScreen> createState() => _AllDocumentsScreenState();
}

class _AllDocumentsScreenState extends ConsumerState<AllDocumentsScreen> {
  String _searchQuery = '';
  bool _isSearching = false;
  SortOption _currentSortOption = SortOption.newest;
  final TextEditingController _searchController = TextEditingController();

  // Pagination variables
  final int _itemsPerPage = 5;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _currentPage = 0; // Reset to first page on new search
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Document> _sortAndFilterDocuments(List<Document> documents) {
    if (documents.isEmpty) {
      return [];
    }

    // First, sort the documents
    final List<Document> sortedDocs = List.from(documents);

    switch (_currentSortOption) {
      case SortOption.newest:
        sortedDocs.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
        break;
      case SortOption.oldest:
        sortedDocs.sort((a, b) => a.modifiedAt.compareTo(b.modifiedAt));
        break;
      case SortOption.nameAZ:
        sortedDocs.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case SortOption.nameZA:
        sortedDocs.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
    }

    // Then, filter based on search query
    if (_isSearching && _searchQuery.isNotEmpty) {
      final lowercaseQuery = _searchQuery.toLowerCase();
      return sortedDocs.where((doc) {
        return doc.name.toLowerCase().contains(lowercaseQuery);
      }).toList();
    }

    return sortedDocs;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: AutoSizeText(
                'sort_documents'.tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              title: AutoSizeText('newest_first'.tr()),
              leading: Icon(
                Icons.arrow_downward,
                color: _currentSortOption == SortOption.newest
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              selected: _currentSortOption == SortOption.newest,
              onTap: () {
                setState(() {
                  _currentSortOption = SortOption.newest;
                  _currentPage = 0; // Reset to first page on sort change
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: AutoSizeText('oldest_first'.tr()),
              leading: Icon(
                Icons.arrow_upward,
                color: _currentSortOption == SortOption.oldest
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              selected: _currentSortOption == SortOption.oldest,
              onTap: () {
                setState(() {
                  _currentSortOption = SortOption.oldest;
                  _currentPage = 0; // Reset to first page on sort change
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: AutoSizeText('name_az'.tr()),
              leading: Icon(
                Icons.sort_by_alpha,
                color: _currentSortOption == SortOption.nameAZ
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              selected: _currentSortOption == SortOption.nameAZ,
              onTap: () {
                setState(() {
                  _currentSortOption = SortOption.nameAZ;
                  _currentPage = 0; // Reset to first page on sort change
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: AutoSizeText('name_za'.tr()),
              leading: Icon(
                Icons.sort_by_alpha,
                color: _currentSortOption == SortOption.nameZA
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              selected: _currentSortOption == SortOption.nameZA,
              onTap: () {
                setState(() {
                  _currentSortOption = SortOption.nameZA;
                  _currentPage = 0; // Reset to first page on sort change
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _currentPage = 0; // Reset to first page when search is closed
      }
    });
  }

  void _nextPage(int totalPages) {
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _viewDocument(Document document) {
    Navigator.pushNamed(
      context,
      '/view',
      arguments: document,
    );
  }

  void _showDocumentOptions(Document document) {
    DocumentActions.showDocumentOptions(
      context,
      document,
      ref,
      onRename: _renameDocument,
      onEdit: _editDocument,
      onMoveToFolder: _moveDocumentToFolder,
      onShare: _shareDocument,
      onDelete: _deleteDocument,
    );
  }

  void _renameDocument(Document document) {
    AppDialogs.showInputDialog(
      context,
      title: 'document.rename_document'.tr(),
      initialValue: document.name,
      hintText: 'document.enter_new_name'.tr(),
    ).then((newName) {
      if (newName != null && newName.isNotEmpty) {
        final updatedDoc = document.copyWith(
          name: newName,
          modifiedAt: DateTime.now(),
        );
        ref.read(documentsProvider.notifier).updateDocument(updatedDoc);

        AppDialogs.showSnackBar(
          context,
          message: 'document.document_renamed'.tr(),
          type: SnackBarType.success,
        );

        setState(() {}); // Refresh the UI
      }
    });
  }

  void _editDocument(Document document) {
    Navigator.pushNamed(
      context,
      '/edit',
      arguments: document,
    ).then((_) => setState(() {})); // Refresh the UI on return
  }

  void _moveDocumentToFolder(Document document) {
    // This would open your folder selection screen
    Navigator.pushNamed(
      context,
      '/folder_selection',
      arguments: document,
    ).then((_) => setState(() {})); // Refresh the UI on return
  }

  void _shareDocument(Document document) {
    // Implement share functionality
  }
  void _deleteDocument(Document document) {
    AppDialogs.showConfirmDialog(context,
            title: 'document.delete_document'.tr(),
            message: 'document.delete_confirm_message'
                .tr(namedArgs: {'name': document.name}),
            confirmText: 'document.delete'.tr(),
            isDangerous: true)
        .then((confirmed) {
      if (confirmed) {
        ref.read(documentsProvider.notifier).deleteDocument(document.id);
        AppDialogs.showSnackBar(context,
            message: 'document.document_deleted'.tr(),
            type: SnackBarType.success);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use watch to listen for documents changes
    final List<Document> allDocuments = ref.watch(documentsProvider);

    // Sort and filter documents based on current settings
    final List<Document> filteredDocs = _sortAndFilterDocuments(allDocuments);

    // Calculate pagination values
    final int totalPages = (filteredDocs.isEmpty)
        ? 1
        : ((filteredDocs.length - 1) ~/ _itemsPerPage) + 1;

    // Ensure current page is in valid range
    if (_currentPage >= totalPages) {
      _currentPage = totalPages > 0 ? totalPages - 1 : 0;
    }

    // Get the documents for the current page
    final int startIndex = _currentPage * _itemsPerPage;
    final int endIndex = (startIndex + _itemsPerPage) < filteredDocs.length
        ? (startIndex + _itemsPerPage)
        : filteredDocs.length;

    List<Document> currentPageDocs = [];
    if (filteredDocs.isNotEmpty && startIndex < filteredDocs.length) {
      currentPageDocs = filteredDocs.sublist(startIndex, endIndex);
    }

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.brightness == Brightness.dark
          ? Colors.grey.shade900
          : Colors.grey.shade50,
      appBar: CustomAppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'search_documents'.tr(),
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.slabo27px(
                      fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                ),
                style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              )
            : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'all'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.w700,
                        fontSize: 18.sp,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    TextSpan(
                      text: 'chip_format_selector.categories.documents'.tr(),
                      style: GoogleFonts.slabo27px(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            color: primaryColor,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortOptions,
            color: primaryColor,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header with document count and segmented indicator for pagination
          if (filteredDocs.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    offset: Offset(0, 1),
                    blurRadius: 3.r,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 16.sp,
                            color: primaryColor,
                          ),
                          SizedBox(width: 8.w),
                          AutoSizeText(
                            'Showing ${currentPageDocs.length} of ${filteredDocs.length} documents',
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.sp,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                      if (totalPages > 1)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: AutoSizeText(
                            'Page ${_currentPage + 1} of $totalPages',
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Pagination dots indicator for pages
                  if (totalPages > 1)
                    Padding(
                      padding: EdgeInsets.only(top: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          totalPages > 5 ? 5 : totalPages,
                          (index) {
                            // For more than 5 pages, show ellipsis
                            if (totalPages > 5 && index == 4) {
                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: AutoSizeText(
                                  '...',
                                  style: GoogleFonts.slabo27px(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }

                            // Adjust index for pagination with many pages
                            int dotIndex = index;
                            if (totalPages > 5) {
                              if (_currentPage >= totalPages - 2) {
                                // Near end - show last 4 dots
                                dotIndex = totalPages - 5 + index;
                              } else if (_currentPage >= 2) {
                                // In middle - show current and surrounding
                                dotIndex = _currentPage - 2 + index;
                              }
                            }

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _currentPage = dotIndex;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                width: dotIndex == _currentPage ? 20.w : 8.w,
                                height: 8.h,
                                decoration: BoxDecoration(
                                  color: dotIndex == _currentPage
                                      ? primaryColor
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Documents list or empty state
          filteredDocs.isEmpty
              ? _buildEmptyState()
              : Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    itemCount: currentPageDocs.length,
                    itemBuilder: (context, index) {
                      final document = currentPageDocs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 10.h),
                        elevation: 0,
                        child: ListTile(
                          leading: Container(
                            width: 40.w,
                            height: 50.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4.r),
                              color: Colors.grey.shade200,
                            ),
                            child: document.thumbnailPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4.r),
                                    child: Image.file(
                                      File(document.thumbnailPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, error, stackTrace) =>
                                          Icon(Icons.description,
                                              color: Colors.grey),
                                    ),
                                  )
                                : Icon(Icons.description, color: Colors.grey),
                          ),
                          title: AutoSizeText(
                            document.name,
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: AutoSizeText(
                            '${document.pageCount} pages',
                            style: GoogleFonts.slabo27px(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.more_vert),
                            onPressed: () => _showDocumentOptions(document),
                          ),
                          onTap: () => _viewDocument(document),
                        ),
                      );
                    },
                  ),
                ),

          // Pagination controls at the bottom
          if (filteredDocs.isNotEmpty && totalPages > 1)
            Container(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, -2),
                    blurRadius: 5.r,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // First page button
                  _buildPaginationButton(
                    icon: Icons.first_page,
                    onTap: _currentPage > 0
                        ? () => setState(() => _currentPage = 0)
                        : null,
                    isActive: _currentPage > 0,
                  ),

                  // Previous page button
                  _buildPaginationButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: _currentPage > 0 ? _previousPage : null,
                    isActive: _currentPage > 0,
                  ),

                  // Page indicator button
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: AutoSizeText(
                      '${_currentPage + 1} / $totalPages',
                      style: GoogleFonts.slabo27px(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Next page button
                  _buildPaginationButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onTap: _currentPage < totalPages - 1
                        ? () => _nextPage(totalPages)
                        : null,
                    isActive: _currentPage < totalPages - 1,
                  ),

                  // Last page button
                  _buildPaginationButton(
                    icon: Icons.last_page,
                    onTap: _currentPage < totalPages - 1
                        ? () => setState(() => _currentPage = totalPages - 1)
                        : null,
                    isActive: _currentPage < totalPages - 1,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Helper widget for pagination buttons
  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isActive,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            color:
                isActive ? primaryColor.withOpacity(0.1) : Colors.transparent,
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: isActive ? primaryColor : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.description_outlined,
              size: 64.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            AutoSizeText(
              _isSearching
                  ? 'empty_state.searching.no_documents_match'.tr()
                  : 'not_searching.no_documents_found'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            AutoSizeText(
              _isSearching
                  ? 'empty_state.searching.try_different_term'.tr()
                  : 'not_searching.scan_or_import'.tr(),
              style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.w700,
                fontSize: 14.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            if (!_isSearching) ...[
              SizedBox(height: 24.h),
              OutlinedButton.icon(
                onPressed: () {
                  // Navigate to scan screen or show scan options
                  Navigator.pushNamed(context, '/scan');
                },
                icon: const Icon(Icons.add),
                label: AutoSizeText('not_searching.create_new_document'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum SortOption {
  newest,
  oldest,
  nameAZ,
  nameZA,
}
