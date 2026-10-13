import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
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
        body: SingleChildScrollView(
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
                          final imgPath = controller.selectedImagePath.value;
                          final isNetworkOrBlob = kIsWeb ||
                              imgPath.startsWith('http') ||
                              imgPath.startsWith('blob:');
                          return Hero(
                            tag: 'user_avatar',
                            child: Container(
                              width: 100.w,
                              height: 100.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: isNetworkOrBlob
                                      ? NetworkImage(imgPath)
                                      : FileImage(
                                          File(imgPath),
                                        ) as ImageProvider,
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

                        // 2. Nếu có URL ảnh từ assets hoặc server (Network)
                        if (controller.currentAvatarUrl.value.isNotEmpty) {
                          final avatarPath = controller.currentAvatarUrl.value;
                          if (avatarPath.startsWith('assets/')) {
                            return Hero(
                              tag: 'user_avatar',
                              child: Container(
                                width: 100.w,
                                height: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(avatarPath),
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
                          return Hero(
                            tag: 'user_avatar',
                            child: CachedNetworkImage(
                              imageUrl: avatarPath,
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
              SizedBox(height: 30.h),

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
                prefixIcon: IconlyBold.call,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16.h),

              Obx(
                () => CustomDropdown<Map<String, dynamic>>(
                  key: ValueKey(
                    "${controller.provinces.length}_${controller.selectedProvince.value?['name']}",
                  ),
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

              SizedBox(height: 24.h),

              // 3. Thẻ "Lái xe an toàn"
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Row(
                  children: [
                    _buildMedalIcon(1500),
                    SizedBox(width: 16.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lái xe an toàn".tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Điểm số: 1500".tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppTheme.subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              // 4. Nút Lưu
              PrimaryButton(
                text: 'Lưu thay đổi'.tr,
                onPressed: controller.saveProfile,
              ),
              SizedBox(height: 16.h),

              // 5. Nút Đăng xuất
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
    );
  }

  Widget _buildMedalIcon(int score) {
    String assetName;
    if (score >= 1500) {
      assetName = 'assets/icons/gold_medal.svg';
    } else if (score >= 1000) {
      assetName = 'assets/icons/silver_medal.svg';
    } else {
      assetName = 'assets/icons/bronze_medal.svg';
    }

    return SizedBox(
      width: 50.w,
      height: 50.w,
      child: SvgPicture.asset(assetName),
    );
  }
}
