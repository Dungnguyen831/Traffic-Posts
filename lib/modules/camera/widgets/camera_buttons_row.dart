import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../controllers/camera_controller.dart';

class CameraButtonsRow extends GetView<CameraController> {
  const CameraButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hasImg = controller.hasImage.value;
      final status = controller.moderationStatus.value;

      return SizedBox(
        width: double.infinity,
        height: 120.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Nút hành động chính hoặc thông báo trạng thái kiểm duyệt
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: _buildCenterContent(hasImg, status),
            ),

            // X button – only visible when an image has been captured/picked
            if (hasImg)
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: controller.clearImage,
                  child: Container(
                    width: 44.w,
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.15),
                          blurRadius: 12.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      IconlyBroken.close_square,
                      color: AppTheme.primaryColor,
                      size: 22.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildCenterContent(bool hasImg, ImageModerationStatus status) {
    // 1. Chưa có ảnh -> Hiện nút chụp ảnh (big_camera.svg)
    if (!hasImg) {
      return GestureDetector(
        key: const ValueKey('btn_camera'),
        onTap: controller.onActionTap,
        child: Opacity(
          opacity: controller.canCreatePost.value ? 1.0 : 0.6,
          child: SvgPicture.asset('assets/icons/big_camera.svg'),
        ),
      );
    }

    // 2. Có ảnh và đã kiểm duyệt hợp lệ (label == 1) -> Hiện nút đăng bài (big_send.svg)
    if (status == ImageModerationStatus.valid) {
      return GestureDetector(
        key: const ValueKey('btn_send'),
        onTap: controller.onActionTap,
        child: Opacity(
          opacity: controller.canCreatePost.value ? 1.0 : 0.6,
          child: SvgPicture.asset('assets/icons/big_send.svg'),
        ),
      );
    }

    // 3. Đang kiểm duyệt ảnh -> Ẩn nút đăng bài, hiển thị trạng thái chờ kiểm duyệt
    if (status == ImageModerationStatus.checking) {
      return Container(
        key: const ValueKey('status_checking'),
        margin: EdgeInsets.only(right: 56.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryBgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16.w,
              height: 16.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                'camera_moderating_image'.tr,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Ảnh không hợp lệ (label == 0) -> Ẩn nút đăng bài kèm thông báo không hợp lệ
    if (status == ImageModerationStatus.invalid) {
      return Container(
        key: const ValueKey('status_invalid'),
        margin: EdgeInsets.only(right: 56.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppTheme.errorAlertBgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: AppTheme.errorColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              IconlyBold.danger,
              color: AppTheme.errorAlertIconColor,
              size: 20.sp,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'camera_image_invalid_alert'.tr,
                style: TextStyle(
                  color: AppTheme.errorAlertTextColor,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 5. Lỗi mạng khi kiểm duyệt -> Ẩn nút đăng bài, cho phép chạm để thử kiểm tra lại
    if (status == ImageModerationStatus.error) {
      return GestureDetector(
        key: const ValueKey('status_error'),
        onTap: controller.validateSelectedImage,
        child: Container(
          margin: EdgeInsets.only(right: 56.w),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppTheme.warningAlertBgColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: AppTheme.warningColor.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                IconlyBold.danger,
                color: AppTheme.warningColor,
                size: 20.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'camera_image_moderation_error'.tr,
                  style: TextStyle(
                    color: AppTheme.warningAlertTextColor,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink(key: ValueKey('status_none'));
  }
}
