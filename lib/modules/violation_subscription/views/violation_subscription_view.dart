import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/violation_subscription_controller.dart';
import '../widgets/subscription_item_card.dart';

class ViolationSubscriptionView
    extends GetView<ViolationSubscriptionController> {
  const ViolationSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
            'violation_sub_title'.tr,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          actions: [
            Obx(() {
              if (controller.subscriptions.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(
                  IconlyBroken.delete,
                  color: AppTheme.errorColor,
                  size: 22.sp,
                ),
                tooltip: 'violation_sub_delete_all_action'.tr,
                onPressed: controller.confirmDeleteAllSubscriptions,
              );
            }),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.loadSubscriptions,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Form đăng ký theo dõi
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: _buildRegistrationCard(context),
                ),
              ),

              // 2. Header danh sách đang theo dõi
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 10.h),
                  child: Obx(
                    () => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'violation_sub_my_list'.tr} (${controller.subscriptions.length})',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        if (controller.isLoading.value)
                          SizedBox(
                            width: 16.r,
                            height: 16.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Nội dung danh sách theo các trạng thái
              Obx(() {
                if (controller.isLoading.value &&
                    controller.subscriptions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const LoadingWidget(),
                          SizedBox(height: 12.h),
                          Text(
                            'profile_loading'.tr,
                            style: TextStyle(
                              color: AppTheme.subTextColor,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (controller.errorMessage.isNotEmpty &&
                    controller.subscriptions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildErrorState(),
                  );
                }

                if (controller.subscriptions.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = controller.subscriptions[index];
                        return SubscriptionItemCard(
                          key: ValueKey(item.licensePlate),
                          item: item,
                          onToggleEnabled: (newValue) =>
                              controller.toggleNotificationStatus(item, newValue),
                          onDelete: () =>
                              controller.confirmDeleteSubscription(item),
                        );
                      },
                      childCount: controller.subscriptions.length,
                    ),
                  ),
                );
              }),

              SliverToBoxAdapter(
                child: SizedBox(height: 40.h),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF04060F).withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
                child: Icon(
                  IconlyBroken.notification,
                  color: AppTheme.primaryColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'violation_sub_input_label'.tr,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'violation_sub_subtitle'.tr,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Ô nhập biển số xe
          CustomTextField(
            hintText: 'violation_sub_plate_hint'.tr,
            prefixIcon: IconlyBroken.edit,
            controller: controller.plateController,
            textCapitalization: TextCapitalization.characters,
            height: 50.h,
          ),
          SizedBox(height: 12.h),

          // Tùy chọn nhận thông báo
          Obx(
            () => Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FE),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppTheme.dividerColor.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    IconlyBroken.volume_up,
                    color: AppTheme.primaryColor,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'violation_sub_notify_toggle'.tr,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'violation_sub_notify_desc'.tr,
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: controller.receiveNotificationsForBoth.value,
                    activeColor: AppTheme.primaryColor,
                    onChanged: (val) =>
                        controller.receiveNotificationsForBoth.value = val,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Nút lưu đăng ký
          Obx(
            () => PrimaryButton(
              text: 'violation_sub_btn_register'.tr,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.registerSubscription,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyBroken.paper,
                color: AppTheme.primaryColor,
                size: 38.sp,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'violation_sub_empty_title'.tr,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textColor,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'violation_sub_empty_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppTheme.subTextColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppTheme.errorColor,
              size: 50.sp,
            ),
            SizedBox(height: 14.h),
            Text(
              controller.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textColor,
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: controller.loadSubscriptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('discovery_retry'.tr),
            ),
          ],
        ),
      ),
    );
  }
}
