import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../../../widgets/liquid_glass_bottom_bar.dart';
import '../../../widgets/location_permission_banner.dart';
import '../../../widgets/upload_progress_overlay.dart';
import '../../camera/views/camera_view.dart';
import '../../chatbot/views/chatbot_view.dart';
import '../../dashboard/views/dashboard_view.dart';
import '../../discovery/views/discovery_view.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../emergency/views/sos_active_screen.dart';
import '../../map/views/map_view.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        extendBody: true,
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: controller.currentIndex.value,
              children: const [
                DashboardView(),
                MapView(),
                CameraView(),
                DiscoveryView(),
                ChatbotView(),
              ],
            ),
            // Liquid Glass Bottom Bar
            SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: LiquidGlassBottomBar(
                  selectedIndex: controller.currentIndex.value,
                  onTabSelected: controller.changeTab,
                  tabs: [
                    LiquidGlassBottomBarTab(
                      label: 'home_bottom_navbar'.tr,
                      icon: IconlyBroken.home,
                      selectedIcon: IconlyBold.home,
                    ),
                    LiquidGlassBottomBarTab(
                      label: 'map_bottom_navbar'.tr,
                      icon: IconlyBroken.location,
                      selectedIcon: IconlyBold.location,
                    ),
                    LiquidGlassBottomBarTab(
                      label: 'camera_bottom_navbar'.tr,
                      icon: IconlyBroken.camera,
                      selectedIcon: IconlyBold.camera,
                    ),
                    LiquidGlassBottomBarTab(
                      label: 'discovery_bottom_navbar'.tr,
                      icon: IconlyBroken.search,
                      selectedIcon: IconlyBold.search,
                    ),
                    LiquidGlassBottomBarTab(
                      label: 'chatbot_bottom_navbar'.tr,
                      icon: IconlyBroken.chat,
                      selectedIcon: IconlyBold.chat,
                    ),
                  ],
                ),
              ),
            ),
            // Upload Progress Overlay
            if (controller.isUploading.value)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: UploadProgressOverlay(
                  progress: controller.uploadProgress.value,
                  label: controller.uploadLabel.value,
                  onCancel: controller.cancelUpload,
                ),
              ),
            // Location Permission / Service Banner
            if (!controller.locationBannerDismissed.value &&
                !controller.isUploading.value &&
                (controller.isLocationPermissionDenied.value ||
                    controller.isLocationServiceDisabled.value))
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: LocationPermissionBanner(
                  isServiceDisabled: controller.isLocationServiceDisabled.value,
                  onAction: controller.requestLocationPermission,
                  onDismiss: controller.dismissLocationBanner,
                ),
              ),

            // Bottom SOS Dialog (Hiển thị đè lên thanh điều hướng khi mở, che kín toàn bộ phía dưới màn hình)
            () {
              final isEmergencyRegistered =
                  Get.isRegistered<EmergencyController>();
              final isSosActive = isEmergencyRegistered &&
                  Get.find<EmergencyController>().isSosActive.value;
              final isMinimized = isEmergencyRegistered &&
                  Get.find<EmergencyController>().isSheetMinimized.value;
              final isSheetOpen = isSosActive &&
                  !isMinimized &&
                  controller.currentIndex.value == 1;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                left: 0,
                right: 0,
                bottom: isSheetOpen ? 0 : -550.h,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isSheetOpen ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isSheetOpen,
                    child: const SosActiveBottomView(),
                  ),
                ),
              );
            }(),

            // Top SOS Dialog / Banner: Luôn hiển thị xuyên suốt ở phía trên (trừ khi vào Settings/Profile)
            () {
              final isEmergencyRegistered =
                  Get.isRegistered<EmergencyController>();
              final isSosActive = isEmergencyRegistered &&
                  Get.find<EmergencyController>().isSosActive.value;
              final isMinimized = isEmergencyRegistered &&
                  Get.find<EmergencyController>().isSheetMinimized.value;
              final isVisible = isSosActive && isMinimized;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                top: isVisible
                    ? (MediaQuery.of(context).padding.top + 8.h)
                    : -120.h,
                left: 16.w,
                right: 16.w,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: isVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !isVisible,
                    child: SosTopBannerWidget(
                      onTap: () {
                        // Chuyển sang Map tab và mở lại màn hình SOS
                        controller.changeTab(1);
                        Get.find<EmergencyController>().isSheetMinimized.value =
                            false;
                      },
                    ),
                  ),
                ),
              );
            }(),
          ],
        ),
      ),
    );
  }
}
