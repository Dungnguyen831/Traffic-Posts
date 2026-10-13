import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:lottie/lottie.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:traffic_app/modules/profile/views/profile_view.dart';

import '../../../services/assets_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/loading_widget.dart';
import '../../dashboard/widgets/post_item.dart';
import '../../dashboard/widgets/post_item_shimmer.dart';
import '../controllers/user_profile_controller.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserProfileController());
    final heroTag = Get.arguments?['heroTag']?.toString();
    final initialAvatarUrl = Get.arguments?['initialAvatarUrl']?.toString() ??
        Get.arguments?['initialAvatar']?.toString();
    final initialUserName = Get.arguments?['initialUserName']?.toString();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Obx(
          () => Text(
            controller.userInfo.value?.fullname ??
                initialUserName ??
                'profile_user_info_title'.tr,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        actions: [
          if (!controller.isMyProfile)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: Obx(() {
                  final isFollowed = controller.isFollowing.value;
                  return GestureDetector(
                    onTap: () {
                      if (isFollowed) {
                        CustomDialog.showConfirm(
                          context: context,
                          title: 'profile_unfollow_title'.tr,
                          message: 'profile_unfollow_message'.tr,
                          confirmText: 'profile_confirm'.tr,
                          cancelText: 'profile_cancel'.tr,
                          onConfirm: () {
                            controller.toggleUserFollow();
                            Get.back();
                          },
                        );
                      } else {
                        controller.toggleUserFollow();
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: isFollowed
                            ? AppTheme.primaryBgColor
                            : AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(100.r),
                        boxShadow: isFollowed
                            ? []
                            : [
                                const BoxShadow(
                                  color: Color(0x404D5DFA),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                      ),
                      child: Text(
                        isFollowed
                            ? 'profile_unfollow_btn'.tr
                            : 'profile_follow_btn'.tr,
                        style: TextStyle(
                          color: isFollowed
                              ? AppTheme.primaryColor
                              : Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

          if (controller.isMyProfile)
            IconButton(
              icon: Icon(
                IconlyLight.setting,
                color: AppTheme.textColor,
                size: 24.sp,
              ),
              onPressed: () => Get.to(() => const ProfileView()),
            ),
        ],
      ),

      // ✅ SMART REFRESHER SỬ DỤNG CUSTOM FOOTER CỦA DASHBOARD
      body: SmartRefresher(
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
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
              );
            } else if (mode == LoadStatus.loading) {
              body = Center(child: LoadingWidget());
            } else if (mode == LoadStatus.failed) {
              body = Text(
                'dashboard_load_failed'.tr,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
              );
            } else if (mode == LoadStatus.canLoading) {
              body = Text(
                'dashboard_release_to_load'.tr,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
              );
            } else {
              final closeComp = AssetsService.to.closeComposition.value;
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

        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Obx(() {
                final user = controller.userInfo.value;
                final displayAvatarUrl =
                    user?.fullAvatarUrl ?? initialAvatarUrl;
                final displayUserName =
                    user?.fullname ?? initialUserName ?? 'profile_loading'.tr;

                return Column(
                  children: [
                    SizedBox(height: 20.h),
                    Hero(
                      tag:
                          heroTag ??
                          'avatar_default_${controller.targetUserId}',
                      child: ClipOval(
                        child: displayAvatarUrl != null
                            ? (displayAvatarUrl.startsWith('assets/')
                                ? Image.asset(
                                    displayAvatarUrl,
                                    width: 90.w,
                                    height: 90.w,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                      width: 90.w,
                                      height: 90.w,
                                      color: Colors.grey[200],
                                      child: Icon(
                                        IconlyBroken.profile,
                                        size: 50.sp,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: displayAvatarUrl,
                                    width: 90.w,
                                    height: 90.w,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(
                                          color: AppTheme.primaryColor,
                                        ),
                                    errorWidget: (context, url, error) => Icon(
                                      IconlyBroken.profile,
                                      size: 50.sp,
                                      color: Colors.grey,
                                    ),
                                  ))
                            : Container(
                                width: 90.w,
                                height: 90.w,
                                color: Colors.grey[200],
                                child: Icon(
                                  IconlyBroken.profile,
                                  size: 50.sp,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(height: 12.h),
                    Text(
                      displayUserName,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 28.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          '${user?.followingsCount ?? 0}',
                          'profile_stat_following'.tr,
                        ),
                        _buildStatItem(
                          '${user?.followersCount ?? 0}',
                          'profile_stat_followers'.tr,
                        ),
                        _buildStatItem(
                          '${controller.totalLikes.value}',
                          'profile_stat_likes'.tr,
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                  ],
                );
              }),
            ),

            // ==========================================
            // PHẦN DANH SÁCH BÀI VIẾT TÍCH HỢP SHIMMER VÀ LOTTIE
            // ==========================================
            Obx(() {
              // 1. TRẠNG THÁI LOADING: Dùng SliverList + PostItemShimmer
              if (controller.isLoading.value && controller.posts.isEmpty) {
                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: EdgeInsets.only(bottom: 20.h),
                        child: const PostItemShimmer(),
                      ),
                      childCount: 3, // Hiện 3 bộ xương (skeleton)
                    ),
                  ),
                );
              }

              // 2. TRẠNG THÁI TRỐNG: Dùng Lottie + SliverToBoxAdapter
              if (controller.posts.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: 40.h),
                        SizedBox(
                          height: 260.h,
                          child:
                              AssetsService.to.notFoundComposition.value != null
                              ? Lottie(
                                  composition: AssetsService
                                      .to
                                      .notFoundComposition
                                      .value!,
                                  fit: BoxFit.contain,
                                  repeat: true,
                                )
                              : Lottie.asset(
                                  'assets/animations/404_not_found.json',
                                  fit: BoxFit.contain,
                                  repeat: true,
                                  renderCache: RenderCache.drawingCommands,
                                ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'dashboard_no_posts'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // 3. TRẠNG THÁI CÓ DỮ LIỆU: Render danh sách thật
              return SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    addRepaintBoundaries: false,
                    (context, index) {
                      final post = controller.posts[index];
                      final postId = post.id ?? '';
                      final userId = post.userId ?? '';

                      return _PostKeepAlive(
                        key: ValueKey('keep_$postId'),
                        child: Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: RepaintBoundary(
                            key: ValueKey(postId),
                            child: PostItem(
                              key: ValueKey(postId),
                              post: post,
                              isLikedRx: controller.likedState(postId),
                              likeCountRx: controller.likeCount(postId),
                              isFollowedRx: controller.followedState(userId),
                              currentUserId: controller.currentUserId,
                              onLike: () => controller.toggleLike(post),
                              onReport: () => controller.reportPost(post),
                              onFollow: () {},
                              enableHeroAvatar: false,
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: controller.posts.length,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textColor,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, color: AppTheme.subTextColor),
        ),
      ],
    );
  }
}

class _PostKeepAlive extends StatefulWidget {
  final Widget child;

  const _PostKeepAlive({super.key, required this.child});

  @override
  State<_PostKeepAlive> createState() => _PostKeepAliveState();
}

class _PostKeepAliveState extends State<_PostKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
