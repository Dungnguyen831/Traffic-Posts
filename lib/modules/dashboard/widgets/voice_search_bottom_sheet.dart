import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_button.dart';
import '../controllers/dashboard_controller.dart';

class VoiceSearchBottomSheet extends GetView<DashboardController> {
  const VoiceSearchBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40.r),
          topRight: Radius.circular(40.r),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 48.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 38.w,
            height: 3.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          SizedBox(height: 24.h),
          // Title
          Text(
            "voice_search_title".tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),

          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 40.h),

          // Microphone UI
          Obx(() {
            final isListening = controller.isListening.value;
            return GestureDetector(
              onTap: () {
                if (isListening) {
                  controller.stopVoiceSearch();
                } else {
                  controller.startListening();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Vòng mờ lan tỏa bên ngoài khi đang thu âm
                  color: isListening
                      ? AppTheme.primaryColor.withOpacity(0.15)
                      : Colors.transparent,
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Khi đang nghe dùng màu chủ đạo, khi tắt dùng màu nền nhạt
                      color: isListening
                          ? AppTheme.primaryColor
                          : const Color(0xFFF5F5F5),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isListening ? Icons.mic : Icons.mic_none,
                      // Đổi màu icon tương phản với nền
                      color: isListening ? Colors.white : AppTheme.primaryColor,
                      size: 40.sp,
                    ),
                  ),
                ),
              ),
            );
          }),

          SizedBox(height: 24.h),

          // Text status
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Obx(() {
              final text = controller.recognizedText.value;
              final isListening = controller.isListening.value;

              return Text(
                text.isEmpty
                    ? (isListening
                          ? "voice_search_listening".tr
                          : "voice_search_hint".tr)
                    : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  // Chữ nháp thì dùng màu xám, chữ thật thì dùng màu đen
                  color: text.isEmpty
                      ? const Color(0xFF9E9E9E)
                      : const Color(0xFF212121),
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              );
            }),
          ),

          SizedBox(height: 40.h),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 20.h),

          // Button Close
          AppButton(
            text: "close_button".tr,
            onPressed: () {
              if (controller.isListening.value) {
                controller.stopVoiceSearch(closeSheet: false);
              }
              Get.back();
            },
            type: ButtonType.secondary,
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}
