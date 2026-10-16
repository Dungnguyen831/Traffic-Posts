import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/models/sos_model.dart'; 
import '../../../theme/app_theme.dart'; 
import '../../../widgets/app_button.dart'; 
import '../../../widgets/custom_alert.dart'; 

class SosBottomSheet {
  static void show({required SosResponseDTO sos}) {
    // Xử lý thời gian (Lấy giờ và phút từ timestamp)
    String timeString = '';
    if (sos.timestamp != null) {
      final localTime = sos.timestamp!.toLocal();
      timeString = '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
    }

    Get.bottomSheet(
      ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFFECECEC).withOpacity(0.88),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28.r),
                topRight: Radius.circular(28.r),
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.7),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 28,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo nhỏ (Drag handle) ở trên cùng
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor, 
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),

              // Header: Icon + Tiêu đề + Thời gian
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBgColor, 
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emergency, color: AppTheme.errorColor, size: 28.sp), 
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Tín hiệu SOS',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor, 
                      ),
                    ),
                  ),
                  if (timeString.isNotEmpty)
                    Text(
                      timeString,
                      style: TextStyle(fontSize: 14.sp, color: AppTheme.subTextColor), 
                    ),
                ],
              ),
              SizedBox(height: 16.h),

              // Nội dung sự cố (Note)
              Text(
                (sos.note != null && sos.note!.isNotEmpty)
                    ? sos.note!
                    : 'Cần hỗ trợ khẩn cấp!',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textColor, 
                ),
              ),
              SizedBox(height: 16.h),

              // Số điện thoại
              Row(
                children: [
                  Icon(Icons.phone, size: 20.sp, color: AppTheme.subTextColor), 
                  SizedBox(width: 8.w),
                  Text(
                    (sos.phoneNumber != null && sos.phoneNumber!.isNotEmpty)
                        ? sos.phoneNumber!
                        : 'Không có số điện thoại',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AppTheme.textColor, 
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),

              // Hai Nút: Đóng và Gọi hỗ trợ
              Row(
                children: [
                  // Nút Đóng (Dùng AppButton type secondary)
                  Expanded(
                    child: AppButton(
                      text: 'Đóng',
                      type: ButtonType.secondary, 
                      onPressed: () => Get.back(),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  
                  // Nút Gọi hỗ trợ (Dùng AppButton type primary kèm icon)
                  Expanded(
                    flex: 2,
                    child: AppButton(
                      text: 'Gọi hỗ trợ',
                      icon: Icons.call, 
                      type: ButtonType.primary, 
                      onPressed: () async {
                        if (sos.phoneNumber != null && sos.phoneNumber!.isNotEmpty) {
                          final Uri launchUri = Uri(
                            scheme: 'tel',
                            path: sos.phoneNumber,
                          );
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri, mode: LaunchMode.externalApplication);
                          } else {
                            CustomAlert.showError('Không thể mở trình gọi điện trên thiết bị này'); 
                          }
                        } else {
                          CustomAlert.showWarning('Người này không cung cấp số điện thoại!'); 
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
            ],
          ),
        ),
      ),
    ),
  ),
  isScrollControlled: true,
  backgroundColor: Colors.transparent, 
);
  }
}