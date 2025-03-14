import 'package:easy_scan/config/routes.dart';
import 'package:easy_scan/services/scan_service.dart';
import 'package:easy_scan/ui/screen/conversion/conversion_screen.dart';
import 'package:easy_scan/ui/screen/folder/folder_screen.dart';
import 'package:easy_scan/ui/screen/home/home_screen.dart';
import 'package:easy_scan/ui/screen/settings_screen.dart';
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

class _MainScreenState extends ConsumerState<MainScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
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

  // Define pages
  static final List<Widget> _pages = [
    const HomeScreen(),
    // Use a placeholder for the Folder screen since we navigate to it with folder parameters
    FolderScreen(),
    const ConversionScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();

    // Set up animation for FAB
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    // Handle tap on folders tab (index 1)
    if (index == 1) {
      _showFoldersScreen(context);
    } else {
      // All other tabs are handled normally
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showFoldersScreen(BuildContext context) {
    // This would typically navigate to the folder screen with root folder
    setState(() {
      _selectedIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final scanService = ref.read(scanServiceProvider);
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true, // Important for transparent effect
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton(
          heroTag: 'mainScreenFab',
          elevation: 8,
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          child: Icon(
            Icons.document_scanner_rounded,
            size: 28.sp,
          ),
          onPressed: () {
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
          },
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar.builder(
        itemCount: _iconList.length,
        tabBuilder: (int index, bool isActive) {
          // Custom tab item with icon and label
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
        // Height for the bottom navigation bar
        height: 65.h,
      ),
    );
  }
}
