import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/widgets/loading_widget.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_pages.dart';
import '../../../theme/app_theme.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../home/controllers/home_controller.dart';
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
        // Logo ứng dụng kèm tên Traffic Posts phía trên cùng bên trái
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34.w,
              height: 34.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.asset(
                  'assets/icons/app_icon_big.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            RichText(
              text: TextSpan(
                style: GoogleFonts.quicksand(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
                children: const [
                  TextSpan(
                    text: 'Traffic ',
                    style: TextStyle(color: AppTheme.textColor),
                  ),
                  TextSpan(
                    text: 'Posts',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Spacer(),
        // Nút Bảng xếp hạng uy tín
        GestureDetector(
          onTap: () => Get.toNamed(Routes.RANKING),
          child: Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              size: 20.sp,
              color: const Color(0xFFE5A100),
            ),
          ),
        ),
        SizedBox(width: 14.w),
        // Map marker
        // Nút Cứu hộ khẩn cấp
        GestureDetector(
          onTap: () {
            if (Get.isRegistered<EmergencyController>() &&
                Get.find<EmergencyController>().isSosActive.value) {
              Get.find<EmergencyController>().isSheetMinimized.value = false;
              if (Get.isRegistered<HomeController>()) {
                Get.find<HomeController>().changeTab(1);
              }
            } else {
              Get.toNamed(Routes.EMERGENCY);
            }
          },
          child: SvgPicture.asset(
            'assets/icons/warning_appbar.svg',
            width: 40.w,
            height: 40.w,
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
                width: 36.w,
                height: 36.w,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: isLoading
                    ? Center(child: LoadingWidget(width: 20.w))
                    : (avatarUrl.isEmpty
                          ? Icon(
                              IconlyBroken.profile,
                              size: 20.sp,
                              color: Colors.white,
                            )
                          : CachedNetworkImage(
                              imageUrl: avatarUrl,
                              fit: BoxFit.cover,
                              width: 36.w,
                              height: 36.w,
                              placeholder: (context, url) =>
                                  Center(child: LoadingWidget(width: 20.w)),
                              errorWidget: (context, url, error) => Icon(
                                IconlyBroken.profile,
                                size: 20.sp,
                                color: Colors.white,
                              ),
                            )),
              );
            }),
          ),
        ),
      ],
    );
  }
}
