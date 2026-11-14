import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../controllers/chatbot_controller.dart';

class SuggestionChips extends StatelessWidget {
  final ChatbotController controller;
  const SuggestionChips({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final askedTexts = controller.messages
        .where((m) => m.isUser)
        .map((m) => m.text.trim())
        .toSet();
    final remaining = controller.suggestions
        .where((s) => !askedTexts.contains(s.tr.trim()))
        .toList();
    final displayList = remaining.isNotEmpty
        ? remaining
        : controller.suggestions;

    return Padding(
      padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 44.w, bottom: 8.h),
            child: Text(
              'chatbot_quick_ask'.tr,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.subTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 44.w),
            child: Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: displayList.map((s) {
                return GestureDetector(
                  onTap: () => controller.sendMessage(s.tr),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      s.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
