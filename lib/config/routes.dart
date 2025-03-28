import 'package:scanpro/config/app_transition.dart';
import 'package:scanpro/ui/screen/all_documents.dart';
import 'package:scanpro/ui/screen/barcode/barcode_generator_screen.dart';
import 'package:scanpro/ui/screen/barcode/barcode_history_screen.dart';
import 'package:scanpro/ui/screen/barcode/barcode_scanner_screen.dart';
import 'package:scanpro/ui/screen/compression/compression_screen.dart';
import 'package:scanpro/ui/screen/contact_screen.dart';
import 'package:scanpro/ui/screen/conversion/conversion_screen.dart';
import 'package:scanpro/ui/screen/faq_screen.dart';
import 'package:scanpro/ui/screen/languages/languages_screen.dart';
import 'package:scanpro/ui/screen/merger/pdf_merge_screen.dart';
import 'package:scanpro/ui/screen/ocr/ocr_extraction.dart';
import 'package:scanpro/ui/screen/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/ui/screen/user_guide/user_guide_screen.dart';
import '../models/document.dart';
import '../models/folder.dart';
import '../ui/screen/edit/edit_screen.dart';
import '../ui/screen/folder/folder_screen.dart';
import '../ui/screen/home/home_screen.dart';
import '../ui/screen/view_screen.dart';
import '../ui/screen/main_screen.dart';

class AppRoutes {
  // Route path constants
  static const String home = '/';
  static const String edit = '/edit';
  static const String convert = '/convert';
  static const String view = '/view';
  static const String settings = '/settings';
  static const String languages = '/languages';
  static const String folders = '/folders';
  static const String pdfMerger = '/pdf_merger';
  static const String allDocuments = '/all_documents';
  static const String compression = '/compression';
  static const String backupSettings = '/backup-settings';
  static const String backupRestore = '/backup-restore';
  static const String scan = '/scan';
  static const String ocr = '/ocr';
  static const String barcodeScan = '/barcode/scan';
  static const String barcodeGenerate = '/barcode/generate';
  static const String barcodeHistory = '/barcode/history';
  static const String faq = '/faq';
  static const String contactSupport = '/contact-support';
  // GoRouter configuration
  static final router = GoRouter(
    initialLocation: home,
    routes: [
      // Main shell route with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        // Use a clean transition for shell route pages
        pageBuilder: (context, state, child) {
          return NoTransitionPage(
            key: state.pageKey,
            child: MainScreen(child: child),
          );
        },
        routes: [
          // Home route
          GoRoute(
            path: home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          // Folders route
          GoRoute(
            path: folders,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FolderScreen(),
            ),
          ),
          // Convert route
          GoRoute(
            path: convert,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversionScreen(),
            ),
          ),
          // Convert route
          GoRoute(
            path: pdfMerger,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PdfMergerScreen(),
            ),
          ),
          // Settings route
          GoRoute(
            path: settings,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: languages,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LanguagesScreen(),
            ),
          ),
          GoRoute(
            path: barcodeScan,
            builder: (context, state) => const BarcodeScannerScreen(),
          ),
          GoRoute(
            path: barcodeGenerate,
            builder: (context, state) => const BarcodeGeneratorScreen(),
          ),
          GoRoute(
            path: barcodeHistory,
            builder: (context, state) => const BarcodeHistoryScreen(),
          ),
          GoRoute(
            path: faq,
            builder: (context, state) => const FaqScreen(),
          ),
          GoRoute(
            path: contactSupport,
            builder: (context, state) => const ContactSupportScreen(),
          ),

          GoRoute(
            path: '/userguide',
            name: 'userGuide',
            builder: (context, state) => const UserGuideScreen(),
          ),
        
        ],
      ),

      // Edit document route - smooth slide transition
      GoRoute(
        path: edit,
        pageBuilder: (context, state) {
          final document = state.extra as Document?;
          return AppTransitions.buildSlideTransition(
            context: context,
            state: state,
            child: EditScreen(document: document),
          );
        },
      ),
      GoRoute(
        path: ocr,
        pageBuilder: (context, state) {
          final document = state.extra as Document?;
          return AppTransitions.buildSlideTransition(
            context: context,
            state: state,
            child: OcrExtractionScreen(document: document!),
          );
        },
      ),
      // View document route - hero transition for smooth document viewing
      GoRoute(
        path: view,
        pageBuilder: (context, state) {
          // Make document nullable and handle null case
          final document = state.extra as Document?;
          if (document == null) {
            // Return error screen when document is null
            return AppTransitions.buildPageTransition(
              context: context,
              state: state,
              child: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      AutoSizeText(
                        'Document not found or invalid',
                        style: GoogleFonts.slabo27px(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.adaptiveSp),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => navigateToHome(context),
                        child: const AutoSizeText('Go to Home'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Only create ViewScreen with a valid document
          return AppTransitions.buildHeroTransition(
            context: context,
            state: state,
            child: ViewScreen(document: document),
          );
        },
      ),

      // All documents route - fade + slide transition
      GoRoute(
        path: allDocuments,
        pageBuilder: (context, state) => AppTransitions.buildPageTransition(
          context: context,
          state: state,
          child: const AllDocumentsScreen(),
        ),
      ),

      // Folder route - slide transition
      GoRoute(
        path: '/folder/:folderId',
        name: 'specificFolder',
        pageBuilder: (context, state) {
          final folder = state.extra as Folder?;
          return AppTransitions.buildSlideTransition(
            context: context,
            state: state,
            child: FolderScreen(folder: folder),
          );
        },
      ),

      // Compression route - modal scale transition
      GoRoute(
        path: compression,
        pageBuilder: (context, state) {
          final document = state.extra as Document;
          return AppTransitions.buildModalTransition(
            context: context,
            state: state,
            child: CompressionScreen(document: document),
          );
        },
      ),
    ],
    // Custom error page with animation
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            AutoSizeText(
              'Route not found: ${state.error}',
              style: GoogleFonts.slabo27px(
                  fontWeight: FontWeight.w700, fontSize: 14.adaptiveSp),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => navigateToHome(context),
              child: const AutoSizeText('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );

  // Navigation helper methods
  static void navigateToHome(BuildContext context) {
    context.go(home);
  }

  static void navigateToCompression(BuildContext context, Document document) {
    context.push(compression, extra: document);
  }

  static void navigateToEdit(BuildContext context, {Document? document}) {
    context.push(edit, extra: document);
  }

  static void navigateToLanguages(BuildContext context) {
    context.push(languages);
  }

  static void navigateToFaq(BuildContext context) {
    context.push(faq);
  }

  static void navigateToUserGuide(BuildContext context) {
    context.pushNamed('userGuide');
  }

  static void navigateToView(BuildContext context, Document? document) {
    if (document == null) {
      // Show error or navigate to home if document is null
      navigateToHome(context);
      return;
    }
    context.push(view, extra: document);
  }

  static void navigateToFolder(BuildContext context, Folder folder) {
    // Push to the specific folder route and pass the folder object as extra
    context.pushNamed('specificFolder',
        pathParameters: {'folderId': folder.id}, extra: folder);
  }

  static void navigateToPdfMerger(BuildContext context) {
    context.push(pdfMerger);
  }

  static void navigateToAllDoc(BuildContext context) {
    context.push(allDocuments);
  }

  static void navigateToFolders(BuildContext context) {
    context.go(folders);
  }

  static void navigateToOcr(BuildContext context, Document document) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OcrExtractionScreen(document: document),
      ),
    );
  }

  static void navigateToSettings(BuildContext context) {
    context.go(settings);
  }

  static void navigateToContactSupport(BuildContext context) {
    context.push(contactSupport);
  }

  static void navigateToConvert(BuildContext context) {
    context.go(convert);
  }

  static void navigateToBarcodeScan(BuildContext context) {
    context.go(barcodeScan);
  }

  static void navigateToBarcodeGenerator(BuildContext context) {
    context.go(barcodeGenerate);
  }

  static void navigateToBarcodeHistory(BuildContext context) {
    context.go(barcodeHistory);
  }

  static void navigateToBackupSettings(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.backupSettings);
  }

  static void navigateToBackupRestore(BuildContext context) {
    GoRouter.of(context).push(AppRoutes.backupRestore);
  }
}
