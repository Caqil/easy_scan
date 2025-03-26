import 'package:flutter/material.dart';
import 'package:scanpro/utils/screen_util_extensions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scanpro/config/helper.dart';
import 'package:scanpro/ui/screen/premium/premium_screen.dart';
import 'package:scanpro/ui/common/dialogs.dart';

import '../services/compress_limit_service.dart';

class CompressionLimitUtils {
  static const _animationDuration = Duration(milliseconds: 300);

  /// Display a premium upgrade dialog when user tries to use a premium compression level
  static Future<void> showPremiumCompressionDialog(
    BuildContext context,
    CompressionLevel level,
  ) async {
    final levelName = _getCompressionLevelName(level);

    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: _animationDuration,
      pageBuilder: (context, animation, secondaryAnimation) => ScaleTransition(
        scale: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          backgroundColor: Theme.of(context).dialogBackgroundColor,
          title: Semantics(
            label: 'Premium compression feature',
            child: Text(
              'compression.premium_feature.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          content: _buildPremiumLevelDialogContent(context, levelName),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: _buildPremiumDialogActions(context),
        ),
      ),
    );
  }

  static Widget _buildPremiumLevelDialogContent(
      BuildContext context, String levelName) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      constraints: BoxConstraints(maxWidth: screenWidth * 0.85),
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Locked feature icon',
            child: Icon(
              Icons.compress,
              color: Theme.of(context).colorScheme.primary,
              size: 60,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'compression.premium_feature.message'
                .tr(namedArgs: {'level': levelName}),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          SizedBox(height: 12),
          Text(
            'compression.premium_feature.upgrade_prompt'.tr(),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  static List<Widget> _buildPremiumDialogActions(BuildContext context) {
    return [
      OutlinedButton(
        onPressed: () {
          Navigator.pop(context);
          if (context.mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumScreen()),
            );
          }
        },
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 3,
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        child: Semantics(
          label: 'Upgrade to premium button',
          child: Text(
            'compression.premium_feature.upgrade'.tr(),
            style: GoogleFonts.slabo27px(
                fontWeight: FontWeight.bold, fontSize: 14.adaptiveSp),
          ),
        ),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        child: Semantics(
          label: 'Cancel button',
          child: Text(
            'common.cancel'.tr(),
            style: GoogleFonts.slabo27px(
                color: Theme.of(context).colorScheme.secondary),
          ),
        ),
      ),
    ];
  }

  /// Checks if a compression level is available, and shows an upgrade dialog if not
  static Future<bool> canUseCompressionLevel(
    BuildContext context,
    WidgetRef ref,
    CompressionLevel level, {
    bool showDialog = true,
  }) async {
    try {
      final isAvailableAsync =
          ref.read(isCompressionLevelAvailableProvider(level));
      final isAvailable = isAvailableAsync.value ?? false;

      // If level is not available and dialog should be shown
      if (!isAvailable && showDialog && context.mounted) {
        await showPremiumCompressionDialog(context, level);
        return false;
      }

      return isAvailable;
    } catch (e) {
      if (context.mounted) {
        AppDialogs.showSnackBar(
          context,
          message: 'compression.error_checking_availability'.tr(),
          type: SnackBarType.error,
        );
      }
      return level ==
          CompressionLevel.low; // Default to allowing only low level
    }
  }

  /// Get user-friendly name for compression level
  static String _getCompressionLevelName(CompressionLevel level) {
    switch (level) {
      case CompressionLevel.low:
        return 'compression.level.low'.tr();
      case CompressionLevel.medium:
        return 'compression.level.medium'.tr();
      case CompressionLevel.high:
        return 'compression.level.high'.tr();
      case CompressionLevel.maximum:
        return 'compression.level.maximum'.tr();
    }
  }

  /// Get all available compression levels with premium indicator
  static Future<List<Map<String, dynamic>>> getCompressionLevelOptions(
      WidgetRef ref) async {
    try {
      final compressionLimitService = ref.read(compressionLimitServiceProvider);
      final availableLevels =
          await compressionLimitService.getAvailableCompressionLevels();

      // Create options list with premium indicators
      List<Map<String, dynamic>> options = [];

      for (var level in CompressionLevel.values) {
        final isAvailable = availableLevels.contains(level);

        options.add({
          'level': level,
          'name': _getCompressionLevelName(level),
          'isAvailable': isAvailable,
          'isPremium': level != CompressionLevel.low,
        });
      }

      return options;
    } catch (e) {
      // On error, return just the low level option
      return [
        {
          'level': CompressionLevel.low,
          'name': _getCompressionLevelName(CompressionLevel.low),
          'isAvailable': true,
          'isPremium': false,
        },
        {
          'level': CompressionLevel.medium,
          'name': _getCompressionLevelName(CompressionLevel.medium),
          'isAvailable': false,
          'isPremium': true,
        },
        {
          'level': CompressionLevel.high,
          'name': _getCompressionLevelName(CompressionLevel.high),
          'isAvailable': false,
          'isPremium': true,
        },
        {
          'level': CompressionLevel.maximum,
          'name': _getCompressionLevelName(CompressionLevel.maximum),
          'isAvailable': false,
          'isPremium': true,
        },
      ];
    }
  }
}
