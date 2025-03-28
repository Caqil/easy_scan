// auth_overlay.dart
import 'package:scanpro/models/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthOverlay extends ConsumerWidget {
  const AuthOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // If no auth state, biometrics are disabled, or already authenticated, show nothing
    if (authState == null || authState.isAuthenticated) {
      return const SizedBox.shrink();
    }

    // Show the authentication overlay
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              authState.isAuthenticating
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.fingerprint, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              AutoSizeText(
                'Authentication Required',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              AutoSizeText(
                'This app is protected with biometric authentication.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed:
                    authState.isAuthenticating ? null : authState.authenticate,
                child: AutoSizeText(authState.isAuthenticating
                    ? 'Authenticating...'
                    : 'Authenticate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
