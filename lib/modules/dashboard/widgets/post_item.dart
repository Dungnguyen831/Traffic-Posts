import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../data/models/traffic_post_model.dart';
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
  });

  /// Hiện badge "+" khi:
  /// 1. API trả về follow == false
  /// 2. Không phải bài viết của chính mình
  bool _shouldShowFollowBadge(bool isFollowed) {
    if (isFollowed) return false;
    final postUserId = int.tryParse(post.userId ?? '');
    if (postUserId != null && postUserId == currentUserId) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0x0D04060F), // 5% opacity pre-computed
            offset: const Offset(0, 4),
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
                  ? CachedNetworkImage(
                      imageUrl: post.fullImageUrls!.first,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      fadeInDuration: Duration.zero,
                      fadeOutDuration: Duration.zero,
                      placeholder: (context, url) =>
                          const Center(child: LoadingWidget()),
                      errorWidget: (context, url, error) => Center(
                        child: Icon(
                          IconlyBroken.image_2,
                          size: 48.w,
                          color: Colors.grey[400],
                        ),
                      ),
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
          // User Info
          Obx(() {
            // Giữ lại logic check badge realtime
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
                // gestureDetector bao quanh cả avatar để chuyển trang
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
                      top: 8.h,
                      bottom: 8.h,
                    ),
                    child: SizedBox(
                      width: 46.w,
                      height: 46.w,
                      child: Stack(
                        children: [
                          // bọc avatar bằng Hero để chuyển động mượt mà khi vào trang profile
                          enableHeroAvatar
                              ? Hero(
                                  tag: 'avatar_${post.id}',
                                  child: avatarWidget,
                                )
                              : avatarWidget,
                          // tách follow và chuyển trang profile
                          if (showBadge)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap:
                                    onFollow, // Bấm chính xác vào dấu + mới follow
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

                // BẤM VÀO TÊN ĐỂ CHUYỂN TRANG
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
                    child: Row(
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
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: 8.h),
          // Content
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF616161),
                height: 1.4,
              ),
              children: [
                TextSpan(text: "${post.content} "),
                if (post.hashtags?.isNotEmpty ?? false)
                  TextSpan(
                    text: " #${post.hashtags?.join(" #") ?? ''}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4D5DFA),
                    ),
                  ),
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
                    "Báo cáo".tr,
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
