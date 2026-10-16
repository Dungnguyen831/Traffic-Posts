import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/reputation_badge.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final ProfileController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    // Luôn làm mới thông tin và điểm số uy tín mới nhất từ server khi mở màn hình quản lý tài khoản
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadUserProfile(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
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
            "Quản lý tài khoản".tr,
            style: TextStyle(
              color: AppTheme.textColor,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.loadUserProfile(forceRefresh: true),
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            child: Column(
              children: [
                // 1. Avatar + Icon Edit
                Center(
                  child: GestureDetector(
                    onTap: controller.pickImage,
                    child: Stack(
                      children: [
                        Obx(() {
                          // 1. Ưu tiên ảnh vừa chọn từ thư viện (Local)
                          if (controller.selectedImagePath.value.isNotEmpty) {
                            return Hero(
                              tag: 'user_avatar',
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: FileImage(
                                      File(controller.selectedImagePath.value),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            );
                          }

                          // 2. Nếu có URL ảnh từ server (Network)
                          if (controller.currentAvatarUrl.value.isNotEmpty) {
                            return Hero(
                              tag: 'user_avatar',
                              child: CachedNetworkImage(
                                imageUrl: controller.currentAvatarUrl.value,
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                      width: 100.w,
                                      height: 100.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: imageProvider,
                                          fit: BoxFit.cover,
                                        ),
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                placeholder: (context, url) => Container(
                                  width: 100.w,
                                  height: 100.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.inputFillColor,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: LoadingWidget(height: 40.h),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  width: 100.w,
                                  height: 100.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.inputFillColor,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    IconlyBroken.profile,
                                    size: 50.sp,
                                    color: AppTheme.subTextColor,
                                  ),
                                ),
                              ),
                            );
                          }

                          // 3. Mặc định: Chưa có ảnh (Default)
                          return Hero(
                            tag: 'user_avatar',
                            child: Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.inputFillColor,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                IconlyBroken.profile,
                                size: 50.sp,
                                color: AppTheme.subTextColor,
                              ),
                            ),
                          );
                        }),

                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: controller.pickImage,
                            child: Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Icon(
                                IconlyBroken.edit,
                                color: Colors.white,
                                size: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20.h),

                // Card Điểm uy tín & Huy hiệu chính xác từ server
                Obx(
                  () => ReputationBadgeWidget(
                    badge: controller.badge.value,
                    score: controller.reputationScore.value,
                    canCreatePost: controller.canCreatePost.value,
                    isCompact: false,
                  ),
                ),

                SizedBox(height: 20.h),

                // 2. Các ô nhập liệu
                CustomTextField(
                  controller: controller.nameController,
                  hintText: "full_name".tr,
                  prefixIcon: IconlyBroken.profile,
                  keyboardType: TextInputType.name,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  controller: controller.emailController,
                  hintText: "Email",
                  prefixIcon: IconlyBroken.message,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  controller: controller.phoneController,
                  hintText: "phone_number".tr,
                  prefixIcon: IconlyBroken.call,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16.h),

                CustomTextField(
                  controller: controller.relativePhoneController,
                  hintText: "relative_phone".tr,
                  prefixIcon: IconlyBroken.call,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16.h),

                Obx(
                  () => CustomDropdown(
                    hintText: "province_city".tr,
                    prefixIcon: FontAwesomeIcons.mapPin,
                    value: controller.selectedProvince.value,
                    items: controller.provinces,
                    itemLabel: (item) => item['name'],
                    onChanged: (value) {
                      controller.selectedProvince.value = value;
                    },
                  ),
                ),

                SizedBox(height: 32.h),

                // 3. Nút Lưu
                PrimaryButton(
                  text: 'Lưu thay đổi'.tr,
                  onPressed: controller.saveProfile,
                ),
                SizedBox(height: 16.h),

                // 4. Nút Đăng xuất
                PrimaryButton(
                  text: 'Đăng xuất',
                  onPressed: controller.logout,
                  color: Colors.red,
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
