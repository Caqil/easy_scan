import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DocumentPasswordWidget extends StatefulWidget {
  final TextEditingController passwordController;
  final bool isPasswordProtected;
  final ColorScheme colorScheme;

  const DocumentPasswordWidget({
    super.key,
    required this.passwordController,
    required this.isPasswordProtected,
    required this.colorScheme,
  });

  @override
  State<DocumentPasswordWidget> createState() => _DocumentPasswordWidgetState();
}

class _DocumentPasswordWidgetState extends State<DocumentPasswordWidget> {
  bool _obscureText = true;
  bool _isProtectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _isProtectionEnabled = widget.isPasswordProtected;

    // Debug message to verify the password status
    print("Password protection initialized: $_isProtectionEnabled");
    if (_isProtectionEnabled) {
      print(
          "Password value: ${widget.passwordController.text.isNotEmpty ? '[Password exists]' : '[No password]'}");
    }
  }

  @override
  void didUpdateWidget(DocumentPasswordWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update the protection state if it changes from parent
    if (oldWidget.isPasswordProtected != widget.isPasswordProtected) {
      setState(() {
        _isProtectionEnabled = widget.isPasswordProtected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isProtectionEnabled
              ? widget.colorScheme.primary.withOpacity(0.5)
              : widget.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Password protection toggle
          SwitchListTile(
            title: Text(
              'Password Protection',
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.w500,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Text(
              _isProtectionEnabled
                  ? 'Document will be password protected'
                  : 'Add a password to protect this document',
              style: GoogleFonts.notoSerif(
                fontSize: 12.sp,
                color: widget.colorScheme.onSurfaceVariant,
              ),
            ),
            value: _isProtectionEnabled,
            activeColor: widget.colorScheme.inversePrimary,
            onChanged: (value) {
              setState(() {
                _isProtectionEnabled = value;
                if (!value) {
                  widget.passwordController.clear();
                }
              });
            },
            secondary: Icon(
              _isProtectionEnabled ? Icons.lock : Icons.lock_open_outlined,
              color: _isProtectionEnabled
                  ? widget.colorScheme.primary
                  : widget.colorScheme.onSurfaceVariant,
            ),
          ),

          // Password field (shown only when protection is enabled)
          if (_isProtectionEnabled)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: TextField(
                controller: widget.passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter document password',
                  prefixIcon: Icon(Icons.password_outlined,
                      color: widget.colorScheme.primary),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: widget.colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                    borderSide: BorderSide(
                      color: widget.colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
