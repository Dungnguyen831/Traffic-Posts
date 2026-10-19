import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../controllers/signup_controller.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/social_button.dart';
import '../../../widgets/custom_dropdown.dart';

class SignupScreen extends GetView<SignupController> {
  const SignupScreen({super.key});

  // Tạm thời ẩn mục đăng ký từ bên thứ 3 (Google, Facebook, Apple)
  static const bool _showThirdPartySignup = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,

      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  SizedBox(height: 40.h),
                  // Title
                  Text(
                    'signup_title'.tr,
                    style: TextStyle(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textColor,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 40.h),

                  // Username
                  CustomTextField(
                    hintText: 'username'.tr,
                    prefixIcon: FontAwesomeIcons.userGear,
                    focusNode: controller.usernameFocusNode,
                    controller: controller.usernameController,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16.h),

                  // Full Name
                  CustomTextField(
                    hintText: 'full_name'.tr,
                    prefixIcon: FontAwesomeIcons.userPen,
                    focusNode: controller.nameFocusNode,
                    controller: controller.fullNameController,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16.h),

                  // Email
                  // CustomTextField(
                  //   hintText: 'email'.tr,
                  //   prefixIcon: FontAwesomeIcons.solidEnvelope,
                  //   focusNode: controller.emailFocusNode,
                  //   keyboardType: TextInputType.emailAddress,
                  //   textInputAction: TextInputAction.next,
                  // ),
                  // SizedBox(height: 16.h),

                  // // Phone
                  // CustomTextField(
                  //   hintText: 'phone_number'.tr,
                  //   prefixIcon: FontAwesomeIcons.phone,
                  //   focusNode: controller.phoneFocusNode,
                  //   keyboardType: TextInputType.phone,
                  //   textInputAction: TextInputAction.next,
                  // ),
                  // SizedBox(height: 16.h),

                  // Province Dropdown
                  Obx(
                    () => CustomDropdown<Map<String, dynamic>>(
                      key: ValueKey(controller.provinces.length),
                      hintText: 'province_city'.tr,
                      prefixIcon: FontAwesomeIcons.mapPin,
                      value: controller.selectedProvince.value,
                      items: controller.provinces,
                      itemLabel: (item) => item['name'],
                      onChanged: (value) {
                        controller.selectedProvince.value = value;
                      },
                    ),
                  ),
                  // SizedBox(height: 16.h),

                  // // Address
                  // CustomTextField(
                  //   hintText: 'Địa chỉ cụ thể',
                  //   prefixIcon: FontAwesomeIcons.locationDot,
                  //   focusNode: controller.addressFocusNode,
                  //   textInputAction: TextInputAction.next,
                  // ),
                  SizedBox(height: 16.h),

                  // Password
                  CustomTextField(
                    hintText: 'password'.tr,
                    prefixIcon: FontAwesomeIcons.lock,
                    isPassword: true,
                    focusNode: controller.passwordFocusNode,
                    controller: controller.passwordController,
                    textInputAction: TextInputAction.next,
                  ),
                  SizedBox(height: 16.h),

                  // Confirm Password
                  CustomTextField(
                    hintText: 'confirm_password'.tr,
                    prefixIcon: FontAwesomeIcons.lock,
                    isPassword: true,
                    focusNode: controller.confirmPasswordFocusNode,
                    controller: controller.confirmPasswordController,
                    textInputAction: TextInputAction.done,
                  ),
                  SizedBox(height: 20.h),

                  // Remember Me
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      Obx(
                        () => Checkbox(
                          value: controller.rememberMe.value,
                          onChanged: controller.toggleRememberMe,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          activeColor: AppTheme.primaryColor,
                          side: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                      Text(
                        'remember_password'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Signup Button
                  Obx(
                    () => PrimaryButton(
                      text: 'signup_button'.tr,
                      isLoading: controller.isLoading.value,
                      onPressed: controller.signup,
                    ),
                  ),
                  SizedBox(height: _showThirdPartySignup ? 20.h : 24.h),

                  // Tạm thời ẩn mục đăng ký từ bên thứ 3 (Facebook, Google, Apple)
                  if (_showThirdPartySignup) ...[
                    // Divider
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(
                            color: AppTheme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                        Padding(
                          padding: .symmetric(horizontal: 16.w),
                          child: Text(
                            'or_signup_with'.tr,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF616161),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(
                            color: AppTheme.dividerColor,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 30.h),

                    // Social Buttons
                    Row(
                      mainAxisAlignment: .center,
                      children: [
                        SocialButton(
                          icon: FontAwesomeIcons.facebookF,
                          color: const Color(0xFF1877F2),
                          onPressed: () {},
                        ),
                        SizedBox(width: 20.w),
                        SocialButton(
                          iconAssetPath: 'assets/icons/google.svg',
                          color: Colors.white,
                          onPressed: () {},
                        ),
                        SizedBox(width: 20.w),
                        SocialButton(
                          icon: FontAwesomeIcons.apple,
                          color: Colors.black,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                  ],

                  // Login Link
                  Row(
                    mainAxisAlignment: .center,
                    children: [
                      Text(
                        'already_have_account'.tr,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppTheme.subTextColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.goToLogin,
                        child: Text(
                          'login_link'.tr,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
