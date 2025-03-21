import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class GuideWidgets {
  final ScrollController scrollController;
  final BuildContext context;

  GuideWidgets({required this.scrollController, required this.context});

  // Content Methods

  Widget buildGettingStartedGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.getting_started.initial_setup".tr()),
        _buildParagraph(
            "user_guide.getting_started.setup_steps.permissions".tr()),
        _buildNumberedStep(
            1, "", "user_guide.getting_started.setup_steps.permissions".tr()),
        _buildNumberedStep(
            2, "", "user_guide.getting_started.setup_steps.language".tr()),
        _buildNumberedStep(
            3, "", "user_guide.getting_started.setup_steps.theme".tr()),
        _buildSubsectionHeader("user_guide.getting_started.home_screen".tr()),
        _buildParagraph("user_guide.getting_started.home_screen_desc".tr()),
        _buildFeatureExplanation(
            "user_guide.getting_started.features.recent_docs".tr(),
            "user_guide.getting_started.features.recent_docs".tr()),
        _buildFeatureExplanation(
            "user_guide.getting_started.features.scan_button".tr(),
            "user_guide.getting_started.features.scan_button".tr()),
        _buildFeatureExplanation(
            "user_guide.getting_started.features.folders".tr(),
            "user_guide.getting_started.features.folders".tr()),
        _buildFeatureExplanation(
            "user_guide.getting_started.features.search".tr(),
            "user_guide.getting_started.features.search".tr()),
        _buildTipBox("user_guide.getting_started.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildDocumentScanningGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader(
            "user_guide.document_scanning.starting_scan".tr()),
        _buildParagraph(
            "user_guide.document_scanning.scan_methods.home_button".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.scan_methods.home_button".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.scan_methods.plus_button".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.scan_methods.folder_scan".tr()),
        _buildSubsectionHeader(
            "user_guide.document_scanning.scanning_modes".tr()),
        _buildFeatureExplanation(
            "Auto Mode", "user_guide.document_scanning.modes.auto".tr()),
        _buildFeatureExplanation(
            "Manual Mode", "user_guide.document_scanning.modes.manual".tr()),
        _buildFeatureExplanation(
            "Batch Mode", "user_guide.document_scanning.modes.batch".tr()),
        _buildSubsectionHeader(
            "user_guide.document_scanning.scan_settings".tr()),
        _buildParagraph("user_guide.document_scanning.settings_desc".tr()),
        _buildFeatureExplanation("Color Mode",
            "user_guide.document_scanning.settings.color_mode".tr()),
        _buildFeatureExplanation("Document Type",
            "user_guide.document_scanning.settings.document_type".tr()),
        _buildFeatureExplanation("Edge Detection",
            "user_guide.document_scanning.settings.edge_detection".tr()),
        _buildFeatureExplanation(
            "OCR", "user_guide.document_scanning.settings.ocr".tr()),
        _buildFeatureExplanation(
            "Quality", "user_guide.document_scanning.settings.quality".tr()),
        _buildTipBox("user_guide.document_scanning.tip".tr()),
        _buildSubsectionHeader("user_guide.document_scanning.reviewing".tr()),
        _buildParagraph(
            "user_guide.document_scanning.reviewing_options.crop".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.crop".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.rotate".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.filters".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.retake".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.add_pages".tr()),
        _buildBulletPoint(
            "user_guide.document_scanning.reviewing_options.rearrange".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildDocumentManagementGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.document_management.library".tr()),
        _buildParagraph("user_guide.document_management.library_desc".tr()),
        _buildBulletPoint(
            "user_guide.document_management.library_features.view".tr()),
        _buildBulletPoint(
            "user_guide.document_management.library_features.sort".tr()),
        _buildBulletPoint(
            "user_guide.document_management.library_features.filter".tr()),
        _buildBulletPoint(
            "user_guide.document_management.library_features.search".tr()),
        _buildSubsectionHeader("user_guide.document_management.actions".tr()),
        _buildParagraph("user_guide.document_management.actions_desc".tr()),
        _buildFeatureExplanation(
            "View", "user_guide.document_management.doc_actions.view".tr()),
        _buildFeatureExplanation(
            "Rename", "user_guide.document_management.doc_actions.rename".tr()),
        _buildFeatureExplanation(
            "Edit", "user_guide.document_management.doc_actions.edit".tr()),
        _buildFeatureExplanation(
            "Share", "user_guide.document_management.doc_actions.share".tr()),
        _buildFeatureExplanation(
            "Move", "user_guide.document_management.doc_actions.move".tr()),
        _buildFeatureExplanation("Add to Favorites",
            "user_guide.document_management.doc_actions.favorite".tr()),
        _buildFeatureExplanation(
            "Delete", "user_guide.document_management.doc_actions.delete".tr()),
        _buildSubsectionHeader("user_guide.document_management.recents".tr()),
        _buildParagraph("user_guide.document_management.recents_desc".tr()),
        _buildTipBox("user_guide.document_management.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildOrganizationGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.organization.creating_folders".tr()),
        _buildParagraph("user_guide.organization.creating_steps.step1".tr()),
        _buildNumberedStep(
            1, "", "user_guide.organization.creating_steps.step1".tr()),
        _buildNumberedStep(
            2, "", "user_guide.organization.creating_steps.step2".tr()),
        _buildNumberedStep(
            3, "", "user_guide.organization.creating_steps.step3".tr()),
        _buildNumberedStep(
            4, "", "user_guide.organization.creating_steps.step4".tr()),
        _buildSubsectionHeader("user_guide.organization.subfolders".tr()),
        _buildParagraph("user_guide.organization.subfolders_desc".tr()),
        _buildBulletPoint(
            "user_guide.organization.subfolder_features.create".tr()),
        _buildBulletPoint(
            "user_guide.organization.subfolder_features.content".tr()),
        _buildBulletPoint(
            "user_guide.organization.subfolder_features.navigate".tr()),
        _buildSubsectionHeader("user_guide.organization.moving".tr()),
        _buildParagraph("user_guide.organization.moving_steps.step1".tr()),
        _buildNumberedStep(
            1, "", "user_guide.organization.moving_steps.step1".tr()),
        _buildNumberedStep(
            2, "", "user_guide.organization.moving_steps.step2".tr()),
        _buildNumberedStep(
            3, "", "user_guide.organization.moving_steps.step3".tr()),
        _buildNumberedStep(
            4, "", "user_guide.organization.moving_steps.step4".tr()),
        _buildSubsectionHeader("user_guide.organization.managing_folders".tr()),
        _buildParagraph("user_guide.organization.managing_desc".tr()),
        _buildFeatureExplanation(
            "Rename", "user_guide.organization.folder_actions.rename".tr()),
        _buildFeatureExplanation(
            "Delete", "user_guide.organization.folder_actions.delete".tr()),
        _buildFeatureExplanation(
            "Move", "user_guide.organization.folder_actions.move".tr()),
        _buildTipBox("user_guide.organization.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildEditingGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.editing.enhancement".tr()),
        _buildParagraph("user_guide.editing.enhancement_desc".tr()),
        _buildFeatureExplanation(
            "Auto Enhance", "user_guide.editing.enhancement_tools.auto".tr()),
        _buildFeatureExplanation("Brightness and Contrast",
            "user_guide.editing.enhancement_tools.brightness".tr()),
        _buildFeatureExplanation("Color Correction",
            "user_guide.editing.enhancement_tools.color".tr()),
        _buildFeatureExplanation("Noise Reduction",
            "user_guide.editing.enhancement_tools.noise".tr()),
        _buildSubsectionHeader("user_guide.editing.editing".tr()),
        _buildParagraph("user_guide.editing.editing_desc".tr()),
        _buildFeatureExplanation(
            "Crop & Rotate", "user_guide.editing.editing_tools.crop".tr()),
        _buildFeatureExplanation("Text Recognition (OCR)",
            "user_guide.editing.editing_tools.ocr".tr()),
        _buildFeatureExplanation(
            "Text Editing", "user_guide.editing.editing_tools.text".tr()),
        _buildFeatureExplanation("Highlight & Annotate",
            "user_guide.editing.editing_tools.annotate".tr()),
        _buildSubsectionHeader("user_guide.editing.page_management".tr()),
        _buildParagraph("user_guide.editing.page_desc".tr()),
        _buildBulletPoint("user_guide.editing.page_actions.add".tr()),
        _buildBulletPoint("user_guide.editing.page_actions.remove".tr()),
        _buildBulletPoint("user_guide.editing.page_actions.rearrange".tr()),
        _buildBulletPoint("user_guide.editing.page_actions.extract".tr()),
        _buildTipBox("user_guide.editing.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildPdfToolsGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.pdf_tools.creating".tr()),
        _buildParagraph("user_guide.pdf_tools.creating_desc".tr()),
        _buildBulletPoint("user_guide.pdf_tools.creating_methods.scan".tr()),
        _buildBulletPoint("user_guide.pdf_tools.creating_methods.combine".tr()),
        _buildBulletPoint("user_guide.pdf_tools.creating_methods.images".tr()),
        _buildBulletPoint("user_guide.pdf_tools.creating_methods.import".tr()),
        _buildSubsectionHeader("user_guide.pdf_tools.compression".tr()),
        _buildParagraph("user_guide.pdf_tools.compression_desc".tr()),
        _buildFeatureExplanation("Low Compression",
            "user_guide.pdf_tools.compression_levels.low".tr()),
        _buildFeatureExplanation("Medium Compression",
            "user_guide.pdf_tools.compression_levels.medium".tr()),
        _buildFeatureExplanation("High Compression",
            "user_guide.pdf_tools.compression_levels.high".tr()),
        _buildSubsectionHeader("user_guide.pdf_tools.operations".tr()),
        _buildParagraph("user_guide.pdf_tools.operations_desc".tr()),
        _buildFeatureExplanation(
            "Merge PDFs", "user_guide.pdf_tools.pdf_operations.merge".tr()),
        _buildFeatureExplanation(
            "Split PDF", "user_guide.pdf_tools.pdf_operations.split".tr()),
        _buildFeatureExplanation("Extract Pages",
            "user_guide.pdf_tools.pdf_operations.extract".tr()),
        _buildFeatureExplanation("Rearrange Pages",
            "user_guide.pdf_tools.pdf_operations.rearrange".tr()),
        _buildFeatureExplanation(
            "Rotate Pages", "user_guide.pdf_tools.pdf_operations.rotate".tr()),
        _buildSubsectionHeader("user_guide.pdf_tools.conversion".tr()),
        _buildParagraph("user_guide.pdf_tools.conversion_desc".tr()),
        _buildBulletPoint(
            "user_guide.pdf_tools.conversion_options.images".tr()),
        _buildBulletPoint("user_guide.pdf_tools.conversion_options.text".tr()),
        _buildBulletPoint(
            "user_guide.pdf_tools.conversion_options.formats".tr()),
        _buildTipBox("user_guide.pdf_tools.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildSecurityGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.security.app_security".tr()),
        _buildParagraph("user_guide.security.app_security_desc".tr()),
        _buildFeatureExplanation("Biometric Authentication",
            "user_guide.security.app_security_features.biometric".tr()),
        _buildFeatureExplanation("PIN Protection",
            "user_guide.security.app_security_features.pin".tr()),
        _buildFeatureExplanation("Auto-Lock",
            "user_guide.security.app_security_features.auto_lock".tr()),
        _buildSubsectionHeader("user_guide.security.encryption".tr()),
        _buildParagraph("user_guide.security.encryption_desc".tr()),
        _buildFeatureExplanation("Password Protection",
            "user_guide.security.encryption_features.password".tr()),
        _buildFeatureExplanation("Change Password",
            "user_guide.security.encryption_features.change".tr()),
        _buildFeatureExplanation("Remove Protection",
            "user_guide.security.encryption_features.remove".tr()),
        _buildSubsectionHeader("user_guide.security.private_folder".tr()),
        _buildParagraph("user_guide.security.private_folder_desc".tr()),
        _buildBulletPoint(
            "user_guide.security.private_folder_features.auth".tr()),
        _buildBulletPoint(
            "user_guide.security.private_folder_features.hidden".tr()),
        _buildBulletPoint(
            "user_guide.security.private_folder_features.biometric".tr()),
        _buildSubsectionHeader("user_guide.security.best_practices".tr()),
        _buildParagraph("user_guide.security.practices_desc".tr()),
        _buildBulletPoint(
            "user_guide.security.security_practices.strong_passwords".tr()),
        _buildBulletPoint(
            "user_guide.security.security_practices.biometric".tr()),
        _buildBulletPoint("user_guide.security.security_practices.backup".tr()),
        _buildBulletPoint(
            "user_guide.security.security_practices.sharing".tr()),
        _buildTipBox("user_guide.security.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildImportExportGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.import_export.importing".tr()),
        _buildParagraph("user_guide.import_export.importing_desc".tr()),
        _buildFeatureExplanation("Import from Gallery",
            "user_guide.import_export.import_methods.gallery".tr()),
        _buildFeatureExplanation("Import PDF Files",
            "user_guide.import_export.import_methods.pdf".tr()),
        _buildFeatureExplanation("Import from Cloud Storage",
            "user_guide.import_export.import_methods.cloud".tr()),
        _buildFeatureExplanation("Import from Other Apps",
            "user_guide.import_export.import_methods.apps".tr()),
        _buildSubsectionHeader("user_guide.import_export.exporting".tr()),
        _buildParagraph("user_guide.import_export.exporting_desc".tr()),
        _buildFeatureExplanation(
            "Share as PDF", "user_guide.import_export.export_methods.pdf".tr()),
        _buildFeatureExplanation("Share as Images",
            "user_guide.import_export.export_methods.images".tr()),
        _buildFeatureExplanation("Multiple Sharing Options",
            "user_guide.import_export.export_methods.options".tr()),
        _buildFeatureExplanation("Batch Sharing",
            "user_guide.import_export.export_methods.batch".tr()),
        _buildSubsectionHeader("user_guide.import_export.backup".tr()),
        _buildParagraph("user_guide.import_export.backup_desc".tr()),
        _buildFeatureExplanation("Local Backup",
            "user_guide.import_export.backup_methods.local".tr()),
        _buildFeatureExplanation("Cloud Backup",
            "user_guide.import_export.backup_methods.cloud".tr()),
        _buildFeatureExplanation("Automatic Backup",
            "user_guide.import_export.backup_methods.auto".tr()),
        _buildFeatureExplanation("Restore from Backup",
            "user_guide.import_export.backup_methods.restore".tr()),
        _buildTipBox("user_guide.import_export.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildSettingsGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader(
            "user_guide.troubleshooting.scanning_issues".tr()),
        _buildParagraph(
            "user_guide.troubleshooting.scanning_solutions_desc".tr()),
        _buildFeatureExplanation("Poor Image Quality",
            "user_guide.troubleshooting.scanning_solutions.quality".tr()),
        _buildFeatureExplanation("Edge Detection Problems",
            "user_guide.troubleshooting.scanning_solutions.edges".tr()),
        _buildFeatureExplanation("OCR Not Working Well",
            "user_guide.troubleshooting.scanning_solutions.ocr".tr()),
        _buildFeatureExplanation("Camera Not Working",
            "user_guide.troubleshooting.scanning_solutions.camera".tr()),
        _buildSubsectionHeader(
            "user_guide.troubleshooting.management_issues".tr()),
        _buildParagraph(
            "user_guide.troubleshooting.management_solutions_desc".tr()),
        _buildFeatureExplanation("Missing Documents",
            "user_guide.troubleshooting.management_solutions.missing".tr()),
        _buildFeatureExplanation("Can't Open Document",
            "user_guide.troubleshooting.management_solutions.open".tr()),
        _buildFeatureExplanation("App Performance Slow",
            "user_guide.troubleshooting.management_solutions.performance".tr()),
        _buildFeatureExplanation("Storage Space Issues",
            "user_guide.troubleshooting.management_solutions.storage".tr()),
        _buildSubsectionHeader("user_guide.troubleshooting.support".tr()),
        _buildParagraph("user_guide.troubleshooting.support_desc".tr()),
        _buildFeatureExplanation("In-App Help",
            "user_guide.troubleshooting.support_options.help".tr()),
        _buildFeatureExplanation("Email Support",
            "user_guide.troubleshooting.support_options.email".tr()),
        _buildFeatureExplanation("Knowledge Base",
            "user_guide.troubleshooting.support_options.knowledge".tr()),
        _buildFeatureExplanation("Feedback & Feature Requests",
            "user_guide.troubleshooting.support_options.feedback".tr()),
        _buildTipBox("user_guide.troubleshooting.tip".tr()),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildTroubleshootingGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        _buildSubsectionHeader("user_guide.settings.appearance".tr()),
        _buildParagraph("user_guide.settings.appearance_desc".tr()),
        _buildFeatureExplanation(
            "Theme", "user_guide.settings.appearance_settings.theme".tr()),
        _buildFeatureExplanation("Language",
            "user_guide.settings.appearance_settings.language".tr()),
        _buildFeatureExplanation("Home Screen Layout",
            "user_guide.settings.appearance_settings.layout".tr()),
        _buildSubsectionHeader("user_guide.settings.scanning".tr()),
        _buildParagraph("user_guide.settings.scanning_desc".tr()),
        _buildFeatureExplanation("Default Scan Mode",
            "user_guide.settings.scanning_settings.mode".tr()),
        _buildFeatureExplanation("Default Color Mode",
            "user_guide.settings.scanning_settings.color".tr()),
        _buildFeatureExplanation("Auto-Enhancement",
            "user_guide.settings.scanning_settings.enhancement".tr()),
        _buildFeatureExplanation("Default Quality",
            "user_guide.settings.scanning_settings.quality".tr()),
        _buildSubsectionHeader("user_guide.settings.document".tr()),
        _buildParagraph("user_guide.settings.document_desc".tr()),
        _buildFeatureExplanation("Default Save Location",
            "user_guide.settings.document_settings.location".tr()),
        _buildFeatureExplanation("PDF Quality",
            "user_guide.settings.document_settings.quality".tr()),
        _buildFeatureExplanation(
            "OCR Settings", "user_guide.settings.document_settings.ocr".tr()),
        _buildSubsectionHeader("user_guide.settings.security".tr()),
        _buildParagraph("user_guide.settings.security_desc".tr()),
        _buildFeatureExplanation("Biometric Authentication",
            "user_guide.settings.security_settings.biometric".tr()),
        _buildFeatureExplanation(
            "PIN Setup", "user_guide.settings.security_settings.pin".tr()),
        _buildFeatureExplanation("Auto-Lock Timer",
            "user_guide.settings.security_settings.auto_lock".tr()),
        _buildSubsectionHeader("user_guide.settings.backup".tr()),
        _buildParagraph("user_guide.settings.backup_desc".tr()),
        _buildFeatureExplanation(
            "Auto Backup", "user_guide.settings.backup_settings.auto".tr()),
        _buildFeatureExplanation("Backup Location",
            "user_guide.settings.backup_settings.location".tr()),
        _buildFeatureExplanation("Backup Content",
            "user_guide.settings.backup_settings.content".tr()),
        _buildTipBox("user_guide.settings.tip".tr()),
        SizedBox(height: 40.h),
      ],
    );
  }

  // Helper Widgets

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: AutoSizeText(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildSubsectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: AutoSizeText(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildParagraph(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AutoSizeText(
        content,
        style: GoogleFonts.slabo27px(
          fontSize: 14.sp,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(String imageLabel) {
    return Container(
      height: 180.h,
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.r),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 48.r,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 8.h),
          AutoSizeText(
            imageLabel,
            style: GoogleFonts.slabo27px(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AutoSizeText(
              content,
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedStep(int number, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22.w,
            height: 22.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            alignment: Alignment.center,
            child: AutoSizeText(
              number.toString(),
              style: GoogleFonts.slabo27px(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  AutoSizeText(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                AutoSizeText(
                  content,
                  style: GoogleFonts.slabo27px(
                    fontSize: 14.sp,
                    height: 1.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureExplanation(String feature, String explanation) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: AutoSizeText(
              feature,
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AutoSizeText(
              explanation,
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                height: 1.4,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBox(String tip) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20.r,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: AutoSizeText(
              tip,
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
