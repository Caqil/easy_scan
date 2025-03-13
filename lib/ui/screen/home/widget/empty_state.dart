// empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const EmptyState({super.key, required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner, size: 80, color: Colors.grey),
          const SizedBox(height: 24),
          const Text(
            'No documents yet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan or import your first document',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onScan,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Start Scanning'),
          ),
        ],
      ),
    );
  }
}
