import 'package:flutter/material.dart';

import '../../models/folder.dart';

class FolderCard extends StatelessWidget {
  final Folder folder;
  final int documentCount;
  final VoidCallback onTap;
  final VoidCallback? onMorePressed;

  const FolderCard({
    super.key,
    required this.folder,
    required this.documentCount,
    required this.onTap,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Folder icon and more button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(folder.color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      folder.iconName != null
                          ? IconData(
                              int.parse('0x${folder.iconName}'),
                              fontFamily: 'MaterialIcons',
                            )
                          : Icons.folder,
                      color: Color(folder.color),
                    ),
                  ),
                  const Spacer(),
                  if (onMorePressed != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onMorePressed,
                    ),
                ],
              ),

              const Spacer(),

              // Folder info
              Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$documentCount ${documentCount == 1 ? 'document' : 'documents'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
