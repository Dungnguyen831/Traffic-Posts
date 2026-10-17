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
            // Chỉ hiển thị nút xóa tất cả khi còn nhiều biển số (dữ liệu cũ cần dọn dẹp)
            Obx(() {
              if (controller.subscriptions.length <= 1) {
                return const SizedBox.shrink();
              }
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
          child: Obx(() {
            // Trạng thái đang tải lần đầu
            if (controller.isLoading.value && controller.subscriptions.isEmpty) {
              return Center(
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
              );
            }

            // Trạng thái lỗi tải dữ liệu
            if (controller.errorMessage.isNotEmpty &&
                controller.subscriptions.isEmpty) {
              return _buildErrorState();
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Cảnh báo nếu tài khoản có nhiều hơn 1 biển số (dữ liệu cũ)
                if (controller.subscriptions.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 6.h),
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppTheme.warningColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              IconlyBroken.info_circle,
                              color: AppTheme.warningColor,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Text(
                                'violation_sub_multiple_warning'.tr,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppTheme.textColor,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Khi CHƯA có biển số nào đăng ký: hiển thị form đăng ký duy nhất
                if (controller.subscriptions.isEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                      child: _buildRegistrationCard(context),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: _buildEmptyState(),
                    ),
                  ),
                ]
                // Khi ĐÃ có đúng 1 biển số đăng ký: hiển thị Featured Card quản lý biển số duy nhất
                else if (controller.subscriptions.length == 1) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
                      child: SubscriptionItemCard(
                        key: ValueKey(controller.subscriptions.first.licensePlate),
                        item: controller.subscriptions.first,
                        isFeatured: true,
                        onToggleEnabled: (newValue) => controller
                            .toggleNotificationStatus(
                                controller.subscriptions.first, newValue),
                        onDelete: () => controller
                            .confirmDeleteSubscription(controller.subscriptions.first),
                        onChangePlate: () =>
                            controller.showChangePlateDialog(context),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                      child: _buildPolicyCard(),
                    ),
                  ),
                ]
                // Khi có nhiều hơn 1 biển số (dữ liệu cũ): hiển thị danh sách để người dùng xóa bớt
                else ...[
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = controller.subscriptions[index];
                          return SubscriptionItemCard(
                            key: ValueKey(item.licensePlate),
                            item: item,
                            isFeatured: false,
                            onToggleEnabled: (newValue) =>
                                controller.toggleNotificationStatus(item, newValue),
                            onDelete: () =>
                                controller.confirmDeleteSubscription(item),
                            onChangePlate: () =>
                                controller.showChangePlateDialog(context),
                          );
                        },
                        childCount: controller.subscriptions.length,
                      ),
                    ),
                  ),
                ],

                SliverToBoxAdapter(
                  child: SizedBox(height: 32.h),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Khối nhập đăng ký biển số xe khi chưa có biển số nào
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
                width: 38.w,
                height: 38.w,
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

  /// Khối chính sách & thông tin hướng dẫn
  Widget _buildPolicyCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                IconlyBroken.info_circle,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'violation_sub_policy_title'.tr,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'violation_sub_policy_desc'.tr,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textColor.withValues(alpha: 0.8),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  /// Trạng thái trống khi chưa có biển số nào được đăng ký
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconlyBroken.paper,
                color: AppTheme.primaryColor,
                size: 34.sp,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'violation_sub_empty_title'.tr,
              style: TextStyle(
                fontSize: 15.sp,
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

  /// Trạng thái lỗi tải dữ liệu
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
