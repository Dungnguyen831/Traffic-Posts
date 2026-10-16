import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:traffic_app/theme/app_theme.dart';
import 'package:traffic_app/widgets/custom_text_field.dart';

import '../controllers/camera_controller.dart';
import '../widgets/camera_buttons_row.dart';
import '../widgets/camera_hashtag_section.dart';
import '../widgets/camera_image_section.dart';
import '../widgets/camera_info_chips.dart';

class CameraView extends GetView<CameraController> {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    if (controller.canCreatePost.value) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1E5),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: const Color(0xFFAE5A1E).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: const Color(0xFFAE5A1E),
                            size: 20.sp,
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'reputation_cannot_post_alert'.tr,
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFAE5A1E),
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const CameraImageSection(),
                  const CameraButtonsRow(),
                  CustomTextField(
                    controller: controller.contentController,
                    hintText: 'camera_content_placeholder'.tr,
                    height: 108.h,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                  ),
                  SizedBox(height: 24.h),
                  const CameraHashtagSection(),
                  SizedBox(height: 24.h),
                  const CameraInfoChips(),
                  SizedBox(height: 70.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
