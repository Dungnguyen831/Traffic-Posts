import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../utils/hashtag_helper.dart';
import 'like_icon.dart';

class PostItem extends StatefulWidget {
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

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartAnimController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  bool _showHeartOverlay = false;
  bool _isLikedAction = true;
  double? _overlayTop;
  DateTime? _lastDoubleTapTime;
  Offset? _lastImageTapOffset;
  Offset? _lastPostTapOffset;

  @override
  void initState() {
    super.initState();
    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.08)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_heartAnimController);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_heartAnimController);

    _heartAnimController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          setState(() {
            _showHeartOverlay = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    super.dispose();
  }

  /// Xử lý tương tác chạm 2 lần vào ảnh hoặc phạm vi bài viết để Like / Hủy Like
  void _triggerDoubleTapLike({required bool isImage, Offset? tapOffset}) {
    final now = DateTime.now();
    if (_lastDoubleTapTime != null &&
        now.difference(_lastDoubleTapTime!) <
            const Duration(milliseconds: 350)) {
      return;
    }
    _lastDoubleTapTime = now;

    // Trạng thái like trước khi chạm đúp
    final wasLiked = widget.isLikedRx.value;
    final willBeLiked = !wasLiked;

    // Kích hoạt callback like/unlike bài viết
    widget.onLike();

    // Rung xúc giác tạo phản hồi trực quan
    if (willBeLiked) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    // Tính toán toạ độ hiển thị icon hiệu ứng
    const overlayHeight = 90.0;
    final halfOverlay = overlayHeight / 2;

    double calculatedTop;
    if (isImage || (tapOffset != null && tapOffset.dy <= 320.h)) {
      // Khi chạm 2 lần vào ảnh hoặc phần khung ảnh phía trên: căn giữa ảnh (ảnh cao 300.h, padding trên 20.w)
      calculatedTop = 20.w + 150.h - halfOverlay;
    } else if (tapOffset != null) {
      // Khi chạm 2 lần vào phạm vi bài viết: xuất hiện gần vị trí chạm
      calculatedTop = (tapOffset.dy - halfOverlay).clamp(20.w, 800.h);
    } else {
      calculatedTop = 20.w + 150.h - halfOverlay;
    }

    if (mounted) {
      setState(() {
        _isLikedAction = willBeLiked;
        _overlayTop = calculatedTop;
        _showHeartOverlay = true;
      });
      _heartAnimController.forward(from: 0.0);
    }
  }

  /// Widget biểu tượng trái tim / hủy thích bật lên khi nhấn đúp
  Widget _buildHeartOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _heartAnimController,
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final opacity = _opacityAnimation.value.clamp(0.0, 1.0);

          return Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          );
        },
        child: Center(
          child: Container(
            width: 90.w,
            height: 90.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isLikedAction
                  ? AppTheme.primaryColor
                  : const Color(0xFF374151).withValues(alpha: 0.88),
              boxShadow: [
                BoxShadow(
                  color: _isLikedAction
                      ? AppTheme.primaryColor.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24.r,
                  spreadRadius: 2.r,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Icon(
                _isLikedAction
                    ? Icons.favorite_rounded
                    : Icons.heart_broken_rounded,
                size: 50.sp,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Kiểm tra bài viết có phải của chính người dùng hiện tại không
  bool get _isMyPost {
    if (widget.onEdit != null || widget.onDelete != null) return true;
    if (widget.currentUserId == null) return false;
    final rawUserId = widget.post.userId?.trim();
    if (rawUserId == null || rawUserId.isEmpty) return false;
    final postUserId = int.tryParse(rawUserId);
    if (postUserId != null) {
      return postUserId == widget.currentUserId;
    }
    return rawUserId == widget.currentUserId.toString();
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
    final post = widget.post;
    final relativeTime = _formatRelativeTime(post.timestamp);
    final loc = post.location;
    final hasAddress = loc != null &&
        (loc.address.trim().isNotEmpty || (loc.lat != 0.0 && loc.lng != 0.0));
    final displayAddress = (loc != null && loc.address.trim().isNotEmpty)
        ? loc.address.trim()
        : (loc != null
            ? '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}'
            : '');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTapDown: (details) {
        _lastPostTapOffset = details.localPosition;
      },
      onDoubleTap: () => _triggerDoubleTapLike(
        isImage: false,
        tapOffset: _lastPostTapOffset,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                                      'post_img_${post.id ?? post.hashCode}_${identityHashCode(widget)}';

                                  return GestureDetector(
                                    onTap: () {
                                      FullScreenImageViewer.show(
                                        context,
                                        imageUrls: images,
                                        initialIndex: 0,
                                        heroTagPrefix: heroPrefix,
                                      );
                                    },
                                    onDoubleTapDown: (details) {
                                      _lastImageTapOffset = details.localPosition;
                                    },
                                    onDoubleTap: () => _triggerDoubleTapLike(
                                      isImage: true,
                                      tapOffset: _lastImageTapOffset != null
                                          ? Offset(
                                              _lastImageTapOffset!.dx + 20.w,
                                              _lastImageTapOffset!.dy + 20.w,
                                            )
                                          : null,
                                    ),
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
                  final showBadge = _shouldShowFollowBadge(widget.isFollowedRx.value);

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
                                widget.enableHeroAvatar
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
                                      onTap: widget.onFollow,
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
                                      post.userName ?? 'user_fallback'.tr,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time_rounded,
                                      size: 12.sp,
                                      color: Colors.grey[500],
                                    ),
                                    SizedBox(width: 4.w),
                                    Flexible(
                                      child: Text(
                                        relativeTime,
                                        style: TextStyle(
                                          fontSize: 11.5.sp,
                                          color: Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (_isMyPost &&
                          (widget.onEdit != null || widget.onDelete != null))
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
                              widget.onEdit?.call();
                            } else if (value == 'delete') {
                              widget.onDelete?.call();
                            }
                          },
                          itemBuilder: (context) => [
                            if (widget.onEdit != null)
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
                            if (widget.onDelete != null)
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
                    onTap: widget.onTapLocation,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
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
                          if (widget.distanceText != null &&
                              widget.distanceText!.isNotEmpty) ...[
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
                                'dashboard_distance_away'.trParams(
                                    {'distance': widget.distanceText!}),
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
                          if (widget.onTapLocation != null) ...[
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
                          final canonicalTag = HashtagHelper.toCanonical(cleanTag);
                          final isSelectedTag = widget.activeHashtag != null &&
                              widget.activeHashtag!.toLowerCase() ==
                                  canonicalTag;
                          final displayTag = HashtagHelper.format(cleanTag);
                          final tagStyle = TextStyle(
                            fontSize: 16.sp,
                            height: 1.4,
                            fontWeight: isSelectedTag
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: isSelectedTag
                                ? const Color(0xFFE53935)
                                : const Color(0xFF4D5DFA),
                            decoration: isSelectedTag
                                ? TextDecoration.underline
                                : TextDecoration.none,
                          );
                          if (widget.onTapHashtag == null) {
                            return TextSpan(
                              text: '$displayTag ',
                              style: tagStyle,
                            );
                          }
                          return WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => widget.onTapHashtag!(canonicalTag),
                              child: Text(
                                '$displayTag ',
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
                      onTap: widget.onLike,
                      child: Obx(
                        () => Row(
                          children: [
                            LikeIcon(isLiked: widget.isLikedRx.value),
                            SizedBox(width: 8.w),
                            Text(
                              widget.likeCountRx.value.toString(),
                              style: TextStyle(
                                fontSize: 14.4.sp,
                                fontWeight: FontWeight.w600,
                                color: widget.isLikedRx.value
                                    ? const Color(0xFF4D5DFA)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_isMyPost)
                      GestureDetector(
                        onTap: widget.onReport,
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
                            'report'.tr,
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
          ),
          if (_showHeartOverlay)
            Positioned(
              top: _overlayTop,
              left: 0,
              right: 0,
              child: _buildHeartOverlay(),
            ),
        ],
      ),
    );
  }
}
