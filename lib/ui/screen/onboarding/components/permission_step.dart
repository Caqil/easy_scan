import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/utils/permission_utils.dart';
import 'package:lottie/lottie.dart';

class PermissionStep extends StatefulWidget {
  final VoidCallback onPermissionsGranted;

  const PermissionStep({
    Key? key,
    required this.onPermissionsGranted,
  }) : super(key: key);

  @override
  State<PermissionStep> createState() => _PermissionStepState();
}

class _PermissionStepState extends State<PermissionStep>
    with SingleTickerProviderStateMixin {
  bool _cameraPermissionGranted = false;
  bool _storagePermissionGranted = false;
  bool _isCheckingPermissions = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    setState(() => _isCheckingPermissions = true);

    final hasCameraPermission = await PermissionUtils.hasCameraPermission();
    final hasStoragePermission = await PermissionUtils.hasStoragePermissions();

    setState(() {
      _cameraPermissionGranted = hasCameraPermission;
      _storagePermissionGranted = hasStoragePermission;
      _isCheckingPermissions = false;
    });

    if (_cameraPermissionGranted && _storagePermissionGranted) {
      widget.onPermissionsGranted();
    }
  }

  Future<void> _requestCameraPermission() async {
    _animationController.forward(from: 0);
    final granted = await PermissionUtils.requestCameraPermission();
    setState(() => _cameraPermissionGranted = granted);
    _checkAllPermissionsGranted();
  }

  Future<void> _requestStoragePermission() async {
    _animationController.forward(from: 0);
    final granted = await PermissionUtils.requestStoragePermissions();
    setState(() => _storagePermissionGranted = granted);
    _checkAllPermissionsGranted();
  }

  void _checkAllPermissionsGranted() {
    if (_cameraPermissionGranted && _storagePermissionGranted) {
      widget.onPermissionsGranted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                Text(
                  'onboarding.permissions_title'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  'onboarding.permissions_description'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40.h),

                // Lottie Animation
                Container(
                  height: 220.h,
                  width: double.infinity,
                  child: Lottie.asset(
                    'assets/animations/permissions.json',
                    fit: BoxFit.contain,
                    controller: _animationController,
                    onLoaded: (composition) {
                      _animationController.duration = composition.duration;
                    },
                  ),
                ),

                SizedBox(height: 40.h),

                // Permission Cards
                _buildPermissionCard(
                  title: 'onboarding.camera_permission'.tr(),
                  description: 'onboarding.camera_permission_desc'.tr(),
                  icon: Icons.camera_alt,
                  isGranted: _cameraPermissionGranted,
                  onRequestPermission: _requestCameraPermission,
                ),
                SizedBox(height: 20.h),
                _buildPermissionCard(
                  title: 'onboarding.storage_permission'.tr(),
                  description: 'onboarding.storage_permission_desc'.tr(),
                  icon: Icons.storage,
                  isGranted: _storagePermissionGranted,
                  onRequestPermission: _requestStoragePermission,
                ),

                SizedBox(height: 40.h),

                // Progress Indicator
                if (_isCheckingPermissions)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onRequestPermission,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isGranted
              ? Colors.green.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isGranted
                      ? [Colors.green.shade300, Colors.green.shade500]
                      : [
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.4),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                isGranted ? Icons.check_circle : icon,
                color: Colors.white,
                size: 28.r,
              ),
            ),
            SizedBox(width: 16.w),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Action Button
            SizedBox(width: 12.w),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isGranted
                  ? Chip(
                      label: Text(
                        'onboarding.granted'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                      backgroundColor: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                    )
                  : ElevatedButton(
                      onPressed: onRequestPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'onboarding.grant'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
