import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';
import 'package:traffic_app/widgets/loading_widget.dart';

import '../../../routes/app_pages.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/views/user_profile_screen.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy ProfileController đã được đăng ký từ HomeBinding
    final profileController = Get.find<ProfileController>();

    return Row(
      children: [
        // App Logo & Tên ứng dụng Flowly với font Quicksand chuẩn của app
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/app_icon_big.png',
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10.w),
            Text(
              'Traffic Posts',
              style: GoogleFonts.quicksand(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Nút Cứu hộ khẩn cấp
        GestureDetector(
          onTap: () {
            Get.toNamed(Routes.EMERGENCY);
          },
          child: SvgPicture.asset(
            'assets/icons/warning_appbar.svg',
            width: 38.w,
            height: 38.w,
          ),
        ),
        SizedBox(width: 14.w),
        // Avatar - hiển thị từ ProfileController
        GestureDetector(
          onTap: () {
            Get.to(
              () => const UserProfileScreen(),
              arguments: {
                'heroTag': 'user_avatar',
                'initialAvatarUrl': profileController.currentAvatarUrl.value,
                'initialAvatar': profileController.currentAvatarUrl.value,
              },
            );
          },
          child: Hero(
            tag: 'user_avatar',
            child: Obx(() {
              final avatarUrl = profileController.currentAvatarUrl.value;
              final isLoading = profileController.isLoading.value;

              return Container(
                width: 38.w,
                height: 38.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: isLoading
                    ? Center(child: LoadingWidget(width: 18.w))
                    : (avatarUrl.isEmpty
                          ? Container(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              child: Icon(
                                IconlyBroken.profile,
                                size: 20.sp,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : (avatarUrl.startsWith('assets/')
                                ? Image.asset(
                                    avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 38.w,
                                    height: 38.w,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                              child: Icon(
                                                IconlyBroken.profile,
                                                size: 20.sp,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                  )
                                : CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    fit: BoxFit.cover,
                                    width: 38.w,
                                    height: 38.w,
                                    placeholder: (context, url) => Center(
                                      child: LoadingWidget(width: 18.w),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                          color: AppTheme.primaryColor
                                              .withOpacity(0.1),
                                          child: Icon(
                                            IconlyBroken.profile,
                                            size: 20.sp,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                  ))),
              );
            }),
          ),
        ),
      ],
    );
  }
}
