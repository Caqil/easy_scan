import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PasswordVerificationDialog extends StatefulWidget {
  final String correctPassword;
  final VoidCallback onVerified;
  final VoidCallback? onCancelled;

  const PasswordVerificationDialog({
    super.key,
    required this.correctPassword,
    required this.onVerified,
    this.onCancelled,
  });

  @override
  State<PasswordVerificationDialog> createState() =>
      _PasswordVerificationDialogState();
}

class _PasswordVerificationDialogState extends State<PasswordVerificationDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isError = false;
  bool _obscureText = true;
  bool _isVerifying = false;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();

    // Setup shake animation for incorrect password
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticIn,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _verifyPassword() async {
    if (_controller.text.isEmpty) {
      setState(() {
        _isError = true;
      });
      _animationController.forward();
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Simulate verification delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_controller.text.trim() == widget.correctPassword) {
      setState(() {
        _isVerifying = false;
        _isError = false;
      });
      Navigator.pop(context);
      widget.onVerified();
    } else {
      setState(() {
        _isVerifying = false;
        _isError = true;
      });
      _animationController.forward();
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            sin(_shakeAnimation.value * 3 * 3.14159) *
                10 *
                _shakeAnimation.value,
            0,
          ),
          child: child,
        );
      },
      child: CupertinoAlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Protected Document'),
          ],
        ),
        content: Container(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This document is protected. Please enter the password to continue.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  CupertinoTextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    obscureText: _obscureText,
                    style: theme.textTheme.bodyLarge,
                    onSubmitted: (_) => _verifyPassword(),
                    autofocus: true,
                    keyboardType: TextInputType.visiblePassword,
                    enableSuggestions: false,
                    autocorrect: false,
                    enabled: !_isVerifying,
                  ),
                  Positioned(
                    right: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          tooltip:
                              _obscureText ? 'Show password' : 'Hide password',
                          splashRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Please check your password and try again',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isVerifying
                ? null
                : () {
                    Navigator.pop(context);
                    widget.onCancelled?.call();
                  },
            child: Text(
              'Cancel',
              style: GoogleFonts.notoSerif(
                color: colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: _isVerifying ? null : _verifyPassword,
            child: _isVerifying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}
