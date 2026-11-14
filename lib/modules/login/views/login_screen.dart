import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../../routes/app_pages.dart';
import '../../../services/localization_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/social_button.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  // Tạm thời ẩn mục đăng nhập từ bên thứ 3 (Google, Facebook, Apple)
  static const bool _showThirdPartyLogin = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                child: Padding(
                  padding: .symmetric(horizontal: 24.w),
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      SizedBox(height: 40.h),
                      // Language Switcher (Temporary for testing)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            if (Get.locale?.languageCode == 'vi') {
                              LocalizationService.changeLocale('English');
                            } else {
                              LocalizationService.changeLocale('Tiếng Việt');
                            }
                          },
                          child: Text(
                            Get.locale?.languageCode == 'vi'
                                ? 'English'
                                : 'Tiếng Việt',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      // Title
                      Text(
                        'login_title'.tr,
                        style: TextStyle(
                          fontSize: 44.sp,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textColor,
                          height: 1.1,
                        ),
                      ),
                      SizedBox(height: 40.h),

                      // Username Input
                      CustomTextField(
                        controller: controller.usernameController,
                        hintText: 'username'.tr,
                        prefixIcon: FontAwesomeIcons.userGear,
                        focusNode: controller.usernameFocusNode,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 24.h),

                      // Password Input
                      CustomTextField(
                        controller: controller.passwordController,
                        hintText: 'password'.tr,
                        prefixIcon: FontAwesomeIcons.lock,
                        isPassword: true,
                        focusNode: controller.passwordFocusNode,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 24.h),

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
                      SizedBox(height: 24.h),

                      // Login Button
                      Obx(
                        () => PrimaryButton(
                          text: 'login_button'.tr,
                          isLoading: controller.isLoading.value,
                          onPressed: () {
                            controller.login();
                          },
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Forgot Password
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: Text(
                            'forgot_password'.tr,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: _showThirdPartyLogin ? 40.h : 28.h),

                      // Tạm thời ẩn mục đăng nhập từ bên thứ 3 (Facebook, Google, Apple)
                      if (_showThirdPartyLogin) ...[
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
                                'or_login_with'.tr,
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
                              icon: FontAwesomeIcons.facebook,
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

                      // Sign Up
                      Row(
                        mainAxisAlignment: .center,
                        children: [
                          Text(
                            'register_new_account'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: AppTheme.subTextColor,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(Routes.SIGNUP),
                            child: Text(
                              'signup_link'.tr,
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
            ],
          ),
        ),
      ),
    );
  }
}
