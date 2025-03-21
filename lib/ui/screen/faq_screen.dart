import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/routes.dart';
import '../common/app_bar.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: AutoSizeText(
          "faq.title".tr(),
          style: GoogleFonts.lilitaOne(
            fontSize: 25.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.r),
          children: [
            _buildFaqHeader(context),
            SizedBox(height: 16.h),
            _buildFaqSection(
              context: context,
              title: "faq.general_questions".tr(),
              faqs: _generalQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.scanning_documents".tr(),
              faqs: _scanningQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.file_management".tr(),
              faqs: _fileManagementQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.backup_sync".tr(),
              faqs: _backupQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.advanced_features".tr(),
              faqs: _advancedQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.troubleshooting".tr(),
              faqs: _troubleshootingQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.privacy_security".tr(),
              faqs: _privacyQuestions(),
            ),
            _buildFaqSection(
              context: context,
              title: "faq.app_settings".tr(),
              faqs: _settingsQuestions(),
            ),
            SizedBox(height: 24.h),
            _buildSupportSection(context),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 24.r,
              ),
              SizedBox(width: 12.w),
              AutoSizeText(
                "faq.welcome_to_faq".tr(),
                style: GoogleFonts.slabo27px(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            "faq.introduction".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> faqs,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.r),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: ExpansionTile(
        title: AutoSizeText(
          title,
          style: GoogleFonts.slabo27px(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        children: faqs
            .map((faq) => _buildFaqItem(
                  context: context,
                  question: faq['question']!,
                  answer: faq['answer']!,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: AutoSizeText(
        question,
        style: GoogleFonts.slabo27px(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      childrenPadding: EdgeInsets.fromLTRB(16.r, 0, 16.r, 16.r),
      children: [
        AutoSizeText(
          answer,
          style: GoogleFonts.slabo27px(
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutoSizeText(
            "faq.need_more_help".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            "faq.contact_support".tr(),
            style: GoogleFonts.slabo27px(
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton.icon(
            onPressed: () {
              AppRoutes.navigateToContactSupport(context);
            },
            icon: Icon(Icons.email_outlined),
            label: AutoSizeText("faq.email_support".tr()),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.r, horizontal: 16.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAQ Content by Section
  List<Map<String, String>> _generalQuestions() {
    return [
      {
        'question': "faq.what_is_scanpro.question".tr(),
        'answer': "faq.what_is_scanpro.answer".tr(),
      },
      {
        'question': "faq.platforms.question".tr(),
        'answer': "faq.platforms.answer".tr(),
      },
      {
        'question': "faq.free_to_use.question".tr(),
        'answer': "faq.free_to_use.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _scanningQuestions() {
    return [
      {
        'question': "faq.how_to_scan.question".tr(),
        'answer': "faq.how_to_scan.answer".tr(),
      },
      {
        'question': "faq.scan_types.question".tr(),
        'answer': "faq.scan_types.answer".tr(),
      },
      {
        'question': "faq.organize_documents.question".tr(),
        'answer': "faq.organize_documents.answer".tr(),
      },
      {
        'question': "faq.edit_documents.question".tr(),
        'answer': "faq.edit_documents.answer".tr(),
      },
      {
        'question': "faq.multiple_pages.question".tr(),
        'answer': "faq.multiple_pages.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _fileManagementQuestions() {
    return [
      {
        'question': "faq.file_formats.question".tr(),
        'answer': "faq.file_formats.answer".tr(),
      },
      {
        'question': "faq.share_documents.question".tr(),
        'answer': "faq.share_documents.answer".tr(),
      },
      {
        'question': "faq.password_protection.question".tr(),
        'answer': "faq.password_protection.answer".tr(),
      },
      {
        'question': "faq.compress_pdf.question".tr(),
        'answer': "faq.compress_pdf.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _backupQuestions() {
    return [
      {
        'question': "faq.backup_documents.question".tr(),
        'answer': "faq.backup_documents.answer".tr(),
      },
      {
        'question': "faq.backup_frequency.question".tr(),
        'answer': "faq.backup_frequency.answer".tr(),
      },
      {
        'question': "faq.restore_documents.question".tr(),
        'answer': "faq.restore_documents.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _advancedQuestions() {
    return [
      {
        'question': "faq.ocr.question".tr(),
        'answer': "faq.ocr.answer".tr(),
      },
      {
        'question': "faq.merge_pdfs.question".tr(),
        'answer': "faq.merge_pdfs.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _troubleshootingQuestions() {
    return [
      {
        'question': "faq.edge_detection.question".tr(),
        'answer': "faq.edge_detection.answer".tr(),
      },
      {
        'question': "faq.blurry_text.question".tr(),
        'answer': "faq.blurry_text.answer".tr(),
      },
      {
        'question': "faq.ocr_issues.question".tr(),
        'answer': "faq.ocr_issues.answer".tr(),
      },
      {
        'question': "faq.lost_scans.question".tr(),
        'answer': "faq.lost_scans.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _privacyQuestions() {
    return [
      {
        'question': "faq.data_security.question".tr(),
        'answer': "faq.data_security.answer".tr(),
      },
      {
        'question': "faq.cloud_storage.question".tr(),
        'answer': "faq.cloud_storage.answer".tr(),
      },
      {
        'question': "faq.sensitive_documents.question".tr(),
        'answer': "faq.sensitive_documents.answer".tr(),
      },
    ];
  }

  List<Map<String, String>> _settingsQuestions() {
    return [
      {
        'question': "faq.change_language.question".tr(),
        'answer': "faq.change_language.answer".tr(),
      },
      {
        'question': "faq.dark_mode.question".tr(),
        'answer': "faq.dark_mode.answer".tr(),
      },
      {
        'question': "faq.biometric_auth.question".tr(),
        'answer': "faq.biometric_auth.answer".tr(),
      },
    ];
  }
}
