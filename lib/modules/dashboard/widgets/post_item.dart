import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/full_screen_image_viewer.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/reputation_badge.dart';
import '../../profile/views/user_profile_screen.dart';
import 'like_icon.dart';

class PostItem extends StatelessWidget {
  final TrafficPostModel post;
  final VoidCallback onLike;
  final VoidCallback onReport;
  final VoidCallback onFollow;
  final int? currentUserId;
  final RxBool isLikedRx;
  final RxInt likeCountRx;
  final RxBool isFollowedRx;
  final bool enableHeroAvatar;
  final String? distanceText;
  final VoidCallback? onTapLocation;
  final void Function(String tag)? onTapHashtag;
  final String? activeHashtag;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PostItem({
    super.key,
    required this.post,
    required this.onLike,
    required this.onReport,
    required this.onFollow,
    required this.isLikedRx,
    required this.likeCountRx,
    required this.isFollowedRx,
    this.currentUserId,
    this.enableHeroAvatar = true,
    this.distanceText,
    this.onTapLocation,
    this.onTapHashtag,
    this.activeHashtag,
    this.onEdit,
    this.onDelete,
  });

  /// Kiểm tra bài viết có phải của chính người dùng hiện tại không
  bool get _isMyPost {
    if (currentUserId == null) return false;
    final rawUserId = post.userId;
    if (rawUserId == null || rawUserId.isEmpty) {
      return onEdit != null || onDelete != null;
    }
    final postUserId = int.tryParse(rawUserId);
    return postUserId != null && postUserId == currentUserId;
  }

  /// Hiện badge "+" khi:
  /// 1. API trả về follow == false
  /// 2. Không phải bài viết của chính mình
  bool _shouldShowFollowBadge(bool isFollowed) {
    if (isFollowed || _isMyPost) return false;
    return true;
  }

  /// Định dạng thời gian đăng bài tương đối (Vừa xong, X phút trước, X giờ trước...)
  String? _formatRelativeTime(DateTime? timestamp) {
    if (timestamp == null) return null;
    final now = DateTime.now();
    final diff = now.difference(timestamp.toLocal());

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'dashboard_time_just_now'.tr;
    }
    if (diff.inMinutes < 60) {
      return 'dashboard_time_minutes_ago'
          .trParams({'min': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'dashboard_time_hours_ago'.trParams({'hour': '${diff.inHours}'});
    }
    if (diff.inDays < 7) {
      return 'dashboard_time_days_ago'.trParams({'day': '${diff.inDays}'});
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final relativeTime = _formatRelativeTime(post.timestamp);
    final loc = post.location;
    final hasAddress = loc != null &&
        (loc.address.trim().isNotEmpty || (loc.lat != 0.0 && loc.lng != 0.0));
    final displayAddress = (loc != null && loc.address.trim().isNotEmpty)
        ? loc.address.trim()
        : (loc != null
            ? '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}'
            : '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D04060F), // 5% opacity pre-computed
            offset: Offset(0, 4),
            blurRadius: 60,
          ),
        ],
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image/Map Area
          Container(
            height: 300.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child:
                  post.fullImageUrls != null && post.fullImageUrls!.isNotEmpty
                      ? Builder(
                          builder: (context) {
                            final images = post.fullImageUrls!;
                            final heroPrefix =
                                'post_img_${post.id ?? post.hashCode}_${identityHashCode(this)}';

                            return GestureDetector(
                              onTap: () {
                                FullScreenImageViewer.show(
                                  context,
                                  imageUrls: images,
                                  initialIndex: 0,
                                  heroTagPrefix: heroPrefix,
                                );
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Hero(
                                    tag: '${heroPrefix}_0',
                                    child: CachedNetworkImage(
                                      imageUrl: images.first,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 800,
                                      fadeInDuration: Duration.zero,
                                      fadeOutDuration: Duration.zero,
                                      placeholder: (context, url) =>
                                          const Center(child: LoadingWidget()),
                                      errorWidget: (context, url, error) =>
                                          Center(
                                        child: Icon(
                                          IconlyBroken.image_2,
                                          size: 48.w,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Badge gợi ý bấm để phóng to & tổng số ảnh
                                  Positioned(
                                    right: 10.w,
                                    bottom: 10.h,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.black.withValues(alpha: 0.58),
                                        borderRadius:
                                            BorderRadius.circular(20.r),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.zoom_out_map_rounded,
                                            color: Colors.white,
                                            size: 14.sp,
                                          ),
                                          if (images.length > 1) ...[
                                            SizedBox(width: 4.w),
                                            Text(
                                              '1/${images.length}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(
                            IconlyBroken.location,
                            size: 48.w,
                            color: Colors.grey[400],
                          ),
                        ),
            ),
          ),
          SizedBox(height: 12.h),

          // User Info + Relative Time
          Obx(() {
            final showBadge = _shouldShowFollowBadge(isFollowedRx.value);

            final avatarWidget = ClipOval(
              child: post.fullAvatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: post.fullAvatarUrl!,
                      width: 40.w,
                      height: 40.w,
                      fit: BoxFit.cover,
                      memCacheWidth: 120,
                      memCacheHeight: 120,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) => Container(
                        width: 40.w,
                        height: 40.w,
                        color: Colors.grey[300],
                        child: LoadingWidget(width: 40.w, height: 40.w),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 40.w,
                        height: 40.w,
                        color: Colors.grey[300],
                        child: Icon(
                          IconlyBroken.profile,
                          size: 24.w,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                      child: Icon(
                        IconlyBroken.profile,
                        size: 24.w,
                        color: Colors.grey[600],
                      ),
                    ),
            );

            return Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (post.userId != null) {
                      final heroTag = 'avatar_${post.id}';
                      Get.to(
                        () => const UserProfileScreen(),
                        arguments: {
                          'userId': post.userId,
                          'heroTag': heroTag,
                          'initialAvatarUrl': post.fullAvatarUrl,
                          'initialUserName': post.userName,
                        },
                      );
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: 12.w,
                      top: 6.h,
                      bottom: 6.h,
                    ),
                    child: SizedBox(
                      width: 46.w,
                      height: 46.w,
                      child: Stack(
                        children: [
                          enableHeroAvatar
                              ? Hero(
                                  tag: 'avatar_${post.id}',
                                  child: avatarWidget,
                                )
                              : avatarWidget,
                          if (showBadge)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: onFollow,
                                child: Container(
                                  width: 24.w,
                                  height: 24.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4D5DFA),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (post.userId != null) {
                        final heroTag = 'avatar_${post.id}';
                        Get.to(
                          () => const UserProfileScreen(),
                          arguments: {
                            'userId': post.userId,
                            'heroTag': heroTag,
                          },
                        );
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                post.userName ?? 'Người dùng',
                                style: TextStyle(
                                  fontSize: 15.2.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1C1C1E),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            ReputationBadgeWidget(
                              badge: (post.userBadge != null &&
                                      post.userBadge!.trim().isNotEmpty)
                                  ? post.userBadge!
                                  : 'Người dẫn đường',
                              score: post.userReputationScore,
                              isCompact: true,
                            ),
                          ],
                        ),
                        if (relativeTime != null) ...[
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 12.sp,
                                color: Colors.grey[500],
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                relativeTime,
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isMyPost && (onEdit != null || onDelete != null))
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    color: Colors.white,
                    surfaceTintColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: const Color(0xFF616161),
                      size: 22.sp,
                    ),
                    onSelected: (value) {
                      if (value == 'edit') {
                        onEdit?.call();
                      } else if (value == 'delete') {
                        onDelete?.call();
                      }
                    },
                    itemBuilder: (context) => [
                      if (onEdit != null)
                        PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                IconlyLight.edit,
                                size: 18.sp,
                                color: AppTheme.textColor,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'post_edit_option'.tr,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (onDelete != null)
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                IconlyLight.delete,
                                size: 18.sp,
                                color: AppTheme.errorColor,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'post_delete_option'.tr,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            );
          }),

          // Location & Distance Bar (tappable to view on Map)
          if (hasAddress) ...[
            SizedBox(height: 6.h),
            GestureDetector(
              onTap: onTapLocation,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: const Color(0xFFE9ECF5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      IconlyBold.location,
                      size: 15.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 6.w),
                    if (distanceText != null && distanceText!.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'dashboard_distance_away'
                              .trParams({'distance': distanceText!}),
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                    ],
                    Expanded(
                      child: Text(
                        displayAddress,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4B5563),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onTapLocation != null) ...[
                      SizedBox(width: 6.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'dashboard_view_on_map'.tr,
                            style: TextStyle(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16.sp,
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          SizedBox(height: 10.h),

          // Content + Interactive Hashtags
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF616161),
                height: 1.4,
              ),
              children: [
                TextSpan(text: '${post.content ?? ''} '),
                if (post.hashtags != null && post.hashtags!.isNotEmpty)
                  ...post.hashtags!.map((tag) {
                    final cleanTag = tag.replaceAll('#', '').trim();
                    final isSelectedTag = activeHashtag != null &&
                        activeHashtag!.toLowerCase() == cleanTag.toLowerCase();
                    final tagStyle = TextStyle(
                      fontSize: 16.sp,
                      height: 1.4,
                      fontWeight:
                          isSelectedTag ? FontWeight.w800 : FontWeight.w600,
                      color: isSelectedTag
                          ? const Color(0xFFE53935)
                          : const Color(0xFF4D5DFA),
                      decoration: isSelectedTag
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    );
                    if (onTapHashtag == null) {
                      return TextSpan(
                        text: '#$cleanTag ',
                        style: tagStyle,
                      );
                    }
                    return WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () => onTapHashtag!(cleanTag),
                        child: Text(
                          '#$cleanTag ',
                          style: tagStyle,
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          SizedBox(height: 12.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: onLike,
                child: Obx(
                  () => Row(
                    children: [
                      LikeIcon(isLiked: isLikedRx.value),
                      SizedBox(width: 8.w),
                      Text(
                        likeCountRx.value.toString(),
                        style: TextStyle(
                          fontSize: 14.4.sp,
                          fontWeight: FontWeight.w600,
                          color: isLikedRx.value
                              ? const Color(0xFF4D5DFA)
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: onReport,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: const Color(0xFFF75555)),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Báo cáo'.tr,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF75555),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
