import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicSelector extends StatelessWidget {
  final List<String> topics;
  final int selectedIndex;
  final ValueChanged<int> onTopicSelected;

  const TopicSelector({
    super.key,
    required this.topics,
    required this.selectedIndex,
    required this.onTopicSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: topics.length,
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        itemBuilder: (context, index) {
          final isSelected = selectedIndex == index;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
            child: InkWell(
              onTap: () => onTopicSelected(index),
              borderRadius: BorderRadius.circular(16.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                alignment: Alignment.center,
                child: AutoSizeText(
                  topics[index],
                  style: GoogleFonts.slabo27px(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
