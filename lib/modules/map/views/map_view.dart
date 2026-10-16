import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../../emergency/controllers/emergency_controller.dart';
import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // flutter_map Engine
          Positioned.fill(
            child: fm.FlutterMap(
              mapController: controller.mapEngineController,
              options: fm.MapOptions(
                initialCenter: controller.center,
                initialZoom: 14.0,
                minZoom: 3.0,
                maxZoom: 19.0,
                onMapReady: controller.onMapReady,
                interactionOptions: const fm.InteractionOptions(
                  flags: fm.InteractiveFlag.all,
                ),
              ),
              children: [
                // Tile Layer
                Obx(
                  () => fm.TileLayer(
                    urlTemplate: controller.currentTileUrl,
                    fallbackUrl: controller.fallbackTileUrl,
                    userAgentPackageName: 'com.trafficapp.app',
                    maxZoom: 19,
                  ),
                ),

                // Polyline Layer cho các tuyến đường
                Obx(
                  () => fm.PolylineLayer(
                    polylines: controller.polylines.toList(),
                  ),
                ),

                // Marker Layer cho Search result, Bài viết tagged, và Sự cố SOS (kèm radar sóng tỏa)
                Obx(
                  () => fm.MarkerLayer(
                    markers: controller.markers.toList(),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar: Ẩn khi SOS đang hoạt động để nhường không gian cho bản đồ và Top Banner
          Obx(() {
            final isEmergencyRegistered = Get.isRegistered<EmergencyController>();
            final isSosActive = isEmergencyRegistered &&
                Get.find<EmergencyController>().isSosActive.value;

            if (isSosActive) {
              return const SizedBox.shrink();
            }

            return Positioned(
              top: 50.h,
              left: 20.w,
              right: 20.w,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: controller.searchController,
                        decoration: const InputDecoration(
                          hintText: 'Tìm kiếm địa điểm...',
                          border: InputBorder.none,
                          icon: Icon(IconlyBroken.search, color: Colors.grey),
                        ),
                        onChanged: (value) {
                          controller.fetchSuggestions(value);
                        },
                        onSubmitted: (value) {
                          controller.searchLocation(value);
                        },
                      ),
                    ),
                  ),
                  Obx(
                    () => controller.placeSuggestions.isNotEmpty
                        ? Container(
                            margin: EdgeInsets.only(top: 10.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.r),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: controller.placeSuggestions.length,
                              itemBuilder: (context, index) {
                                final suggestion =
                                    controller.placeSuggestions[index];
                                return ListTile(
                                  title: Text(suggestion['description']),
                                  leading: const Icon(
                                    IconlyBroken.location,
                                    color: Colors.grey,
                                  ),
                                  onTap: () {
                                    controller.selectSuggestion(suggestion);
                                    FocusScope.of(context).unfocus();
                                  },
                                );
                              },
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          }),

          // Control Buttons (Map Type, Traffic, My Location) - Tự động trượt lên khi mở sheet SOS
          Obx(() {
            final isEmergencyRegistered = Get.isRegistered<EmergencyController>();
            final isSosActive = isEmergencyRegistered &&
                Get.find<EmergencyController>().isSosActive.value;
            final isSheetOpen = isSosActive &&
                !Get.find<EmergencyController>().isSheetMinimized.value;

            return AnimatedPositioned(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              right: 12.w,
              bottom: isSheetOpen ? 300.h : 90.h,
              child: Column(
                children: [
                  // Map Type Toggle
                  FloatingActionButton(
                    heroTag: 'map_type',
                    onPressed: controller.toggleMapType,
                    backgroundColor: AppTheme.backgroundColor,
                    child: const Icon(Icons.layers, color: Colors.black87),
                  ),
                  SizedBox(height: 10.h),

                  // Traffic Toggle
                  Obx(
                    () => FloatingActionButton(
                      heroTag: 'traffic',
                      onPressed: controller.toggleTraffic,
                      backgroundColor: controller.isTrafficEnabled.value
                          ? Colors.blue
                          : AppTheme.backgroundColor,
                      child: Icon(
                        Icons.traffic,
                        color: controller.isTrafficEnabled.value
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // My Location
                  FloatingActionButton(
                    heroTag: 'my_location',
                    onPressed: controller.goToMyLocation,
                    backgroundColor: AppTheme.backgroundColor,
                    child: Obx(
                      () => controller.isLoading.value
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : const Icon(IconlyBold.location, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
