import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/dashboard_controller.dart';

class DashboardFilterBottomSheet extends StatefulWidget {
  const DashboardFilterBottomSheet({super.key});

  @override
  State<DashboardFilterBottomSheet> createState() =>
      _DashboardFilterBottomSheetState();
}

class _DashboardFilterBottomSheetState
    extends State<DashboardFilterBottomSheet> {
  final DashboardController _controller = Get.find<DashboardController>();

  late PostSortOption _sort;
  late bool _nearbyEnabled;
  late double _radiusKm;
  late PostTimeFilter _timeFilter;
  late String? _hashtag;
  late bool _onlyFollowing;

  static const List<Map<String, String?>> _hashtagOptions = [
    {'tag': null, 'labelKey': 'dashboard_filter_all'},
    {'tag': 'ketxe', 'labelKey': 'hashtag_label_ketxe'},
    {'tag': 'tainan', 'labelKey': 'hashtag_label_tainan'},
    {'tag': 'ngaplutnuoc', 'labelKey': 'hashtag_label_ngaplutnuoc'},
    {'tag': 'baocaotainan', 'labelKey': 'hashtag_label_baocaotainan'},
  ];

  @override
  void initState() {
    super.initState();
    _sort = _controller.selectedSort.value;
    _nearbyEnabled = _controller.isNearbyEnabled.value;
    _radiusKm = _controller.nearbyRadiusKm.value;
    _timeFilter = _controller.selectedTimeFilter.value;
    _hashtag = _controller.selectedHashtag.value;
    _onlyFollowing = _controller.onlyFollowing.value;
  }

  void _resetLocal() {
    setState(() {
      _sort = PostSortOption.newest;
      _nearbyEnabled = false;
      _radiusKm = 5.0;
      _timeFilter = PostTimeFilter.all;
      _hashtag = null;
      _onlyFollowing = false;
    });
  }

  Future<void> _apply() async {
    Get.back();
    await _controller.applyAdvancedFilters(
      sort: _sort,
      nearbyEnabled: _nearbyEnabled,
      radiusKm: _radiusKm,
      timeFilter: _timeFilter,
      hashtag: _hashtag,
      followingOnly: _onlyFollowing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'dashboard_filter_title'.tr,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                    ),
                  ),
                  TextButton(
                    onPressed: _resetLocal,
                    child: Text(
                      'dashboard_filter_reset'.tr,
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Divider(color: Colors.grey[200], height: 16.h),
              SizedBox(height: 6.h),

              // 1. Sắp xếp theo
              _buildSectionTitle('dashboard_sort_section'.tr),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildChoiceChip(
                    label: 'dashboard_sort_newest'.tr,
                    icon: Icons.schedule_rounded,
                    selected: _sort == PostSortOption.newest,
                    onTap: () => setState(() => _sort = PostSortOption.newest),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_sort_nearest'.tr,
                    icon: IconlyBold.location,
                    selected: _sort == PostSortOption.nearest,
                    onTap: () => setState(() {
                      _sort = PostSortOption.nearest;
                      _nearbyEnabled = true;
                    }),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_sort_popular'.tr,
                    icon: Icons.favorite_rounded,
                    selected: _sort == PostSortOption.mostLiked,
                    onTap: () =>
                        setState(() => _sort = PostSortOption.mostLiked),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_sort_reputation'.tr,
                    icon: Icons.verified_rounded,
                    selected: _sort == PostSortOption.reputation,
                    onTap: () =>
                        setState(() => _sort = PostSortOption.reputation),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // 2. Bán kính xung quanh vị trí của bạn
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionTitle('dashboard_radius_section'.tr),
                  ),
                  Switch.adaptive(
                    value: _nearbyEnabled,
                    activeTrackColor: AppTheme.primaryColor,
                    onChanged: (val) {
                      setState(() {
                        _nearbyEnabled = val;
                        if (val && _sort == PostSortOption.newest) {
                          _sort = PostSortOption.nearest;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_nearbyEnabled) ...[
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: DashboardController.availableRadiiKm.map((r) {
                    final isSelected = _radiusKm == r;
                    return _buildChoiceChip(
                      label: '< ${r.toInt()} km',
                      selected: isSelected,
                      onTap: () => setState(() => _radiusKm = r),
                    );
                  }).toList(),
                ),
              ],
              SizedBox(height: 16.h),

              // 3. Khoảng thời gian
              _buildSectionTitle('dashboard_time_section'.tr),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildChoiceChip(
                    label: 'dashboard_time_all'.tr,
                    selected: _timeFilter == PostTimeFilter.all,
                    onTap: () =>
                        setState(() => _timeFilter = PostTimeFilter.all),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_time_1h'.tr,
                    selected: _timeFilter == PostTimeFilter.last1Hour,
                    onTap: () =>
                        setState(() => _timeFilter = PostTimeFilter.last1Hour),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_time_3h'.tr,
                    selected: _timeFilter == PostTimeFilter.last3Hours,
                    onTap: () =>
                        setState(() => _timeFilter = PostTimeFilter.last3Hours),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_time_today'.tr,
                    selected: _timeFilter == PostTimeFilter.today,
                    onTap: () =>
                        setState(() => _timeFilter = PostTimeFilter.today),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_time_week'.tr,
                    selected: _timeFilter == PostTimeFilter.last7Days,
                    onTap: () =>
                        setState(() => _timeFilter = PostTimeFilter.last7Days),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // 4. Loại sự cố / Hashtag
              _buildSectionTitle('dashboard_hashtag_section'.tr),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: _hashtagOptions.map((opt) {
                  final tag = opt['tag'];
                  final labelKey = opt['labelKey']!;
                  final isSelected = _hashtag == tag;
                  return _buildChoiceChip(
                    label: tag == null ? labelKey.tr : '${labelKey.tr} (#$tag)',
                    selected: isSelected,
                    onTap: () => setState(() => _hashtag = tag),
                  );
                }).toList(),
              ),
              SizedBox(height: 18.h),

              // 5. Người đăng bài
              _buildSectionTitle('dashboard_author_section'.tr),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _buildChoiceChip(
                    label: 'dashboard_author_all'.tr,
                    selected: !_onlyFollowing,
                    onTap: () => setState(() => _onlyFollowing = false),
                  ),
                  _buildChoiceChip(
                    label: 'dashboard_author_following'.tr,
                    icon: Icons.people_alt_rounded,
                    selected: _onlyFollowing,
                    onTap: () => setState(() => _onlyFollowing = true),
                  ),
                ],
              ),
              SizedBox(height: 24.h),

              // Nút Áp dụng
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: 'dashboard_filter_apply'.tr,
                  onPressed: _apply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    IconData? icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14.sp,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
              SizedBox(width: 5.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

