import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:shimmer/shimmer.dart';

import '../../../data/models/user_info_model.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/reputation_badge.dart';
import '../controllers/follow_management_controller.dart';

class FollowManagementView extends GetView<FollowManagementController> {
  const FollowManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textColor,
              size: 20.sp,
            ),
            onPressed: () => Get.back(),
          ),
          title: Text(
            'Quản lý theo dõi'.tr,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. Thanh tìm kiếm
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller.searchController,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppTheme.textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm theo tên hoặc username...',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.subTextColor,
                    ),
                    prefixIcon: Icon(
                      IconlyBroken.search,
                      color: AppTheme.subTextColor,
                      size: 20.sp,
                    ),
                    suffixIcon: Obx(
                      () => controller.searchKeyword.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: AppTheme.subTextColor,
                                size: 18.sp,
                              ),
                              onPressed: controller.clearSearch,
                            )
                          : const SizedBox.shrink(),
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                ),
              ),
            ),

            // 2. TabBar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TabBar(
                controller: controller.tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: AppTheme.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppTheme.subTextColor,
                labelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                padding: EdgeInsets.all(4.w),
                tabs: [
                  Tab(
                    child: Obx(
                      () => Text(
                        'Người theo dõi (${controller.followers.length})',
                      ),
                    ),
                  ),
                  Tab(
                    child: Obx(
                      () => Text(
                        'Đang theo dõi (${controller.followings.length})',
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Danh sách người dùng theo từng Tab
            Expanded(
              child: TabBarView(
                controller: controller.tabController,
                children: [
                  // Tab 0: Người theo dõi (Followers)
                  _buildFollowersTab(),

                  // Tab 1: Đang theo dõi (Followings)
                  _buildFollowingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện Tab Người theo dõi
  Widget _buildFollowersTab() {
    return Obx(() {
      if (controller.isLoadingFollowers.value &&
          controller.followers.isEmpty) {
        return _buildShimmerList();
      }

      final list = controller.filteredFollowers;

      if (list.isEmpty) {
        return _buildEmptyState(
          title: controller.searchKeyword.value.isNotEmpty
              ? 'Không tìm thấy kết quả'
              : 'Chưa có người theo dõi nào',
          subtitle: controller.searchKeyword.value.isNotEmpty
              ? 'Thử tìm kiếm với từ khóa khác'
              : 'Khi có người khác theo dõi bạn, họ sẽ xuất hiện ở đây',
          icon: IconlyBroken.profile,
          onRefresh: controller.fetchFollowers,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchFollowers,
        color: AppTheme.primaryColor,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: list.length,
          separatorBuilder: (context, index) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final user = list[index];
            return _buildUserItemCard(user);
          },
        ),
      );
    });
  }

  /// Giao diện Tab Đang theo dõi
  Widget _buildFollowingsTab() {
    return Obx(() {
      if (controller.isLoadingFollowings.value &&
          controller.followings.isEmpty) {
        return _buildShimmerList();
      }

      final list = controller.filteredFollowings;

      if (list.isEmpty) {
        return _buildEmptyState(
          title: controller.searchKeyword.value.isNotEmpty
              ? 'Không tìm thấy kết quả'
              : 'Chưa theo dõi người dùng nào',
          subtitle: controller.searchKeyword.value.isNotEmpty
              ? 'Thử tìm kiếm với từ khóa khác'
              : 'Hãy theo dõi những người dùng tích cực để nhận thông tin giao thông mới nhất',
          icon: Icons.person_add_alt_1_rounded,
          onRefresh: controller.fetchFollowings,
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchFollowings,
        color: AppTheme.primaryColor,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          itemCount: list.length,
          separatorBuilder: (context, index) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final user = list[index];
            return _buildUserItemCard(user);
          },
        ),
      );
    });
  }

  /// Card hiển thị thông tin 1 người dùng kèm nút tương tác
  Widget _buildUserItemCard(UserInfoModel user) {
    final isMe = user.id == controller.currentUserId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () => controller.openUserProfile(user),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                // 1. Avatar
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: user.fullAvatarUrl != null &&
                            user.fullAvatarUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: user.fullAvatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppTheme.inputFillColor,
                              child: const Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => _buildAvatarPlaceholder(),
                          )
                        : _buildAvatarPlaceholder(),
                  ),
                ),
                SizedBox(width: 12.w),

                // 2. Thông tin Tên, Username, Điểm & Huy hiệu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullname ?? user.username ?? 'Người dùng',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (user.username != null &&
                          user.username!.isNotEmpty &&
                          user.username != user.fullname) ...[
                        SizedBox(height: 2.h),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.subTextColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      SizedBox(height: 4.h),
                      ReputationBadgeWidget(
                        badge: user.badge ?? 'Người dẫn đường',
                        score: user.reputationScore ?? 100,
                        isCompact: true,
                        showScore: true,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // 3. Nút Follow / Unfollow (Chỉ hiển thị nếu không phải tài khoản của chính mình)
                if (!isMe && user.id != null)
                  Obx(() {
                    final following = controller.isFollowing(user.id);
                    return InkWell(
                      onTap: () => controller.toggleFollow(user),
                      borderRadius: BorderRadius.circular(20.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: following
                              ? AppTheme.inputFillColor
                              : AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: following
                                ? Colors.grey.shade300
                                : AppTheme.primaryColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              following
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
                              size: 16.sp,
                              color: following
                                  ? AppTheme.textColor
                                  : Colors.white,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              following ? 'Đang theo dõi' : 'Theo dõi',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: following
                                  ? AppTheme.textColor
                                  : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: AppTheme.inputFillColor,
      child: Icon(
        IconlyBroken.profile,
        size: 26.sp,
        color: AppTheme.subTextColor,
      ),
    );
  }

  /// Trạng thái trống
  Widget _buildEmptyState({
    required String title,
    required String subtitle,
    required IconData icon,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 80.h),
        children: [
          Center(
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40.sp,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppTheme.subTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Hiệu ứng Shimmer khi đang tải dữ liệu
  Widget _buildShimmerList() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: 6,
      separatorBuilder: (context, index) => SizedBox(height: 10.h),
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          height: 72.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }
}
