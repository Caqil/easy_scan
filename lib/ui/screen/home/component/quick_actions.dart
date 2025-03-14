// lib/ui/widget/quick_actions.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuickActions extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onImport;
  final VoidCallback onFolders;
  final VoidCallback onFavorites;

  const QuickActions({
    super.key,
    required this.onScan,
    required this.onImport,
    required this.onFolders,
    required this.onFavorites,
  });

  @override
  Widget build(BuildContext context) {
    // Create a gradient background instead of using a Card
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern header with cleaner typography
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 18,
                      width: 3,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'QUICK ACTIONS',
                      style: GoogleFonts.notoSerif(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'What would you like to do?',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16.sp.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // Modern action buttons in a grid layout
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
            children: [
              _buildActionButton(
                context,
                icon: Icons.document_scanner_outlined,
                label: 'Scan',
                description: 'Document',
                color: Colors.blue.shade700,
                onTap: onScan,
              ),
              _buildActionButton(
                context,
                icon: Icons.file_upload_outlined,
                label: 'Import',
                description: 'Files',
                color: Colors.green.shade600,
                onTap: onImport,
              ),
              _buildActionButton(
                context,
                icon: Icons.folder_outlined,
                label: 'Browse',
                description: 'Folders',
                color: Colors.orange.shade700,
                onTap: onFolders,
              ),
              _buildActionButton(
                context,
                icon: Icons.star_outline,
                label: 'View',
                description: 'Favorites',
                color: Colors.amber.shade700,
                onTap: onFavorites,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color:
              isDarkMode ? Colors.grey.shade800.withOpacity(0.4) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.notoSerif(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              description,
              style: GoogleFonts.notoSerif(
                fontSize: 11,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MinimalistQuickActions extends StatefulWidget {
  final VoidCallback onScan;
  final VoidCallback onImport;
  final VoidCallback onFolders;
  final VoidCallback onFavorites;

  const MinimalistQuickActions({
    super.key,
    required this.onScan,
    required this.onImport,
    required this.onFolders,
    required this.onFavorites,
  });

  @override
  State<MinimalistQuickActions> createState() => _MinimalistQuickActionsState();
}

class _MinimalistQuickActionsState extends State<MinimalistQuickActions> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Action items data
    final actions = [
      {
        'icon': Icons.camera_enhance_outlined,
        'label': 'Scan',
        'onTap': widget.onScan,
        'color': Colors.blue.shade500,
      },
      {
        'icon': Icons.upload_file_outlined,
        'label': 'Import',
        'onTap': widget.onImport,
        'color': Colors.green.shade500,
      },
      {
        'icon': Icons.folder_open_outlined,
        'label': 'Folders',
        'onTap': widget.onFolders,
        'color': Colors.orange.shade500,
      },
      {
        'icon': Icons.star_border_outlined,
        'label': 'Favorites',
        'onTap': widget.onFavorites,
        'color': Colors.amber.shade500,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle section header
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 5),
            child: Text(
              'Quick Actions',
              style: GoogleFonts.notoSerif(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
          ),

          // Actions row with glass-like effect
          Container(
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDarkMode
                  ? Colors.grey.shade900.withOpacity(0.3)
                  : Colors.grey.shade50,
              boxShadow: [
                BoxShadow(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(actions.length, (index) {
                final action = actions[index];

                return MouseRegion(
                  onEnter: (_) => setState(() => _hoveredIndex = index),
                  onExit: (_) => setState(() => _hoveredIndex = null),
                  child: GestureDetector(
                    onTap: action['onTap'] as VoidCallback,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 70,
                      height: 70,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _hoveredIndex == index
                            ? (action['color'] as Color).withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hoveredIndex == index
                              ? (action['color'] as Color).withOpacity(0.3)
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                            size: 26,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['label'] as String,
                            style: GoogleFonts.notoSerif(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w500,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
