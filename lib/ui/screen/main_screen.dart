import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/services/scan_service.dart';
import 'package:easy_scan/ui/screen/conversion/conversion_screen.dart';
import 'package:easy_scan/ui/screen/folder/folder_screen.dart';
import 'package:easy_scan/ui/screen/home/home_screen.dart';
import 'package:easy_scan/ui/screen/settings_screen.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_scan/ui/screen/camera/component/scan_initial_view.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  bool _isLoading = false;

  final _iconList = <IconData>[
    Icons.home_rounded,
    Icons.folder_rounded,
    Icons.compare_arrows_rounded,
    Icons.settings_rounded,
  ];

  final _labelList = <String>[
    'Home',
    'Folders',
    'Convert',
    'Settings',
  ];

  static final List<Widget> _pages = [
    const HomeScreen(),
    FolderScreen(),
    const ConversionScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showFoldersScreen(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showFoldersScreen(BuildContext context) {
    setState(() {
      _selectedIndex = 1;
    });
  }

  void _handleScanAction() {
    final scanService = ref.read(scanServiceProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: ScanInitialView(
            onScanPressed: () {
              scanService.scanDocuments(
                context: context,
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
                  AppRoutes.navigateToEdit(context);
                },
              );
            },
            onImportPressed: () {
              scanService.pickImages(
                context: context,
                ref: ref,
                setLoading: (isLoading) =>
                    setState(() => _isLoading = isLoading),
                onSuccess: () {
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true,
      floatingActionButton: GestureDetector(
        onTap: _handleScanAction,
        child: Container(
          width: 60.sp,
          height: 60.sp,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.document_scanner_rounded,
                size: 24.sp,
                color: Colors.white,
              ),
              Text(
                'Scan',
                style: GoogleFonts.notoSerif(
                  fontSize: 10.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconList[index],
                size: 24.sp,
                color: isActive ? colorScheme.primary : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                _labelList[index],
                style: GoogleFonts.notoSerif(
                  fontSize: 12.sp,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? colorScheme.primary : Colors.grey,
                ),
              ),
            ],
          );
        },
        backgroundColor: isDarkMode ? const Color(0xFF1F1F1F) : Colors.white,
        activeIndex: _selectedIndex,
        splashColor: colorScheme.primary.withOpacity(0.2),
        notchSmoothness: NotchSmoothness.softEdge,
        gapLocation: GapLocation.center,
        leftCornerRadius: 16,
        rightCornerRadius: 16,
        shadow: BoxShadow(
          offset: const Offset(0, -2),
          blurRadius: 12,
          spreadRadius: 0.5,
          color: Colors.black.withOpacity(0.1),
        ),
        onTap: _onItemTapped,
        height: 65.h,
      ),
    );
  }
}
