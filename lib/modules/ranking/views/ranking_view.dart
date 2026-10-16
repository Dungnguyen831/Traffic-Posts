import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/loading_widget.dart';
import '../controllers/ranking_controller.dart';
import '../widgets/ranking_item_card.dart';

class RankingView extends GetView<RankingController> {
  const RankingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textColor,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'reputation_ranking_title'.tr,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: LoadingWidget(height: 60.h),
          );
        }

        if (controller.rankingList.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.onRefresh,
            color: AppTheme.primaryColor,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 0.7.sh,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconlyBroken.chart,
                        size: 64.sp,
                        color: AppTheme.subTextColor.withValues(alpha: 0.5),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'reputation_ranking_empty'.tr,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: AppTheme.subTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.onRefresh,
          color: AppTheme.primaryColor,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            itemCount: controller.rankingList.length + 1, // +1 for banner/header
            itemBuilder: (context, index) {
              if (index == 0) {
                // Header giới thiệu bảng xếp hạng
                return _buildHeaderBanner();
              }

              final itemIndex = index - 1;
              final user = controller.rankingList[itemIndex];
              final isLastItem = itemIndex == controller.rankingList.length - 1;

              return Column(
                children: [
                  RankingItemCard(
                    rank: itemIndex + 1,
                    user: user,
                  ),
                  if (isLastItem && controller.isLoadMore.value) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: Center(
                        child: LoadingWidget(height: 24.h),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.82),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
            blurRadius: 18,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'reputation_ranking_banner_title'.tr,
                  style: TextStyle(
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'reputation_ranking_banner_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 11.5.sp,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
