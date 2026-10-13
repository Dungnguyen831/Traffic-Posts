import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../../../config/demo_config.dart';
import '../controllers/camera_controller.dart';

class CameraButtonsRow extends GetView<CameraController> {
  const CameraButtonsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return SizedBox(
        width: double.infinity,
        height: 120.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Quick Demo sample image button for Web Demo
            if (!controller.hasImage.value && DemoConfig.isDemoMode)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.selectDemoSampleImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                  label: const Text(
                    'Ảnh mẫu demo',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                  ),
                ),
              ),
            // Camera / Send icon (centered)
            GestureDetector(
              onTap: controller.onActionTap,
              child: SvgPicture.asset(
                controller.hasImage.value
                    ? 'assets/icons/big_send.svg'
                    : 'assets/icons/big_camera.svg',
              ),
            ),
            // X button – only visible when an image has been captured/picked
            if (controller.hasImage.value)
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
                          color: AppTheme.primaryColor.withOpacity(0.15),
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
}
