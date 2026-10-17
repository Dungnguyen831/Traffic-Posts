import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../data/models/violation_subscription_model.dart';
import '../../../theme/app_theme.dart';

class SubscriptionItemCard extends StatelessWidget {
  final ViolationSubscription item;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onDelete;
  final VoidCallback? onChangePlate;
  final bool isFeatured;

  const SubscriptionItemCard({
    super.key,
    required this.item,
    required this.onToggleEnabled,
    required this.onDelete,
    this.onChangePlate,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFeatured) {
      return _buildFeaturedCard(context);
    }
    return _buildCompactCard(context);
  }

  /// Card lớn hiển thị biển số xe duy nhất đang theo dõi
  Widget _buildFeaturedCard(BuildContext context) {
    final isEnabled = item.enabled;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.dividerColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.06),
            offset: const Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Icon + Tiêu đề + Tag trạng thái
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  IconlyBold.shield_done,
                  color: AppTheme.primaryColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'violation_sub_registered_card_title'.tr,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'violation_sub_single_rule'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? AppTheme.successColor.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.r,
                      height: 6.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isEnabled
                            ? AppTheme.successColor
                            : Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isEnabled
                          ? 'violation_sub_status_active'.tr
                          : 'violation_sub_status_inactive'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? AppTheme.successColor
                            : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),

          // 2. Biển số xe thiết kế nổi bật (Vietnamese License Plate Style)
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFBFBFC),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF1E293B),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5.w,
                    height: 26.h,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Text(
                    item.formattedPlate,
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18.h),

          // 3. Khối tùy chọn nhận thông báo
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppTheme.dividerColor.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  IconlyBroken.notification,
                  size: 20.sp,
                  color: isEnabled ? AppTheme.primaryColor : AppTheme.subTextColor,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'violation_sub_notify_toggle'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'violation_sub_notify_desc'.tr,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.subTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: isEnabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: onToggleEnabled,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // 4. Các nút hành động: Đổi biển số & Hủy theo dõi
          Row(
            children: [
              if (onChangePlate != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChangePlate,
                    icon: Icon(
                      IconlyBroken.edit,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    label: Text(
                      'violation_sub_change_plate_btn'.tr,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      side: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      backgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
              ],
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: Icon(
                    IconlyBroken.delete,
                    size: 16.sp,
                    color: AppTheme.errorColor,
                  ),
                  label: Text(
                    'violation_sub_delete_confirm_title'.tr,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    side: BorderSide(
                      color: AppTheme.errorColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    backgroundColor:
                        AppTheme.errorColor.withValues(alpha: 0.04),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card thu gọn cho danh sách cũ khi còn nhiều biển số
  Widget _buildCompactCard(BuildContext context) {
    final isEnabled = item.enabled;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isEnabled
              ? AppTheme.primaryColor.withValues(alpha: 0.25)
              : AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.04),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hàng trên: Biển số xe + Tag trạng thái + Nút Xóa
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFF2B2D42),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      offset: const Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      item.formattedPlate,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10.w),

              // Tag trạng thái
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? AppTheme.successColor.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6.r,
                        height: 6.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isEnabled
                              ? AppTheme.successColor
                              : Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          isEnabled
                              ? 'violation_sub_status_active'.tr
                              : 'violation_sub_status_inactive'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? AppTheme.successColor
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Nút xóa
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8.r),
                child: Padding(
                  padding: EdgeInsets.all(6.r),
                  child: Icon(
                    IconlyBroken.delete,
                    color: AppTheme.errorColor,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10.h),
          Divider(
            height: 1,
            color: AppTheme.dividerColor.withValues(alpha: 0.5),
          ),
          SizedBox(height: 10.h),

          // 2. Hàng dưới: Tùy chọn thông báo + Switch
          Row(
            children: [
              Icon(
                IconlyBroken.notification,
                size: 17.sp,
                color: isEnabled ? AppTheme.primaryColor : AppTheme.subTextColor,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  isEnabled
                      ? 'violation_sub_notify_toggle'.tr
                      : 'violation_sub_status_inactive'.tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isEnabled ? AppTheme.textColor : AppTheme.subTextColor,
                    fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Transform.scale(
                scale: 0.85,
                child: Switch.adaptive(
                  value: isEnabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: onToggleEnabled,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
