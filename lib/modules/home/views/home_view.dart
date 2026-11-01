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
          // 1. Main Tab Views (Lazy mounted for tabs 2, 3, 4)
          Obx(() {
            final visited = controller.visitedTabs;
            return IndexedStack(
              index: controller.currentIndex.value,
              children: [
                const DashboardView(),
                const MapView(),
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

          // 2. Liquid Glass Bottom Bar
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Obx(
                () => LiquidGlassBottomBar(
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
          ),

          // 3. Upload Progress Overlay
          Obx(() {
            if (!controller.isUploading.value) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: topPadding + 8,
              left: 0,
              right: 0,
              child: UploadProgressOverlay(
                progress: controller.uploadProgress.value,
                label: controller.uploadLabel.value,
                onCancel: controller.cancelUpload,
              ),
            );
          }),

          // 4. Location Permission / Service Banner
          Obx(() {
            final showBanner =
                !controller.locationBannerDismissed.value &&
                !controller.isUploading.value &&
                (controller.isLocationPermissionDenied.value ||
                    controller.isLocationServiceDisabled.value);
            if (!showBanner) {
              return const SizedBox.shrink();
            }
            return Positioned(
              top: topPadding + 8,
              left: 0,
              right: 0,
              child: LocationPermissionBanner(
                isServiceDisabled: controller.isLocationServiceDisabled.value,
                onAction: controller.requestLocationPermission,
                onDismiss: controller.dismissLocationBanner,
              ),
            );
          }),

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
