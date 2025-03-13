import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color(folder.color).withOpacity(0.5),
          width: 1.5,
        ),
      ),
      elevation: 3,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Color(folder.color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          folder.iconName != null
                              ? IconData(
                                  int.parse('0x${folder.iconName}'),
                                  fontFamily: 'MaterialIcons',
                                )
                              : Icons.folder,
                          color: Color(folder.color),
                          size: 28,
                        ),
                      ),
                      if (documentCount > 0)
                        Positioned(
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Text(
                              '$documentCount',
                              style: GoogleFonts.notoSerif(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: Color(folder.color),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (onMorePressed != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: onMorePressed,
                    ),
                ],
              ),
              Text(
                folder.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSerif(
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
