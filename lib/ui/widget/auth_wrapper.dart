// Updated auth_wrapper.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:easy_scan/models/auth_state.dart';
import 'package:easy_scan/providers/settings_provider.dart';
import 'package:easy_scan/services/auth_service.dart';
import 'package:easy_scan/ui/common/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  final Widget Function(BuildContext) builder;

  const AuthWrapper({Key? key, required this.builder}) : super(key: key);

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
                content: Text('auth.auth_failed'.tr()),
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
            AppDialogs.showSnackBar(context,
                message:
                    'Biometric authentication is not available on this device.');
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
          AppDialogs.showSnackBar(context,
              message: 'Error during authentication: $e');
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
