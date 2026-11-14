import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../controllers/camera_controller.dart';

class CameraInfoChips extends GetView<CameraController> {
  const CameraInfoChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChip(
            icon: IconlyBold.time_circle,
            text: "${'camera_time_label'.tr} ${controller.time.value}",
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: controller.isLoadingLocation.value
                ? null
                : () => controller.refreshLocationAndTime(),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildChip(
                    icon: IconlyBold.location,
                    text:
                        "${'camera_location_label'.tr} ${controller.location.value}",
                  ),
                ),
                SizedBox(width: 8.w),
                if (controller.isLoadingLocation.value)
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  Icon(
                    Icons.refresh_rounded,
                    color: AppTheme.primaryColor,
                    size: 18.sp,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.subTextColor, size: 16.sp),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.subTextColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
