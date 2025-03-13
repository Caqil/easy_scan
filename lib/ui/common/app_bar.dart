import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget title;
  final List<Widget>? actions;
  final bool centerTitle;
  final double elevation;
  final Color? backgroundColor;
  final Widget? leading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
    this.elevation = 0,
    this.backgroundColor,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      title: title,
      actions: actions,
      centerTitle: centerTitle,
      elevation: elevation,
      backgroundColor: backgroundColor,
      leading: leading,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
