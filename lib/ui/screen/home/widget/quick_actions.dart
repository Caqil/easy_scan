// quick_actions.dart
import 'package:flutter/material.dart';

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
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.camera_alt, 'Scan', onScan),
                _buildQuickAction(Icons.image, 'Import', onImport),
                _buildQuickAction(Icons.folder_open, 'Folders', onFolders),
                _buildQuickAction(Icons.star, 'Favorites', onFavorites),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 24, child: Icon(icon)),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
