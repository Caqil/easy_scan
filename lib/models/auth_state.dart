// Define a separate class for auth state
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  final bool isAuthenticating;
  final bool isAuthenticated;
  final Function() authenticate;

  AuthState({
    required this.isAuthenticating,
    required this.isAuthenticated,
    required this.authenticate,
  });
}

// Create a provider for auth state
final authStateProvider = StateProvider<AuthState?>((ref) => null);
