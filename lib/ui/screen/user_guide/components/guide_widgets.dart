import 'package:flutter/material.dart';
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
        buildSectionHeader("Getting Started with ScanPro"),
        buildImagePlaceholder("Welcome Screen"),
        buildParagraph(
            "Welcome to ScanPro, your complete document scanning and management solution. "
            "This guide will help you get the most out of your app."),
        buildSubsectionHeader("Initial Setup"),
        buildParagraph(
            "When you first open ScanPro, you'll be guided through a brief setup process:"),
        buildNumberedStep(1, "Permission Setup",
            "Grant camera and storage permissions when prompted to enable scanning and saving documents."),
        buildNumberedStep(2, "Language Selection",
            "Choose your preferred language from the available options."),
        buildNumberedStep(3, "Theme Selection",
            "Pick light or dark theme, which you can always change later in settings."),
        buildSubsectionHeader("Home Screen Overview"),
        buildParagraph(
            "The home screen is your command center for all ScanPro features:"),
        buildFeatureExplanation("Recent Documents",
            "Quickly access your most recently scanned or viewed documents."),
        buildFeatureExplanation("Scan Button",
            "The large circular button at the bottom center starts a new scan."),
        buildFeatureExplanation("Folders",
            "Organize your documents in custom folders for easy access."),
        buildFeatureExplanation("Search",
            "Find any document by searching for names, content (if OCR was used), or tags."),
        buildTipBox(
            "You can customize your home screen layout in Settings → Appearance → Home Layout."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildDocumentScanningGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Document Scanning"),
        buildImagePlaceholder("Scanning Interface"),
        buildParagraph(
            "Scanning documents is the core function of ScanPro. The app provides multiple ways to capture high-quality document images."),
        buildSubsectionHeader("Starting a Scan"),
        buildParagraph("You can start a new scan in several ways:"),
        buildBulletPoint("Tap the scan button on the home screen"),
        buildBulletPoint("Tap the + button and select 'Scan Document'"),
        buildBulletPoint(
            "From a folder, tap the scan icon to add directly to that folder"),
        buildSubsectionHeader("Scanning Modes"),
        buildFeatureExplanation("Auto Mode",
            "The app automatically detects document edges and captures the image when steady."),
        buildFeatureExplanation("Manual Mode",
            "You control when to capture the image with the capture button."),
        buildFeatureExplanation("Batch Mode",
            "Continuously scan multiple pages for multi-page documents."),
        buildSubsectionHeader("Scan Settings"),
        buildParagraph("Before scanning, you can adjust various settings:"),
        buildFeatureExplanation("Color Mode",
            "Choose between Color, Grayscale, or Black & White scanning."),
        buildFeatureExplanation("Document Type",
            "Select Document, Receipt, ID Card, or Photo for optimized processing."),
        buildFeatureExplanation(
            "Edge Detection", "Enable or disable automatic edge detection."),
        buildFeatureExplanation("OCR (Text Recognition)",
            "Enable to make text in your documents searchable."),
        buildFeatureExplanation("Quality",
            "Adjust the image quality (higher quality means larger file size)."),
        buildTipBox(
            "For best results, scan in a well-lit environment with the document placed on a contrasting background."),
        buildSubsectionHeader("Reviewing and Editing Scans"),
        buildParagraph(
            "After scanning, you'll be taken to the review screen where you can:"),
        buildBulletPoint("Adjust cropping boundaries"),
        buildBulletPoint("Rotate or flip the image"),
        buildBulletPoint("Apply filters and enhancements"),
        buildBulletPoint("Retake a scan if needed"),
        buildBulletPoint("Add more pages (for multi-page documents)"),
        buildBulletPoint("Rearrange pages by dragging"),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildDocumentManagementGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Document Management"),
        buildImagePlaceholder("Document Library"),
        buildParagraph(
            "ScanPro makes it easy to manage your growing collection of documents."),
        buildSubsectionHeader("Document Library"),
        buildParagraph(
            "Your Document Library contains all scanned and imported documents. Here you can:"),
        buildBulletPoint("View all documents in a list or grid view"),
        buildBulletPoint("Sort documents by name, date, size, or type"),
        buildBulletPoint("Filter documents by type (PDF, image, etc.)"),
        buildBulletPoint("Search for specific documents"),
        buildSubsectionHeader("Document Actions"),
        buildParagraph("For each document, you can:"),
        buildFeatureExplanation(
            "View", "Open the document to read its contents."),
        buildFeatureExplanation("Rename", "Change the document's name."),
        buildFeatureExplanation(
            "Edit", "Modify the document's contents or appearance."),
        buildFeatureExplanation(
            "Share", "Send the document via email, messaging apps, etc."),
        buildFeatureExplanation(
            "Move", "Relocate the document to another folder."),
        buildFeatureExplanation(
            "Add to Favorites", "Mark important documents for quick access."),
        buildFeatureExplanation(
            "Delete", "Remove the document from your library."),
        buildSubsectionHeader("Recent and Favorites"),
        buildParagraph(
            "Access your most recent and favorite documents quickly from the home screen."),
        buildTipBox(
            "You can perform batch operations by long-pressing a document to enter selection mode, then selecting multiple documents."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildOrganizationGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Organization with Folders"),
        buildImagePlaceholder("Folder Structure"),
        buildParagraph(
            "Keep your documents organized using folders and subfolders in ScanPro."),
        buildSubsectionHeader("Creating Folders"),
        buildParagraph("To create a new folder:"),
        buildNumberedStep(1, "", "Tap the + button and select 'Create Folder'"),
        buildNumberedStep(2, "", "Enter a name for your folder"),
        buildNumberedStep(3, "", "Select a color and icon (optional)"),
        buildNumberedStep(4, "", "Tap 'Create' to save your new folder"),
        buildSubsectionHeader("Subfolder Structure"),
        buildParagraph(
            "ScanPro supports nested folders for hierarchical organization:"),
        buildBulletPoint(
            "Open a folder and tap + to create a subfolder within it"),
        buildBulletPoint(
            "Subfolders can contain both documents and additional subfolders"),
        buildBulletPoint(
            "Navigate up and down the folder structure using the breadcrumb navigation"),
        buildSubsectionHeader("Moving Documents"),
        buildParagraph("To move documents between folders:"),
        buildNumberedStep(1, "", "Long-press a document to select it"),
        buildNumberedStep(2, "", "Select multiple documents if needed"),
        buildNumberedStep(3, "", "Tap the 'Move' option"),
        buildNumberedStep(4, "", "Select the destination folder"),
        buildSubsectionHeader("Managing Folders"),
        buildParagraph("You can manage your folders by:"),
        buildFeatureExplanation(
            "Rename", "Change a folder's name, color, or icon."),
        buildFeatureExplanation(
            "Delete", "Remove a folder and optionally its contents."),
        buildFeatureExplanation("Move",
            "Relocate a folder to become a subfolder of another folder."),
        buildTipBox(
            "Create folders based on document categories (e.g., Receipts, ID Documents, Work) or time periods (e.g., 2023, 2024)."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildEditingGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Editing & Enhancing Documents"),
        buildImagePlaceholder("Editing Interface"),
        buildParagraph(
            "ScanPro provides powerful tools to improve the quality and usefulness of your scanned documents."),
        buildSubsectionHeader("Image Enhancement"),
        buildParagraph("Improve document readability with:"),
        buildFeatureExplanation(
            "Auto Enhance", "One-tap improvement for contrast and clarity."),
        buildFeatureExplanation("Brightness and Contrast",
            "Manual adjustment sliders for precise control."),
        buildFeatureExplanation("Color Correction",
            "Fix color issues or convert to grayscale/black & white."),
        buildFeatureExplanation("Noise Reduction",
            "Remove specks and artifacts from scanned images."),
        buildSubsectionHeader("Document Editing"),
        buildParagraph("Edit document content with:"),
        buildFeatureExplanation(
            "Crop & Rotate", "Adjust document boundaries or orientation."),
        buildFeatureExplanation("Text Recognition (OCR)",
            "Convert image text to editable digital text."),
        buildFeatureExplanation(
            "Text Editing", "Modify recognized text directly in the app."),
        buildFeatureExplanation("Highlight & Annotate",
            "Add notes, highlights, or signatures to documents."),
        buildSubsectionHeader("Page Management"),
        buildParagraph("For multi-page documents, you can:"),
        buildBulletPoint("Add new pages to existing documents"),
        buildBulletPoint("Remove specific pages"),
        buildBulletPoint("Rearrange page order by dragging"),
        buildBulletPoint("Extract pages to create new documents"),
        buildTipBox(
            "For text-heavy documents, enable OCR during scanning or apply it later to make text searchable and editable."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildPdfToolsGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("PDF Tools"),
        buildImagePlaceholder("PDF Operations"),
        buildParagraph(
            "ScanPro offers comprehensive PDF management capabilities."),
        buildSubsectionHeader("Creating PDFs"),
        buildParagraph("Create PDFs from various sources:"),
        buildBulletPoint("Convert scanned documents directly to PDF"),
        buildBulletPoint("Combine multiple scans into a single PDF"),
        buildBulletPoint("Convert images from your gallery to PDF"),
        buildBulletPoint("Import existing PDFs for editing"),
        buildSubsectionHeader("PDF Compression"),
        buildParagraph("Reduce file size while maintaining quality:"),
        buildFeatureExplanation("Low Compression",
            "Minimal compression, highest quality (90% of original size)."),
        buildFeatureExplanation("Medium Compression",
            "Balanced compression (50-60% of original size)."),
        buildFeatureExplanation("High Compression",
            "Maximum file size reduction (30-40% of original size)."),
        buildSubsectionHeader("PDF Operations"),
        buildParagraph("Manipulate PDF files with these tools:"),
        buildFeatureExplanation(
            "Merge PDFs", "Combine multiple PDF files into one document."),
        buildFeatureExplanation(
            "Split PDF", "Divide a PDF into multiple smaller documents."),
        buildFeatureExplanation(
            "Extract Pages", "Pull specific pages from a larger PDF."),
        buildFeatureExplanation(
            "Rearrange Pages", "Change the order of pages within a PDF."),
        buildFeatureExplanation(
            "Rotate Pages", "Correct the orientation of individual pages."),
        buildSubsectionHeader("PDF Conversion"),
        buildParagraph("Convert PDFs to other formats:"),
        buildBulletPoint("PDF to Images (JPG, PNG)"),
        buildBulletPoint("PDF to Text (with OCR)"),
        buildBulletPoint("PDF to other document formats"),
        buildTipBox(
            "Use PDF compression when sharing large documents via email or messaging apps to avoid size limitations."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildSecurityGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Document Security"),
        buildImagePlaceholder("Security Features"),
        buildParagraph(
            "Protect your sensitive documents with ScanPro's security features."),
        buildSubsectionHeader("App Security"),
        buildParagraph("Secure access to the entire app:"),
        buildFeatureExplanation("Biometric Authentication",
            "Use fingerprint or face recognition to open the app."),
        buildFeatureExplanation(
            "PIN Protection", "Set a numeric PIN code for app access."),
        buildFeatureExplanation("Auto-Lock",
            "Automatically lock the app after a period of inactivity."),
        buildSubsectionHeader("Document Encryption"),
        buildParagraph(
            "Add an extra layer of protection to individual documents:"),
        buildFeatureExplanation(
            "Password Protection", "Encrypt PDFs with password protection."),
        buildFeatureExplanation("Change Password",
            "Update passwords for already protected documents."),
        buildFeatureExplanation("Remove Protection",
            "Remove password encryption when no longer needed."),
        buildSubsectionHeader("Private Folder"),
        buildParagraph(
            "The Private Folder feature offers additional security for your most sensitive documents:"),
        buildBulletPoint(
            "Documents in Private Folders require authentication to view"),
        buildBulletPoint(
            "Private Folders are hidden from the main document list"),
        buildBulletPoint(
            "Additional biometric verification before accessing Private Folders"),
        buildSubsectionHeader("Security Best Practices"),
        buildParagraph("Recommendations for keeping your documents secure:"),
        buildBulletPoint(
            "Use strong, unique passwords for document protection"),
        buildBulletPoint(
            "Enable biometric authentication for convenient security"),
        buildBulletPoint("Regularly back up important documents"),
        buildBulletPoint(
            "Be cautious when sharing documents containing sensitive information"),
        buildTipBox(
            "Remember your document passwords! If you forget a PDF password, you won't be able to access the document contents."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildImportExportGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Importing & Exporting"),
        buildImagePlaceholder("Import/Export Options"),
        buildParagraph(
            "ScanPro provides various options for bringing documents in and sharing them out."),
        buildSubsectionHeader("Importing Documents"),
        buildParagraph("Add existing documents to your library:"),
        buildFeatureExplanation(
            "Import from Gallery", "Add photos from your device gallery."),
        buildFeatureExplanation(
            "Import PDF Files", "Add existing PDFs from your device storage."),
        buildFeatureExplanation("Import from Cloud Storage",
            "Import documents from Google Drive, Dropbox, etc."),
        buildFeatureExplanation("Import from Other Apps",
            "Receive documents shared from other applications."),
        buildSubsectionHeader("Exporting & Sharing"),
        buildParagraph("Share your documents in various ways:"),
        buildFeatureExplanation("Share as PDF", "Send documents as PDF files."),
        buildFeatureExplanation(
            "Share as Images", "Share individual pages as image files."),
        buildFeatureExplanation("Multiple Sharing Options",
            "Email, messaging apps, cloud storage, and more."),
        buildFeatureExplanation(
            "Batch Sharing", "Share multiple documents at once."),
        buildSubsectionHeader("Backup & Restore"),
        buildParagraph("Safeguard your document collection:"),
        buildFeatureExplanation(
            "Local Backup", "Save a backup to your device storage."),
        buildFeatureExplanation(
            "Cloud Backup", "Back up to Google Drive or other cloud services."),
        buildFeatureExplanation(
            "Automatic Backup", "Schedule regular backups of your library."),
        buildFeatureExplanation("Restore from Backup",
            "Recover your documents from a previous backup."),
        buildTipBox(
            "Regular backups are essential for preventing data loss. Set up automatic backups in Settings → Backup & Restore."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildSettingsGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Settings & Preferences"),
        buildImagePlaceholder("Settings Screen"),
        buildParagraph("Customize ScanPro to work just the way you want it."),
        buildSubsectionHeader("Appearance Settings"),
        buildParagraph("Customize the app's look and feel:"),
        buildFeatureExplanation(
            "Theme", "Choose between Light, Dark, or System default theme."),
        buildFeatureExplanation("Language",
            "Select your preferred language from multiple options."),
        buildFeatureExplanation("Home Screen Layout",
            "Customize which elements appear on your home screen."),
        buildSubsectionHeader("Scanning Preferences"),
        buildParagraph("Default settings for document scanning:"),
        buildFeatureExplanation("Default Scan Mode",
            "Set your preferred scanning mode (Auto, Manual, Batch)."),
        buildFeatureExplanation("Default Color Mode",
            "Choose the default color processing (Color, Grayscale, B&W)."),
        buildFeatureExplanation("Auto-Enhancement",
            "Enable automatic image enhancement for all scans."),
        buildFeatureExplanation(
            "Default Quality", "Set the quality level for document scanning."),
        buildSubsectionHeader("Document Settings"),
        buildParagraph("Configure document management options:"),
        buildFeatureExplanation("Default Save Location",
            "Set where new documents are saved by default."),
        buildFeatureExplanation(
            "PDF Quality", "Set the default quality for PDF creation."),
        buildFeatureExplanation(
            "OCR Settings", "Configure text recognition preferences."),
        buildSubsectionHeader("Security Settings"),
        buildParagraph("Configure app security:"),
        buildFeatureExplanation("Biometric Authentication",
            "Enable fingerprint/face recognition unlock."),
        buildFeatureExplanation(
            "PIN Setup", "Create or change your app access PIN."),
        buildFeatureExplanation("Auto-Lock Timer",
            "Set how quickly the app locks after inactivity."),
        buildSubsectionHeader("Backup Settings"),
        buildParagraph("Configure backup options:"),
        buildFeatureExplanation(
            "Auto Backup", "Enable and schedule automatic backups."),
        buildFeatureExplanation(
            "Backup Location", "Choose where backups are stored."),
        buildFeatureExplanation(
            "Backup Content", "Select what data is included in backups."),
        buildTipBox(
            "Take some time to explore the Settings menu and customize ScanPro to match your workflow and preferences."),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget buildTroubleshootingGuide() {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.all(16.r),
      children: [
        buildSectionHeader("Troubleshooting & Support"),
        buildImagePlaceholder("Support Options"),
        buildParagraph(
            "Solutions for common issues and how to get help when needed."),
        buildSubsectionHeader("Common Scanning Issues"),
        buildParagraph("Solutions for scanning problems:"),
        buildFeatureExplanation("Poor Image Quality",
            "Ensure good lighting, keep the camera steady, and try using Auto Enhancement."),
        buildFeatureExplanation("Edge Detection Problems",
            "Use a contrasting background, or switch to Manual mode and adjust crop manually."),
        buildFeatureExplanation("OCR Not Working Well",
            "Ensure the document is well-lit, clearly visible, and properly aligned."),
        buildFeatureExplanation("Camera Not Working",
            "Check camera permissions in your device settings."),
        buildSubsectionHeader("Document Management Issues"),
        buildParagraph("Solutions for library problems:"),
        buildFeatureExplanation("Missing Documents",
            "Check different folders, use the search function, or restore from backup."),
        buildFeatureExplanation("Can't Open Document",
            "For password-protected PDFs, ensure you have the correct password."),
        buildFeatureExplanation("App Performance Slow",
            "Try clearing the cache or restarting the app."),
        buildFeatureExplanation("Storage Space Issues",
            "Use the 'Clean Temporary Files' option in Settings, or compress large documents."),
        buildSubsectionHeader("Getting Support"),
        buildParagraph("Ways to get help with ScanPro:"),
        buildFeatureExplanation(
            "In-App Help", "This User Guide and FAQ sections."),
        buildFeatureExplanation(
            "Email Support", "Contact our support team at support@scanpro.cc."),
        buildFeatureExplanation(
            "Knowledge Base", "Visit our website for additional resources."),
        buildFeatureExplanation("Feedback & Feature Requests",
            "Share your ideas and suggestions with our team."),
        buildTipBox(
            "When contacting support about an issue, include details about your device, app version, and steps to reproduce the problem."),
        SizedBox(height: 40.h),
      ],
    );
  }

  // Helper Widgets

  Widget buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Text(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 22.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget buildSubsectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Text(
        title,
        style: GoogleFonts.slabo27px(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget buildParagraph(String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        content,
        style: GoogleFonts.slabo27px(
          fontSize: 14.sp,
          height: 1.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget buildImagePlaceholder(String imageLabel) {
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
          Text(
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

  Widget buildBulletPoint(String content) {
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
            child: Text(
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

  Widget buildNumberedStep(int number, String title, String content) {
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
            child: Text(
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
                  Text(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                Text(
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

  Widget buildFeatureExplanation(String feature, String explanation) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, left: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80.w,
            child: Text(
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
            child: Text(
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

  Widget buildTipBox(String tip) {
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
            child: Text(
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
