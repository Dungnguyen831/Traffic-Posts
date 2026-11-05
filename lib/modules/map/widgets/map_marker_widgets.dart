import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Marker đơn lẻ phong cách Apple Maps (Pill Badge + Circular Icon Pin)
class PostMarkerWidget extends StatelessWidget {
  final Color tagColor;
  final IconData tagIcon;
  final String displayTag;
  final bool shouldShowTag;
  final VoidCallback onTap;

  const PostMarkerWidget({
    super.key,
    required this.tagColor,
    required this.tagIcon,
    required this.displayTag,
    required this.shouldShowTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (shouldShowTag)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tagColor.withValues(alpha: 0.25),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                displayTag,
                style: TextStyle(
                  color: tagColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Apple Maps Circular Badge Pin
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tagColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 6,
                  offset: const Offset(0, 2.5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Icon(tagIcon, color: Colors.white, size: 17),
          ),
        ],
      ),
    );
  }
}

/// Cluster Marker phong cách Apple Maps khi gom nhiều bài viết gần nhau (+N Badge Counter)
class ClusterMarkerWidget extends StatelessWidget {
  final Color tagColor;
  final IconData tagIcon;
  final String displayTag;
  final int count;
  final bool shouldShowTag;
  final VoidCallback onTap;

  const ClusterMarkerWidget({
    super.key,
    required this.tagColor,
    required this.tagIcon,
    required this.displayTag,
    required this.count,
    required this.shouldShowTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countText = count > 99 ? '99+' : '$count';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (shouldShowTag)
            Container(
              margin: const EdgeInsets.only(bottom: 3),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tagColor.withValues(alpha: 0.35),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayTag,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '+${count - 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: 48,
            height: 40,
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.24),
                        blurRadius: 7,
                        offset: const Offset(0, 2.5),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(tagIcon, color: Colors.white, size: 19),
                ),
                Positioned(
                  top: -2,
                  right: 0,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.textColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      countText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

