import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../routes/app_pages.dart';
import '../theme/app_theme.dart';

class ReputationBadgeStyle {
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const ReputationBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  static ReputationBadgeStyle getStyle(String? badgeName) {
    switch (badgeName?.trim()) {
      case 'Cần xây dựng':
        return const ReputationBadgeStyle(
          backgroundColor: Color(0xFFFFF1E5),
          textColor: Color(0xFFAE5A1E),
          icon: Icons.shield_outlined,
        );
      case 'Đáng tin cậy':
        return const ReputationBadgeStyle(
          backgroundColor: Color(0xFFEAF4FB),
          textColor: Color(0xFF276A9E),
          icon: Icons.verified_user_rounded,
        );
      case 'Người dẫn đường':
      default:
        return const ReputationBadgeStyle(
          backgroundColor: Color(0xFFE9F7F1),
          textColor: Color(0xFF16734E),
          icon: Icons.stars_rounded,
        );
    }
  }
}

class ReputationBadgeWidget extends StatelessWidget {
  final String badge;
  final int? score;
  final bool isCompact;
  final bool showScore;
  final bool? canCreatePost;
  final VoidCallback? onViewRanking;

  const ReputationBadgeWidget({
    super.key,
    required this.badge,
    this.score,
    this.isCompact = true,
    this.showScore = false,
    this.canCreatePost,
    this.onViewRanking,
  });

  @override
  Widget build(BuildContext context) {
    final style = ReputationBadgeStyle.getStyle(badge);

    if (isCompact) {
      return _buildCompact(style);
    }
    return _buildCard(context, style);
  }

  /// Huy hiệu nhỏ gọn hiển thị cạnh tên tác giả hoặc trong danh sách
  Widget _buildCompact(ReputationBadgeStyle style) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(
          color: style.textColor.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            style.icon,
            size: 11.sp,
            color: style.textColor,
          ),
          SizedBox(width: 4.w),
          Text(
            badge,
            style: TextStyle(
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
              color: style.textColor,
            ),
          ),
          if (showScore && score != null) ...[
            SizedBox(width: 4.w),
            Container(
              width: 3.r,
              height: 3.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: style.textColor.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(width: 4.w),
            Text(
              '$score pts',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                color: style.textColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Card uy tín chi tiết hiển thị trong trang Profile cá nhân
  Widget _buildCard(BuildContext context, ReputationBadgeStyle style) {
    final effectiveScore = score ?? 100;
    final isAllowedToPost = canCreatePost ?? (effectiveScore >= 80);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: style.textColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon huy hiệu lớn
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: style.backgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: style.textColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    style.icon,
                    size: 22.sp,
                    color: style.textColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Tên huy hiệu + điểm số
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: style.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: style.backgroundColor,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            'reputation_badge_tag'.tr,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: style.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Text(
                          '$effectiveScore',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          'reputation_score_unit'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.subTextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Nút xem bảng xếp hạng
              InkWell(
                onTap: onViewRanking ?? () => Get.toNamed(Routes.RANKING),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyBroken.chart,
                        size: 15.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'reputation_ranking_btn'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),
          Divider(
            height: 1,
            color: AppTheme.dividerColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 10.h),

          // Trạng thái quyền đăng bài
          Row(
            children: [
              Icon(
                isAllowedToPost
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 16.sp,
                color: isAllowedToPost
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  isAllowedToPost
                      ? 'reputation_can_post_desc'.tr
                      : 'reputation_cannot_post_desc'.tr,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: isAllowedToPost
                        ? AppTheme.textColor
                        : AppTheme.errorColor,
                    fontWeight: isAllowedToPost ? FontWeight.w500 : FontWeight.w600,
                    height: 1.3,
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
