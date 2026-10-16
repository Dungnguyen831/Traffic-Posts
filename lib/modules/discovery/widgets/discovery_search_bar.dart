import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../../routes/app_pages.dart';
import '../../../../theme/app_theme.dart';
import '../../../../widgets/custom_text_field.dart';
import '../../../../widgets/primary_button.dart';
import '../controllers/discovery_controller.dart';

class DiscoverySearchBar extends StatelessWidget {
  const DiscoverySearchBar({required this.controller, super.key});
  final DiscoveryController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 50,
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20.w,
        right: 20.w,
        top: MediaQuery.of(context).padding.top + 10.h,
        bottom: 16.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  IconlyBroken.shield_done,
                  color: AppTheme.primaryColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'traffic_fine_lookup'.tr,
                      style: TextStyle(
                        color: AppTheme.textColor,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'discovery_header_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              InkWell(
                onTap: () => Get.toNamed(Routes.VIOLATION_SUBSCRIPTION),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        IconlyBroken.notification,
                        size: 15.sp,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        'violation_sub_nav_btn'.tr,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Obx(
            () => Row(
              children: [
                _VehicleChip(
                  label: 'discovery_vehicle_car'.tr,
                  icon: Icons.directions_car_rounded,
                  isSelected: controller.selectedVehicle.value == '1',
                  onTap: () => controller.setVehicle('1'),
                ),
                SizedBox(width: 8.w),
                _VehicleChip(
                  label: 'discovery_vehicle_motorcycle'.tr,
                  icon: Icons.two_wheeler_rounded,
                  isSelected: controller.selectedVehicle.value == '2',
                  onTap: () => controller.setVehicle('2'),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  hintText: 'discovery_search_hint'.tr,
                  prefixIcon: IconlyBroken.search,
                  controller: controller.searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => controller.searchFines(),
                  height: 50.h,
                ),
              ),
              SizedBox(width: 10.w),
              Obx(
                () => PrimaryButton(
                  text: 'discovery_search_button'.tr,
                  width: 92.w,
                  height: 50.h,
                  isLoading: controller.isLoading.value,
                  onPressed: controller.searchFines,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected ? Colors.white : AppTheme.subTextColor,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
