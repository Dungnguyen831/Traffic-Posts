import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/traffic_post_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/primary_button.dart';
import '../../dashboard/widgets/post_item.dart';

class _PostSheetEntry {
  final Rx<TrafficPostModel> postRx;
  final RxBool isLikedRx;
  final RxInt likeCountRx;
  final RxBool isFollowedRx;
  late final Worker _worker;

  _PostSheetEntry(TrafficPostModel initial)
      : postRx = initial.obs,
        isLikedRx = (initial.isLiked ?? false).obs,
        likeCountRx = (initial.likes ?? 0).obs,
        isFollowedRx = (initial.isFollowedByCurrentUser ?? false).obs {
    _worker = ever<TrafficPostModel>(postRx, (updated) {
      isLikedRx.value = updated.isLiked ?? false;
      likeCountRx.value = updated.likes ?? 0;
      isFollowedRx.value = updated.isFollowedByCurrentUser ?? false;
    });
  }

  void dispose() {
    _worker.dispose();
  }
}

class PostBottomSheet {
  static void show({
    TrafficPostModel? post,
    List<TrafficPostModel>? posts,
    required int? currentUserId,
    required Future<void> Function(Rx<TrafficPostModel>) onLike,
    required Future<void> Function(Rx<TrafficPostModel>) onFollow,
    required void Function(TrafficPostModel) onReport,
  }) {
    final resolvedPosts = (posts != null && posts.isNotEmpty)
        ? posts
        : (post != null ? <TrafficPostModel>[post] : <TrafficPostModel>[]);
    if (resolvedPosts.isEmpty) return;

    final entries = resolvedPosts.map(_PostSheetEntry.new).toList();
    final currentIndexRx = 0.obs;

    String tagLabelForPost(TrafficPostModel p, int index) {
      if (p.hashtags != null && p.hashtags!.isNotEmpty) {
        return '#${p.hashtags!.first.replaceAll('#', '')}';
      }
      if (p.type != null && p.type!.isNotEmpty) {
        return '#${p.type}';
      }
      return 'map_report_tag'.trParams({'index': '${index + 1}'});
    }

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: 0.86.sh,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 12.h),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 8.h),

            // Thanh điều hướng khi có nhiều bài viết trùng vị trí / trong cùng cụm
            if (entries.length > 1)
              Obx(() {
                final idx = currentIndexRx.value;
                final total = entries.length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 4.h,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBgColor,
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.layers_rounded,
                              size: 18.sp,
                              color: AppTheme.primaryColor,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'map_reports_in_area'.trParams({'total': '$total'}),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textColor,
                                ),
                              ),
                            ),
                            // Nút Lùi (<)
                            InkWell(
                              borderRadius: BorderRadius.circular(20.r),
                              onTap: idx > 0
                                  ? () => currentIndexRx.value = idx - 1
                                  : null,
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  size: 22.sp,
                                  color: idx > 0
                                      ? AppTheme.primaryColor
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Text(
                                '${idx + 1} / $total',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            // Nút Tiến (>)
                            InkWell(
                              borderRadius: BorderRadius.circular(20.r),
                              onTap: idx < total - 1
                                  ? () => currentIndexRx.value = idx + 1
                                  : null,
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 22.sp,
                                  color: idx < total - 1
                                      ? AppTheme.primaryColor
                                      : Colors.grey[400],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Danh sách chip chọn nhanh từng bài viết trong cụm
                    SizedBox(
                      height: 36.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 4.h,
                        ),
                        itemCount: total,
                        separatorBuilder: (_, _) => SizedBox(width: 8.w),
                        itemBuilder: (context, chipIdx) {
                          final isSelected = chipIdx == idx;
                          final chipPost = entries[chipIdx].postRx.value;
                          final label = tagLabelForPost(chipPost, chipIdx);

                          return GestureDetector(
                            onTap: () => currentIndexRx.value = chipIdx,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${chipIdx + 1}. $label',
                                style: TextStyle(
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 4.h),
                  ],
                );
              }),

            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                child: Column(
                  children: [
                    Obx(() {
                      final activeEntry = entries[currentIndexRx.value];
                      return GestureDetector(
                        onHorizontalDragEnd: entries.length > 1
                            ? (details) {
                                final velocity = details.primaryVelocity ?? 0;
                                if (velocity < -250 &&
                                    currentIndexRx.value < entries.length - 1) {
                                  currentIndexRx.value++;
                                } else if (velocity > 250 &&
                                    currentIndexRx.value > 0) {
                                  currentIndexRx.value--;
                                }
                              }
                            : null,
                        child: PostItem(
                          key: ValueKey(
                            'sheet_post_${activeEntry.postRx.value.id ?? currentIndexRx.value}',
                          ),
                          post: activeEntry.postRx.value,
                          currentUserId: currentUserId,
                          isLikedRx: activeEntry.isLikedRx,
                          likeCountRx: activeEntry.likeCountRx,
                          isFollowedRx: activeEntry.isFollowedRx,
                          enableHeroAvatar: false,
                          onLike: () => onLike(activeEntry.postRx),
                          onReport: () {
                            Get.back();
                            onReport(activeEntry.postRx.value);
                          },
                          onFollow: () => onFollow(activeEntry.postRx),
                        ),
                      );
                    }),
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () => Get.back(),
                        text: 'map_close'.tr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    ).whenComplete(() {
      for (final entry in entries) {
        entry.dispose();
      }
    });
  }
}
