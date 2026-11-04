import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../controllers/camera_controller.dart';
import '../../../utils/hashtag_helper.dart';

class CameraHashtagSection extends GetView<CameraController> {
  const CameraHashtagSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Obx(
        () => Row(
          children: controller.availableHashtags.map((tag) {
            final selected = controller.selectedHashtags.contains(tag);
            return GestureDetector(
              onTap: () => controller.toggleHashtag(tag),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.r),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.tag_rounded,
                      size: 20.sp,
                      color: selected ? Colors.white : AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Text(HashtagHelper.getLabel(tag),
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.primaryColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
