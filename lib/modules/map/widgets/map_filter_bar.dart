import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/hashtag_helper.dart';
import '../../../widgets/app_glass_container.dart';
import '../controllers/map_controller.dart';

class MapFilterBar extends StatelessWidget {
  const MapFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MapController>();

    return Obx(() {
      final hasActiveFilters = controller.hasActiveFilters;
      final activeCount = controller.activeFilterCount;
      final timeFilter = controller.selectedTimeFilter.value;
      final activeTag = controller.selectedTag.value;
      final activeRadius = controller.selectedRadiusKm.value;

      return SizedBox(
        height: 38.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          children: [
            // 1. Nút mở BottomSheet tổng hợp với hiệu ứng Glass
            _buildGlassButton(
              isSelected: hasActiveFilters,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.openFilterBottomSheet();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16.r,
                    color: hasActiveFilters
                        ? AppTheme.primaryColor
                        : AppTheme.textColor,
                  ),
                  if (activeCount > 0) ...[
                    SizedBox(width: 5.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 1.5.h,
                      ),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeCount',
                        style: TextStyle(
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),

            // 2. Chip Thời gian (Tất cả / 1h / 5h / 1 ngày)
            _buildGlassDropdownChip(
              icon: Icons.schedule_rounded,
              label: _getTimeFilterLabel(timeFilter),
              isSelected: timeFilter != MapTimeFilter.all,
              onTap: () => _showTimeMenu(context, controller),
            ),
            SizedBox(width: 8.w),

            // 3. Chip Tag / Loại sự cố
            _buildGlassDropdownChip(
              icon: IconlyBroken.category,
              label: activeTag != null
                  ? HashtagHelper.getLabel(activeTag)
                  : 'map_filter_tag'.tr,
              isSelected: activeTag != null,
              onTap: () => _showTagMenu(context, controller),
            ),
            SizedBox(width: 8.w),

            // 4. Chip Bán kính quanh vị trí
            _buildGlassDropdownChip(
              icon: IconlyBroken.location,
              label: activeRadius != null
                  ? '< ${activeRadius.toInt()} km'
                  : 'map_filter_radius'.tr,
              isSelected: activeRadius != null,
              onTap: () => _showRadiusMenu(context, controller),
            ),

            // 5. Nút Đặt lại nhanh (Chỉ hiện khi có bộ lọc hoạt động)
            if (hasActiveFilters) ...[
              SizedBox(width: 8.w),
              _buildGlassButton(
                isSelected: false,
                isReset: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.resetAllFilters();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.close_rounded,
                      size: 14.r,
                      color: AppTheme.subTextColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'map_filter_reset'.tr,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _getTimeFilterLabel(MapTimeFilter filter) {
    switch (filter) {
      case MapTimeFilter.all:
        return 'map_filter_time'.tr;
      case MapTimeFilter.last1Hour:
        return 'map_filter_time_1h'.tr;
      case MapTimeFilter.last5Hours:
        return 'map_filter_time_5h'.tr;
      case MapTimeFilter.last1Day:
        return 'map_filter_time_1d'.tr;
    }
  }

  Widget _buildGlassButton({
    required Widget child,
    required bool isSelected,
    bool isReset = false,
    required VoidCallback onTap,
  }) {
    return AppGlassContainer(
      borderRadius: 20.r,
      glassColor: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.60),
      borderSide: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.85),
        width: isSelected ? 1.2 : 0.8,
      ),
      gradientColors: [
        isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.82),
        isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.64),
      ],
      boxShadow: [
        BoxShadow(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildGlassDropdownChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppGlassContainer(
      borderRadius: 20.r,
      glassColor: isSelected
          ? AppTheme.primaryColor.withValues(alpha: 0.16)
          : Colors.white.withValues(alpha: 0.60),
      borderSide: BorderSide(
        color: isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.85),
        width: isSelected ? 1.2 : 0.8,
      ),
      gradientColors: [
        isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.82),
        isSelected
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.64),
      ],
      boxShadow: [
        BoxShadow(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.5.r,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.subTextColor,
              ),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textColor,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 15.r,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.subTextColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Khung hiển thị modal menu chọn nhanh dùng chung (loại bỏ code trùng lặp)
  void _showQuickSelectSheet({
    required String title,
    required List<Widget> items,
  }) {
    HapticFeedback.selectionClick();
    Get.bottomSheet(
      AppGlassContainer(
        borderRadius: 24.r,
        glassColor: Colors.white.withValues(alpha: 0.70),
        gradientColors: [
          Colors.white.withValues(alpha: 0.94),
          Colors.white.withValues(alpha: 0.84),
        ],
        padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textColor,
                ),
              ),
              SizedBox(height: 10.h),
              ...items,
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  void _showTimeMenu(BuildContext context, MapController controller) {
    const timeOptions = [
      (MapTimeFilter.all, 'map_filter_time_all'),
      (MapTimeFilter.last1Hour, 'map_filter_time_1h'),
      (MapTimeFilter.last5Hours, 'map_filter_time_5h'),
      (MapTimeFilter.last1Day, 'map_filter_time_1d'),
    ];

    _showQuickSelectSheet(
      title: 'map_filter_time'.tr,
      items: timeOptions.map((item) {
        final isSelected = controller.selectedTimeFilter.value == item.$1;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            Icons.schedule_rounded,
            color: isSelected ? AppTheme.primaryColor : AppTheme.subTextColor,
          ),
          title: Text(
            item.$2.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
              : null,
          onTap: () {
            HapticFeedback.selectionClick();
            controller.setTimeFilter(item.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  void _showTagMenu(BuildContext context, MapController controller) {
    _showQuickSelectSheet(
      title: 'map_filter_tag'.tr,
      items: MapController.filterTagOptions.map((opt) {
        final canonicalOption = opt.tag != null
            ? HashtagHelper.toCanonical(opt.tag!)
            : null;
        final isSelected = controller.selectedTag.value == canonicalOption;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            opt.icon,
            color: isSelected ? opt.color : AppTheme.subTextColor,
          ),
          title: Text(
            opt.tag != null
                ? HashtagHelper.getLabel(opt.tag!)
                : opt.labelKey.tr,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? opt.color : AppTheme.textColor,
            ),
          ),
          trailing: isSelected
              ? Icon(Icons.check_rounded, color: opt.color)
              : null,
          onTap: () {
            HapticFeedback.selectionClick();
            controller.setTagFilter(canonicalOption);
            Get.back();
          },
        );
      }).toList(),
    );
  }

  void _showRadiusMenu(BuildContext context, MapController controller) {
    final radii = [
      (null, 'map_filter_radius_all'.tr),
      ...MapController.availableRadiiKm.map((r) => (r, '< ${r.toInt()} km')),
    ];

    _showQuickSelectSheet(
      title: 'map_filter_radius'.tr,
      items: radii.map((item) {
        final isSelected = controller.selectedRadiusKm.value == item.$1;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            IconlyBroken.location,
            color: isSelected ? AppTheme.primaryColor : AppTheme.subTextColor,
          ),
          title: Text(
            item.$2,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textColor,
            ),
          ),
          trailing: isSelected
              ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
              : null,
          onTap: () {
            HapticFeedback.selectionClick();
            controller.setRadiusFilter(item.$1);
            Get.back();
          },
        );
      }).toList(),
    );
  }
}
