// Updated auth_wrapper.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:scanpro/models/auth_state.dart';
import 'package:scanpro/providers/settings_provider.dart';
import 'package:scanpro/services/auth_service.dart';
import 'package:scanpro/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final Widget Function(BuildContext) builder;

  const AuthWrapper({super.key, required this.builder});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isAuthenticating = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    // Delay authentication check until after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAuthenticate();
      _updateAuthState();
    });
  }

  void _updateAuthState() {
    ref.read(authStateProvider.notifier).state = AuthState(
      isAuthenticating: _isAuthenticating,
      isAuthenticated: _isAuthenticated,
      authenticate: _checkAndAuthenticate,
    );
  }

  Future<void> _checkAndAuthenticate() async {
    final settings = ref.read(settingsProvider);

    // Only proceed with authentication if biometrics are enabled
    if (settings.biometricAuthEnabled) {
      setState(() {
        _isAuthenticating = true;
      });
      _updateAuthState();

      try {
        // Check if biometrics are available on this device
        final isBiometricAvailable = await _authService.isBiometricAvailable();
        if (isBiometricAvailable) {
          // Prompt for authentication
          final authenticated = await _authService.authenticateWithBiometrics();
          setState(() {
            _isAuthenticated = authenticated;
            _isAuthenticating = false;
          });
          _updateAuthState();

          // If authentication failed, show a message
          if (!authenticated && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: AutoSizeText('auth.auth_failed'.tr()),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Biometrics not available, so allow access anyway
          setState(() {
            _isAuthenticated = true;
            _isAuthenticating = false;
          });
          _updateAuthState();

          if (mounted) {
            AppDialogs.showSnackBar(
              context,
              message: 'auth.biometrics_not_available'.tr(),
            );
          }
        }
      } catch (e) {
        // Handle any errors
        setState(() {
          _isAuthenticated = false;
          _isAuthenticating = false;
        });
        _updateAuthState();

        if (mounted) {
          AppDialogs.showSnackBar(
            context,
            message:
                'auth.error_during_auth'.tr(namedArgs: {'error': e.toString()}),
          );
        }
      }
    } else {
      // Biometrics not enabled in settings, allow access
      setState(() {
        _isAuthenticated = true;
      });
      _updateAuthState();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always build the main app structure
    return widget.builder(context);
  }
}
