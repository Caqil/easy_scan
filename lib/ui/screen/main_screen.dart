import 'dart:io';

import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/config/routes.dart';
import 'package:scanpro/services/scan_service.dart';
import 'package:scanpro/services/tracking_service.dart';
import 'package:scanpro/ui/widget/component/scan_initial_view.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;
  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  bool _isLoading = false;
  String? _advertisingIdentifier;
  bool _isTrackingAuthorized = false;
  // Updated to include 5 items with Scan in the middle
  final _iconList = <IconData>[
    Icons.home_rounded,
    Icons.folder_rounded,
    Icons.document_scanner_rounded, // Scan icon in the middle
    Icons.compare_arrows_rounded,
    Icons.settings_rounded,
  ];

  // Updated to include 5 labels with Scan in the middle
  final _labelList = <String>[
    'labels.home'.tr(),
    'labels.folders'.tr(),
    'labels.scan'.tr(),
    'labels.convert'.tr(),
    'labels.settings'.tr(),
  ];

  // Define list of routes that correspond to bottom nav items
  final List<String> _routes = [
    AppRoutes.home,
    AppRoutes.folders,
    '/scan', // Placeholder route for scan action
    AppRoutes.convert,
    AppRoutes.settings,
  ];

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid || Platform.isIOS) {
      _initializeTracking();
    }
  }

  Future<void> _initializeTracking() async {
    // Request tracking authorization
    final isAuthorized = await TrackingService.requestTracking();

    if (isAuthorized) {
      // If authorized, get the advertising identifier
      final idfa = await TrackingService.getAdvertisingIdentifier();

      setState(() {
        _isTrackingAuthorized = true;
        _advertisingIdentifier = idfa;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Close any open bottom sheets first
    Navigator.of(context).popUntil((route) => route.isFirst);

    // Handle the Scan button separately (middle item)
    if (index == 2) {
      // Scan button (middle position)
      _handleScanAction();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });

    // Navigate using routes for other items
    context.go(_routes[index]);
  }

  void _handleScanAction() {
    final scanService = ref.read(scanServiceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.5,
          child: ScanInitialView(
            onScanPressed: () {
              // Close the bottom sheet immediately using the bottom sheet's context
              Navigator.pop(bottomSheetContext);
              // Perform the scan operation
              scanService.scanDocuments(
                context: context, // Use the parent context for navigation
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
                  // Redirect to edit screen after success
                  AppRoutes.navigateToEdit(context);
                },
              );
            },
            onImportPressed: () {
              // Close the bottom sheet immediately using the bottom sheet's context
              Navigator.pop(bottomSheetContext);
              // Perform the import operation
              scanService.pickImages(
                context: context, // Use the parent context for navigation
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
                  // Redirect to edit screen after success
                  AppRoutes.navigateToEdit(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Body remains the same
      body: _isLoading
          ? Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: const Center(child: CircularProgressIndicator()),
            )
          : widget.child,

      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Special container for center scan icon
              index == 2
                  ? Container(
                      width: 45.adaptiveSp,
                      height: 45.adaptiveSp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _iconList[index],
                            color: Colors.white,
                            size: 25.adaptiveSp,
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      _iconList[index],
                      size: 24.adaptiveSp,
                      color: isActive ? colorScheme.primary : Colors.grey,
                    ),

              // Only show label for non-center items
              if (index != 2)
                Column(
                  children: [
                    const SizedBox(height: 4),
                    AutoSizeText(
                      _labelList[index],
                      style: GoogleFonts.slabo27px(
                        fontSize: 10.adaptiveSp,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w700,
                        color: isActive ? colorScheme.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
        backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
        activeIndex: _selectedIndex,
        splashColor: colorScheme.primary.withOpacity(0.2),
        gapLocation: GapLocation.none, // Remove gap in the center
        leftCornerRadius: 10,
        rightCornerRadius: 10,

        onTap: _onItemTapped,
        height: 50.h,
      ),
    );
  }
}
