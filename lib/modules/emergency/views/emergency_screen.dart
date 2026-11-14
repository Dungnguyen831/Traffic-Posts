import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/emergency_controller.dart';
import '../../../widgets/app_button.dart';

class EmergencyScreen extends GetView<EmergencyController> {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(IconlyBroken.arrow_left, color: AppTheme.textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'emergency_title_1'.tr,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            Text(
              'emergency_title_2'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textColor,
              ),
            ),
            SizedBox(height: 16.h),

            // Option 1: Gọi người thân
            Obx(
              () => _buildOptionCard(
                index: 0,
                icon: IconlyBroken.call,
                title: 'emergency_method_1'.tr,
                subtitle: 'emergency_hint'.tr,
                isSelected: controller.selectedOption.value == 0,
              ),
            ),

            SizedBox(height: 16.h),

            // Option 2: Gọi cứu thương
            Obx(() => _buildOptionCard(
                  index: 1,
                  icon: Icons.medical_services_outlined,
                  title: 'emergency_method_2'.tr,
                  isSelected: controller.selectedOption.value == 1,
                )),

            SizedBox(height: 16.h),

            // Option 3: Cầu cứu sự trợ giúp từ cộng đồng (tùy chọn, có thể thêm sau nếu cần)
            Obx(() => _buildOptionCard(
                  index: 2,
                  icon: Icons.group_outlined,
                  title: 'emergency_method_3'.tr,
                  subtitle: 'emergency_hint_3'.tr,
                  isSelected: controller.selectedOption.value == 2,
                )),
          ],
        ),
      ),

      // Nút Tiếp tục được ghìm ở đáy màn hình
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: PrimaryButton(
            text: 'emergency_button'.tr,
            onPressed: () {
              if (controller.selectedOption.value == 2) {
                _showSosInputDialog();
              } else {
                CustomDialog.showConfirm(
                  context: context,
                  title: 'emergency_title_1'.tr,
                  message: controller.selectedOption.value == 0
                      ? 'emergency_hint'.tr
                      : 'emergency_call_115_confirm'.tr,
                  confirmText: 'emergency_button'.tr,
                  cancelText: 'cancel'.tr,
                  type: DialogType.warning,
                  onConfirm: controller.onContinue,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required int index,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => controller.selectOption(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon, size: 28.sp, color: AppTheme.subTextColor),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.dividerColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // Hàm hiển thị Popup nhập ghi chú 
  void _showSosInputDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
        backgroundColor: AppTheme.backgroundColor, 
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'emergency_incident_details'.tr,
                style: TextStyle(
                  fontSize: 20.sp, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.errorColor, 
                ),
              ),
              SizedBox(height: 16.h),
              
              // Ô nhập nội dung
              TextField(
                controller: controller.noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'emergency_incident_hint'.tr,
                  hintStyle: TextStyle(color: AppTheme.subTextColor), 
                  filled: true,
                  fillColor: AppTheme.inputFillColor, 
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: BorderSide.none, 
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.r),
                    borderSide: const BorderSide(color: AppTheme.errorColor), 
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: 'cancel'.tr,
                      type: ButtonType.secondary, 
                      onPressed: () {
                        // Vẫn chặn không cho Hủy nếu đang gửi dữ liệu
                        if (!controller.isLoading.value) Get.back();
                      },
                    ),
                  ),
                  SizedBox(width: 12.w), // Khoảng cách giữa 2 nút
                  
                  Expanded(
                    child: Obx(() => AppButton(
                      text: 'emergency_send_sos_button'.tr,
                      type: ButtonType.primary,
                      isLoading: controller.isLoading.value, 
                      onPressed: () => controller.sendSosAlert(),
                    )),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
