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
      return SizedBox(
        width: double.infinity,
        height: 120.h,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Camera / Send icon (centered)
            GestureDetector(
              onTap: controller.onActionTap,
              child: Opacity(
                opacity: controller.canCreatePost.value ? 1.0 : 0.6,
                child: SvgPicture.asset(
                  controller.hasImage.value
                      ? 'assets/icons/big_send.svg'
                      : 'assets/icons/big_camera.svg',
                ),
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
