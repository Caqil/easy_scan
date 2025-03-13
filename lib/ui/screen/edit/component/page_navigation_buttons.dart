import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Buttons for navigating between document pages
class PageNavigationButtons extends StatelessWidget {
  final int currentPageIndex;
  final int pageCount;
  final PageController pageController;

  const PageNavigationButtons({
    super.key,
    required this.currentPageIndex,
    required this.pageCount,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page button
          if (currentPageIndex > 0) _buildPreviousButton(),

          // Next page button
          if (currentPageIndex < pageCount - 1) _buildNextButton(),
        ],
      ),
    );
  }

  Widget _buildPreviousButton() {
    return GestureDetector(
      onTap: () {
        pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 30.w,
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return GestureDetector(
      onTap: () {
        pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        width: 30.w,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_right_rounded,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
