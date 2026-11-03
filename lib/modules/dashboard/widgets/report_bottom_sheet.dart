import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/app_button.dart';

class ReportBottomSheet extends StatefulWidget {
  final Future<void> Function(String) onReport;

  const ReportBottomSheet({super.key, required this.onReport});

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  String _selectedReasonKey = "";
  bool _isLoading = false;
  final List<String> _reasonKeys = [
    "report_reason_fake_news",
    "report_reason_inappropriate_media",
    "report_reason_offensive_language",
    "report_reason_other",
  ];

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
            "report_title".tr,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF212121),
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 20.h),
          // Reasons List
          ..._reasonKeys.map((reasonKey) => _buildReasonItem(reasonKey)),
          SizedBox(height: 12.h),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: 20.h),
          // Buttons
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: "cancel".tr,
                  onPressed: () => Get.back(),
                  type: ButtonType.secondary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: AppButton(
                  text: "send".tr,
                  isLoading: _isLoading,
                  onPressed: () async {
                    if (_selectedReasonKey.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      await widget.onReport(_selectedReasonKey.tr);
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  type: _isLoading ? ButtonType.secondary : ButtonType.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReasonItem(String reasonKey) {
    final isSelected = _selectedReasonKey == reasonKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReasonKey = reasonKey;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13.r),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 1)
              : Border.all(color: Colors.white, width: 1),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF04060F).withOpacity(0.05),
                    offset: const Offset(0, 4),
                    blurRadius: 60,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 20.w,
              height: 20.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : const Color(0xFFE0E0E0),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            SizedBox(width: 24.w),
            Text(
              reasonKey.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF616161),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
