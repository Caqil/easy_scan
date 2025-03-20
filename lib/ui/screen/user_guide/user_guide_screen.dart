import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/ui/common/app_bar.dart';
import 'package:scanpro/ui/screen/user_guide/components/guide_content_builder.dart';
import 'package:scanpro/ui/screen/user_guide/components/topic_selector.dart';

class UserGuideScreen extends ConsumerStatefulWidget {
  const UserGuideScreen({super.key});

  @override
  ConsumerState<UserGuideScreen> createState() => _UserGuideScreenState();
}

class _UserGuideScreenState extends ConsumerState<UserGuideScreen> {
  int _selectedTopicIndex = 0;

  final List<String> _topics = [
    'Getting Started',
    'Document Scanning',
    'Document Management',
    'Organization',
    'Editing & Enhancing',
    'PDF Tools',
    'Security',
    'Import & Export',
    'Settings',
    'Troubleshooting'
  ];

  void _onTopicSelected(int index) {
    setState(() {
      _selectedTopicIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: Text(
          "user_guide.title".tr(),
          style: GoogleFonts.lilitaOne(
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          TopicSelector(
            topics: _topics,
            selectedIndex: _selectedTopicIndex,
            onTopicSelected: _onTopicSelected,
          ),
          Expanded(
            child: GuideContentBuilder(selectedTopicIndex: _selectedTopicIndex),
          ),
        ],
      ),
    );
  }
}
