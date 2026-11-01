import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../controllers/dashboard_controller.dart';

class DashboardFilterBar extends StatelessWidget {
  const DashboardFilterBar({super.key});

  static const List<Map<String, dynamic>> _presetHashtags = [
    {
      'tag': 'ketxe',
      'labelKey': 'hashtag_label_ketxe',
      'icon': Icons.traffic_rounded,
      'color': Color(0xFFE53935),
    },
    {
      'tag': 'tainan',
      'labelKey': 'hashtag_label_tainan',
      'icon': Icons.warning_amber_rounded,
      'color': Color(0xFFF57C00),
    },
    {
      'tag': 'ngaplutnuoc',
      'labelKey': 'hashtag_label_ngaplutnuoc',
      'icon': Icons.water_drop_rounded,
      'color': Color(0xFF00ACC1),
    },
    {
      'tag': 'baocaotainan',
      'labelKey': 'hashtag_label_baocaotainan',
      'icon': Icons.campaign_rounded,
      'color': Color(0xFF8E24AA),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Obx(() {
      final hasFilters = controller.hasActiveFilters;
      final filterCount = controller.activeFilterCount;
      final isNearby = controller.isNearbyEnabled.value;
      final radiusKm = controller.nearbyRadiusKm.value;
      final activeTag = controller.selectedHashtag.value;
      final isFollowing = controller.onlyFollowing.value;
      final isFetchingLoc = controller.isFetchingLocation.value;

      final isCustomTag = activeTag != null &&
          !_presetHashtags.any((item) => item['tag'] == activeTag);

      return SizedBox(
        height: 36.h,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          children: [
            // 1. Nút mở Bottom Sheet Bộ lọc & Sắp xếp nâng cao
            _FilterSettingsButton(
              activeCount: filterCount,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.openFilterBottomSheet();
              },
            ),
            SizedBox(width: 8.w),

            // 2. Chip "Tất cả"
            _QuickFilterChip(
              label: 'dashboard_filter_all'.tr,
              isSelected: !hasFilters,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.resetAllFilters();
              },
            ),
            SizedBox(width: 8.w),

            // 3. Chip "Gần tôi" (kèm bán kính km khi bật)
            _QuickFilterChip(
              label: isNearby
                  ? '${'dashboard_filter_nearby'.tr} (< ${radiusKm.toInt()}km)'
                  : 'dashboard_filter_nearby'.tr,
              icon: isFetchingLoc
                  ? Icons.my_location_rounded
                  : IconlyBold.location,
              isSelected: isNearby,
              activeColor: const Color(0xFF2E7D32),
              activeBgColor: const Color(0xFFE8F5E9),
              onTap: () {
                HapticFeedback.selectionClick();
                controller.toggleNearbyFilter();
              },
            ),
            SizedBox(width: 8.w),

            // 4. Nếu người dùng bấm vào 1 hashtag tùy chỉnh trên bài viết, hiển thị chip đó
            if (isCustomTag) ...[
              _QuickFilterChip(
                label: '#$activeTag',
                isSelected: true,
                onTap: () {
                  HapticFeedback.selectionClick();
                  controller.toggleHashtagFilter(activeTag);
                },
              ),
              SizedBox(width: 8.w),
            ],

            // 5. Các Chip loại sự cố phổ biến (#ketxe, #tainan, #ngaplutnuoc, #baocaotainan)
            ..._presetHashtags.map((item) {
              final tag = item['tag'] as String;
              final labelKey = item['labelKey'] as String;
              final icon = item['icon'] as IconData;
              final color = item['color'] as Color;
              final selected = activeTag == tag;

              return Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: _QuickFilterChip(
                  label: labelKey.tr,
                  icon: icon,
                  iconColor: selected ? Colors.white : color,
                  isSelected: selected,
                  activeColor: color,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.toggleHashtagFilter(tag);
                  },
                ),
              );
            }),

            // 6. Chip "Đang theo dõi"
            _QuickFilterChip(
              label: 'dashboard_filter_following'.tr,
              icon: Icons.people_alt_rounded,
              isSelected: isFollowing,
              onTap: () {
                HapticFeedback.selectionClick();
                controller.toggleFollowingFilter();
              },
            ),
          ],
        ),
      );
    });
  }
}

class _FilterSettingsButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterSettingsButton({
    required this.activeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 11.w),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryBgColor : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16.sp,
              color: isActive ? AppTheme.primaryColor : const Color(0xFF4B5563),
            ),
            if (isActive) ...[
              SizedBox(width: 5.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  '$activeCount',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final Color? activeColor;
  final Color? activeBgColor;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    this.activeColor,
    this.activeBgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveActiveColor = activeColor ?? AppTheme.primaryColor;
    final bgColor = isSelected
        ? (activeBgColor ?? effectiveActiveColor)
        : const Color(0xFFF5F6FA);
    final textColor = isSelected
        ? (activeBgColor != null ? effectiveActiveColor : Colors.white)
        : const Color(0xFF4B5563);
    final effectiveIconColor = iconColor ??
        (isSelected
            ? (activeBgColor != null ? effectiveActiveColor : Colors.white)
            : const Color(0xFF6B7280));

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? effectiveActiveColor
                : const Color(0xFFE5E7EB),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14.sp, color: effectiveIconColor),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

