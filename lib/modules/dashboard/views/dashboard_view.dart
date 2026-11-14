import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:traffic_app/theme/app_theme.dart';
import 'package:traffic_app/widgets/loading_widget.dart';

import '../../../services/assets_service.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/new_post_animator.dart';
import '../widgets/post_item_shimmer.dart';
import '../widgets/widgets.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Column(
          children: [
            // Header cố định
            Container(
              color: Colors.white,
              padding: EdgeInsets.only(
                left: 24.w,
                right: 24.w,
                top: MediaQuery.paddingOf(context).top + 10.h,
                bottom: 10.h,
              ),
              child: const DashboardHeader(),
            ),
            // Search bar & Filter bar cố định
            Container(
              padding: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16.r),
                  bottomRight: Radius.circular(16.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: DashboardSearchBar(
                      controller: controller.searchController,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  const DashboardFilterBar(),
                ],
              ),
            ),
            SizedBox(height: 10.h),
            // Content với SmartRefresher + Banner bài viết mới Realtime
            Expanded(
              child: Stack(
                children: [
                  Obx(() {
                    // 1. Trạng thái Loading ban đầu (Shimmer)
                    if (controller.isLoading.value &&
                        controller.posts.isEmpty) {
                      return ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: const PostItemShimmer(),
                        ),
                      );
                    }

                    // 2. SmartRefresher luôn bọc ngoài để cho phép vuốt làm mới kể cả khi danh sách trống
                    return SmartRefresher(
                      controller: controller.refreshController,
                      scrollController: controller.scrollController,
                      enablePullDown: true,
                      enablePullUp: controller.posts.isNotEmpty,
                      header: const WaterDropHeader(),
                      footer: CustomFooter(
                        builder: (context, mode) {
                          Widget body;
                          if (mode == LoadStatus.idle) {
                            body = Text(
                              'dashboard_pull_up_load'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[500],
                              ),
                            );
                          } else if (mode == LoadStatus.loading) {
                            body = Center(child: LoadingWidget());
                          } else if (mode == LoadStatus.failed) {
                            body = Text(
                              'dashboard_load_failed'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[500],
                              ),
                            );
                          } else if (mode == LoadStatus.canLoading) {
                            body = Text(
                              'dashboard_release_to_load'.tr,
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[500],
                              ),
                            );
                          } else {
                            final closeComp =
                                AssetsService.to.closeComposition.value;
                            body = SizedBox(
                              height: 120.h,
                              width: 120.h,
                              child: closeComp != null
                                  ? Lottie(
                                      composition: closeComp,
                                      fit: BoxFit.contain,
                                      repeat: true,
                                      renderCache: RenderCache.drawingCommands,
                                    )
                                  : Lottie.asset(
                                      'assets/animations/Close.json',
                                      fit: BoxFit.contain,
                                      repeat: true,
                                      renderCache: RenderCache.drawingCommands,
                                    ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 100.0),
                            child: SizedBox(
                              height: 140.h,
                              child: Center(child: body),
                            ),
                          );
                        },
                      ),
                      onRefresh: controller.refresh,
                      onLoading: controller.loadMore,
                      child: controller.posts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.only(
                                top: 60.h,
                                left: 24.w,
                                right: 24.w,
                              ),
                              children: [
                                SizedBox(
                                  height: 240.h,
                                  child: AssetsService
                                              .to.notFoundComposition.value !=
                                          null
                                      ? Lottie(
                                          composition: AssetsService
                                              .to.notFoundComposition.value!,
                                          fit: BoxFit.contain,
                                          repeat: true,
                                        )
                                      : Lottie.asset(
                                          'assets/animations/404_not_found.json',
                                          fit: BoxFit.contain,
                                          repeat: true,
                                          renderCache:
                                              RenderCache.drawingCommands,
                                        ),
                                ),
                                SizedBox(height: 16.h),
                                Center(
                                  child: Text(
                                    controller.currentKeyword.value.isNotEmpty
                                        ? 'dashboard_no_search_results'.tr
                                        : (controller.hasActiveFilters
                                            ? 'dashboard_no_filter_results'.tr
                                            : 'dashboard_no_posts'.tr),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15.5.sp,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (controller.hasActiveFilters) ...[
                                  SizedBox(height: 14.h),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: controller.resetAllFilters,
                                      icon: Icon(
                                        Icons.filter_alt_off_rounded,
                                        size: 16.sp,
                                        color: AppTheme.primaryColor,
                                      ),
                                      label: Text(
                                        'dashboard_clear_filters'.tr,
                                        style: TextStyle(
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBgColor,
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20.r),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              itemCount: controller.posts.length,
                              cacheExtent: 450,
                              addRepaintBoundaries: true,
                              itemBuilder: (context, index) {
                                final post = controller.posts[index];
                                final postId = post.id ?? '';
                                final userId = post.userId ?? '';
                                final isNew =
                                    index == 0 &&
                                    post.id != null &&
                                    controller.newPostId.value == post.id;
                                final isOwnPost =
                                    controller.currentUserId != null &&
                                    int.tryParse(userId) ==
                                        controller.currentUserId;
                                final item = PostItem(
                                  key: ValueKey(
                                    '${postId}_${post.content.hashCode}',
                                  ),
                                  post: post,
                                  isLikedRx: controller.likedState(postId),
                                  likeCountRx: controller.likeCount(postId),
                                  isFollowedRx: controller.followedState(
                                    userId,
                                  ),
                                  onLike: () => controller.toggleLike(post),
                                  onReport: () => controller.reportPost(post),
                                  onFollow: () => controller.toggleFollow(post),
                                  onEdit: isOwnPost
                                      ? () => controller.openEditPostSheet(post)
                                      : null,
                                  onDelete: isOwnPost
                                      ? () => controller.confirmDeletePost(
                                          context,
                                          post,
                                        )
                                      : null,
                                  currentUserId: controller.currentUserId,
                                  distanceText: controller.formatDistance(post),
                                  onTapLocation: post.location != null
                                      ? () => controller.openPostOnMap(post)
                                      : null,
                                  onTapHashtag: (tag) =>
                                      controller.toggleHashtagFilter(tag),
                                  activeHashtag:
                                      controller.selectedHashtag.value,
                                  activeHashtagRx: controller.selectedHashtag,
                                );
                                return Padding(
                                  key: ValueKey('pad_${postId}_$index'),
                                  padding: EdgeInsets.only(bottom: 20.h),
                                  child: isNew
                                      ? NewPostAnimator(
                                          key: ValueKey('anim_$postId'),
                                          dashController: controller,
                                          child: item,
                                        )
                                      : item,
                                );
                              },
                            ),
                    );
                  }),

                  // 3. Floating pill thông báo có bài viết mới từ cộng đồng qua WebSocket
                  Obx(() {
                    final pendingCount = controller.pendingRealtimePosts.length;
                    if (pendingCount == 0) return const SizedBox.shrink();

                    return Positioned(
                      top: 8.h,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTap: controller.applyPendingRealtimePosts,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 8.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(24.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16.sp,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'dashboard_new_posts_banner'
                                      .trParams({'count': '$pendingCount'}),
                                  style: TextStyle(
                                    fontSize: 12.5.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
