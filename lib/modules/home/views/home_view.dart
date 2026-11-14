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
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBody: true,
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Main Tab Views (Lazy mounted for tabs 1, 2, 3, 4)
          // NotificationListener bắt sự kiện cuộn dọc từ mọi tab để thu nhỏ /
          // mở rộng thanh điều hướng.
          NotificationListener<ScrollNotification>(
            onNotification: controller.handleScrollNotification,
            child: Obx(() {
              final visited = controller.visitedTabs;
              return IndexedStack(
                index: controller.currentIndex.value,
                children: [
                  const DashboardView(),
                  visited.contains(1)
                      ? const MapView()
                      : const SizedBox.shrink(),
                  visited.contains(2)
                      ? const CameraView()
                      : const SizedBox.shrink(),
                  visited.contains(3)
                      ? const DiscoveryView()
                      : const SizedBox.shrink(),
                  visited.contains(4)
                      ? const ChatbotView()
                      : const SizedBox.shrink(),
                ],
              );
            }),
          ),

          // 2. Liquid Glass Bottom Bar (Cô lập RepaintBoundary để không ảnh hưởng FPS khi cuộn danh sách)
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                child: Obx(
                  () => LiquidGlassBottomBar(
                    selectedIndex: controller.currentIndex.value,
                    collapsed: controller.isNavBarCollapsed.value,
                    onExpandRequested: () =>
                        controller.isNavBarCollapsed.value = false,
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
            ),
          ),

          // 3 & 4. Top Status Overlay (Upload Progress & Location Permission Banner)
          Positioned(
            top: topPadding + 8,
            left: 0,
            right: 0,
            child: Obx(() {
              final uploading = controller.isUploading.value;
              final showLocationBanner =
                  !uploading &&
                  !controller.locationBannerDismissed.value &&
                  (controller.isLocationPermissionDenied.value ||
                      controller.isLocationServiceDisabled.value);

              Widget bannerChild = const SizedBox.shrink(
                key: ValueKey('no_banner'),
              );
              if (uploading) {
                bannerChild = UploadProgressOverlay(
                  key: const ValueKey('upload_banner'),
                  progress: controller.uploadProgress.value,
                  label: controller.uploadLabel.value,
                  onCancel: controller.cancelUpload,
                );
              } else if (showLocationBanner) {
                bannerChild = LocationPermissionBanner(
                  key: const ValueKey('location_banner'),
                  isServiceDisabled: controller.isLocationServiceDisabled.value,
                  onAction: controller.requestLocationPermission,
                  onDismiss: controller.dismissLocationBanner,
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: bannerChild,
              );
            }),
          ),

          // 5. Bottom SOS Dialog
          Obx(() {
            final isEmergencyRegistered =
                Get.isRegistered<EmergencyController>();
            final isSosActive =
                isEmergencyRegistered &&
                Get.find<EmergencyController>().isSosActive.value;
            final isMinimized =
                isEmergencyRegistered &&
                Get.find<EmergencyController>().isSheetMinimized.value;
            final isSheetOpen =
                isSosActive &&
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
          }),

          // 6. Top SOS Dialog / Banner
          Obx(() {
            final isEmergencyRegistered =
                Get.isRegistered<EmergencyController>();
            final isSosActive =
                isEmergencyRegistered &&
                Get.find<EmergencyController>().isSosActive.value;
            final isMinimized =
                isEmergencyRegistered &&
                Get.find<EmergencyController>().isSheetMinimized.value;
            final isVisible = isSosActive && isMinimized;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              top: isVisible ? (topPadding + 8.h) : -120.h,
              left: 16.w,
              right: 16.w,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 250),
                opacity: isVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !isVisible,
                  child: SosTopBannerWidget(
                    isActive: isVisible,
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
          }),
        ],
      ),
    );
  }
}
