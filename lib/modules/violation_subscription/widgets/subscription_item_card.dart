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

  const SubscriptionItemCard({
    super.key,
    required this.item,
    required this.onToggleEnabled,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
              // Badge biển kiểm soát
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

              // Tag trạng thái (Đang theo dõi / Đã tạm dừng)
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
