import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../data/models/user_info_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/reputation_badge.dart';
import '../../profile/views/user_profile_screen.dart';

class RankingItemCard extends StatelessWidget {
  final int rank;
  final UserInfoModel user;

  const RankingItemCard({
    super.key,
    required this.rank,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final heroTag = 'ranking_avatar_${user.id}_$rank';
    final isTop1 = rank == 1;
    final isTop2 = rank == 2;
    final isTop3 = rank == 3;
    final isTopThree = isTop1 || isTop2 || isTop3;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isTop1
              ? const Color(0xFFFFD700).withValues(alpha: 0.5)
              : isTop2
                  ? const Color(0xFFB0BEC5).withValues(alpha: 0.5)
                  : isTop3
                      ? const Color(0xFFCD7F32).withValues(alpha: 0.5)
                      : AppTheme.dividerColor.withValues(alpha: 0.6),
          width: isTopThree ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isTop1
                ? const Color(0xFFFFD700).withValues(alpha: 0.08)
                : const Color(0xFF04060F).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (user.id != null) {
              Get.to(
                () => const UserProfileScreen(),
                arguments: {
                  'userId': user.id,
                  'heroTag': heroTag,
                  'initialAvatarUrl': user.fullAvatarUrl,
                  'initialUserName': user.fullname ?? user.username,
                },
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // 1. Huy hiệu thứ hạng (Rank Indicator)
                _buildRankBadge(),

                SizedBox(width: 12.w),

                // 2. Avatar
                _buildAvatar(heroTag),

                SizedBox(width: 12.w),

                // 3. Tên và Username
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.fullname ?? user.username ?? 'Người dùng',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.username != null && user.username!.isNotEmpty) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 11.5.sp,
                            color: AppTheme.subTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 5.h),
                      // Badge loại uy tín nhỏ gọn
                      ReputationBadgeWidget(
                        badge: user.badge ?? 'Người dẫn đường',
                        isCompact: true,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // 4. Điểm uy tín
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          size: 16.sp,
                          color: isTop1
                              ? const Color(0xFFFFB300)
                              : AppTheme.primaryColor,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${user.reputationScore ?? 100}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: isTop1
                                ? const Color(0xFFB78103)
                                : AppTheme.textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'reputation_score_unit'.tr,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppTheme.subTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    Color bgColor;
    Color textColor;
    Widget? icon;

    switch (rank) {
      case 1:
        bgColor = const Color(0xFFFFF8E1);
        textColor = const Color(0xFFB78103);
        icon = Icon(Icons.emoji_events_rounded, size: 16.sp, color: textColor);
        break;
      case 2:
        bgColor = const Color(0xFFECEFF1);
        textColor = const Color(0xFF455A64);
        icon = Icon(Icons.workspace_premium_rounded, size: 16.sp, color: textColor);
        break;
      case 3:
        bgColor = const Color(0xFFEFEBE9);
        textColor = const Color(0xFF6D4C41);
        icon = Icon(Icons.military_tech_rounded, size: 16.sp, color: textColor);
        break;
      default:
        bgColor = const Color(0xFFF5F6F8);
        textColor = AppTheme.subTextColor;
        icon = null;
    }

    return Container(
      width: 38.w,
      height: 38.w,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: icon ??
            Text(
              '#$rank',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
      ),
    );
  }

  Widget _buildAvatar(String heroTag) {
    final avatarUrl = user.fullAvatarUrl;

    return Hero(
      tag: heroTag,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.inputFillColor,
                    child: Center(child: LoadingWidget(height: 20.h)),
                  ),
                  errorWidget: (context, url, error) => _buildDefaultAvatar(),
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppTheme.inputFillColor,
      child: Icon(
        IconlyBroken.profile,
        size: 24.sp,
        color: AppTheme.subTextColor,
      ),
    );
  }
}
