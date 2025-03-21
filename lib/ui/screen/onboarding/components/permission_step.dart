import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            AutoSizeText(
              'onboarding.permissions_title'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 12.h),
            AutoSizeText(
              'onboarding.permissions_description'.tr(),
              style: GoogleFonts.slabo27px(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withOpacity(0.7),
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),

            // Lottie Animation
            Center(
              child: Container(
                height: 180.h,
                child: Lottie.asset(
                  'assets/animations/permissions.json',
                  fit: BoxFit.contain,
                  controller: _animationController,
                  onLoaded: (composition) {
                    _animationController.duration = composition.duration;
                  },
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Permission Cards
            _buildPermissionCard(
              title: 'onboarding.camera_permission'.tr(),
              description: 'onboarding.camera_permission_desc'.tr(),
              icon: Icons.camera_alt,
              isGranted: _cameraPermissionGranted,
              onRequestPermission: _requestCameraPermission,
            ),
            SizedBox(height: 16.h),
            _buildPermissionCard(
              title: 'onboarding.storage_permission'.tr(),
              description: 'onboarding.storage_permission_desc'.tr(),
              icon: Icons.folder_outlined,
              isGranted: _storagePermissionGranted,
              onRequestPermission: _requestStoragePermission,
            ),

            SizedBox(height: 32.h),

            // Progress Indicator
            if (_isCheckingPermissions)
              Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isGranted
              ? colorScheme.primary.withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isGranted ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isGranted
                    ? colorScheme.primary.withOpacity(0.2)
                    : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                isGranted ? Icons.check : icon,
                color: isGranted
                    ? colorScheme.primary
                    : colorScheme.primary.withOpacity(0.7),
                size: 24.r,
              ),
            ),
            SizedBox(width: 16.w),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    title,
                    style: GoogleFonts.slabo27px(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AutoSizeText(
                    description,
                    style: GoogleFonts.slabo27px(
                      fontSize: 12.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
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
                  ? Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16.r,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4.w),
                          AutoSizeText(
                            'onboarding.granted'.tr(),
                            style: GoogleFonts.slabo27px(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    )
                  : OutlinedButton(
                      onPressed: onRequestPermission,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                      ),
                      child: AutoSizeText(
                        'onboarding.grant'.tr(),
                        style: GoogleFonts.slabo27px(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
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
