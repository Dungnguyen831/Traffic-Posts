import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/hashtag_helper.dart';
import '../../../widgets/app_glass_container.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/map_controller.dart';

class MapFilterBottomSheet extends StatefulWidget {
  const MapFilterBottomSheet({super.key});

  @override
  State<MapFilterBottomSheet> createState() => _MapFilterBottomSheetState();
}

class _MapFilterBottomSheetState extends State<MapFilterBottomSheet> {
  final MapController _controller = Get.find<MapController>();

  late MapTimeFilter _timeFilter;
  late String? _tag;
  late double? _radiusKm;

  @override
  void initState() {
    super.initState();
    _timeFilter = _controller.selectedTimeFilter.value;
    _tag = _controller.selectedTag.value;
    _radiusKm = _controller.selectedRadiusKm.value;
  }

  void _resetLocal() {
    HapticFeedback.mediumImpact();
    setState(() {
      _timeFilter = MapTimeFilter.all;
      _tag = null;
      _radiusKm = null;
    });
  }

  Future<void> _apply() async {
    HapticFeedback.lightImpact();
    Get.back();
    await _controller.applyAdvancedFilters(
      timeFilter: _timeFilter,
      tag: _tag,
      radiusKm: _radiusKm,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppGlassContainer(
      borderRadius: 28.r,
      glassColor: Colors.white.withValues(alpha: 0.65),
      gradientColors: [
        Colors.white.withValues(alpha: 0.92),
        Colors.white.withValues(alpha: 0.82),
      ],
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.85),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.14),
          blurRadius: 20,
          offset: const Offset(0, -4),
        ),
      ],
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.5.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'map_filter_title'.tr,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _resetLocal,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                    ),
                    child: Text(
                      'map_filter_reset'.tr,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey.withValues(alpha: 0.2), height: 18.h),

              // 1. Khoảng thời gian
              _buildSectionTitle(
                title: 'map_filter_time'.tr,
                icon: Icons.schedule_rounded,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildGlassChoiceChip(
                    label: 'map_filter_time_all'.tr,
                    selected: _timeFilter == MapTimeFilter.all,
                    onTap: () =>
                        setState(() => _timeFilter = MapTimeFilter.all),
                  ),
                  _buildGlassChoiceChip(
                    label: 'map_filter_time_1h'.tr,
                    selected: _timeFilter == MapTimeFilter.last1Hour,
                    onTap: () =>
                        setState(() => _timeFilter = MapTimeFilter.last1Hour),
                  ),
                  _buildGlassChoiceChip(
                    label: 'map_filter_time_5h'.tr,
                    selected: _timeFilter == MapTimeFilter.last5Hours,
                    onTap: () =>
                        setState(() => _timeFilter = MapTimeFilter.last5Hours),
                  ),
                  _buildGlassChoiceChip(
                    label: 'map_filter_time_1d'.tr,
                    selected: _timeFilter == MapTimeFilter.last1Day,
                    onTap: () =>
                        setState(() => _timeFilter = MapTimeFilter.last1Day),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // 2. Loại sự cố / Tag
              _buildSectionTitle(
                title: 'map_filter_tag'.tr,
                icon: IconlyBroken.category,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: MapController.filterTagOptions.map((opt) {
                  final canonicalOption = opt.tag != null
                      ? HashtagHelper.toCanonical(opt.tag!)
                      : null;
                  final isSelected = _tag == canonicalOption;

                  return _buildGlassChoiceChip(
                    label: opt.tag != null
                        ? HashtagHelper.getLabel(opt.tag!)
                        : opt.labelKey.tr,
                    icon: opt.icon,
                    activeColor: opt.color,
                    selected: isSelected,
                    onTap: () => setState(() => _tag = canonicalOption),
                  );
                }).toList(),
              ),
              SizedBox(height: 18.h),

              // 3. Bán kính quanh vị trí hiện tại
              _buildSectionTitle(
                title: 'map_filter_radius'.tr,
                icon: IconlyBroken.location,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildGlassChoiceChip(
                    label: 'map_filter_radius_all'.tr,
                    selected: _radiusKm == null,
                    onTap: () => setState(() => _radiusKm = null),
                  ),
                  ...MapController.availableRadiiKm.map((r) {
                    final isSelected = _radiusKm == r;
                    return _buildGlassChoiceChip(
                      label: '< ${r.toInt()} km',
                      selected: isSelected,
                      onTap: () => setState(() => _radiusKm = r),
                    );
                  }),
                ],
              ),
              SizedBox(height: 24.h),

              // Nút Áp dụng
              PrimaryButton(text: 'map_filter_apply'.tr, onPressed: _apply),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: AppTheme.subTextColor),
        SizedBox(width: 6.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppTheme.textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassChoiceChip({
    required String label,
    IconData? icon,
    Color? activeColor,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final effectiveColor = activeColor ?? AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: selected
                ? effectiveColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? effectiveColor
                  : Colors.black.withValues(alpha: 0.08),
              width: selected ? 1.4 : 0.8,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: effectiveColor.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15.r,
                  color: selected ? effectiveColor : AppTheme.subTextColor,
                ),
                SizedBox(width: 5.w),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? effectiveColor : AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
