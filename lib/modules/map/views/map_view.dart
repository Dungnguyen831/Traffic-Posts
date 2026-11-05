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
          // flutter_map Engine (Raster Tiles MapTiler 256@2x mượt mà, ổn định tuyệt đối)
          Positioned.fill(
            child: fm.FlutterMap(
              mapController: controller.mapEngineController,
              options: fm.MapOptions(
                initialCenter: controller.center,
                initialZoom: 15.5,
                minZoom: 3.0,
                maxZoom: 21.0,
                keepAlive: true,
                backgroundColor: AppTheme.mapCanvasColor,
                onMapReady: controller.onMapReady,
                onPositionChanged: controller.onMapPositionChanged,
                interactionOptions: const fm.InteractionOptions(
                  flags: fm.InteractiveFlag.all,
                ),
              ),
              children: [
                // Tile Layer (Raster Tiles MapTiler 256@2x phóng to chữ, sắc nét, có caching)
                Obx(() {
                  final isNormalMap =
                      controller.currentMapType.value == AppMapType.normal;
                  final useMapTiler = isNormalMap && controller.hasMapTilerKey;
                  return fm.TileLayer(
                    urlTemplate: controller.currentTileUrl,
                    subdomains: isNormalMap && !useMapTiler
                        ? const ['a', 'b', 'c']
                        : const <String>[],
                    panBuffer: 1,
                    tileUpdateTransformer: fm.TileUpdateTransformers.throttle(
                      const Duration(milliseconds: 100),
                    ),
                    tileDisplay: const fm.TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 120),
                    ),
                    retinaMode: false,
                    maxNativeZoom: 19,
                    userAgentPackageName: 'com.trafficapp.app',
                    maxZoom: 21,
                  );
                }),

                // Polyline Layer cho các tuyến đường (dùng .toList() để kích hoạt lắng nghe RxList của GetX)
                Obx(
                  () => fm.PolylineLayer(
                    polylines: controller.polylines.toList(),
                  ),
                ),

                // Marker Layer (dùng .toList() để kích hoạt lắng nghe RxList của GetX)
                Obx(
                  () => fm.MarkerLayer(
                    rotate: true,
                    markers: controller.markers.toList(),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar: Ẩn khi SOS đang hoạt động để nhường không gian cho bản đồ và Top Banner
          Obx(() {
            final isEmergencyRegistered =
                Get.isRegistered<EmergencyController>();
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
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      type: MaterialType.transparency,
                      child: TextField(
                        controller: controller.searchController,
                        style: const TextStyle(color: AppTheme.textColor),
                        decoration: InputDecoration(
                          hintText: 'map_search_hint'.tr,
                          hintStyle: const TextStyle(
                            color: AppTheme.subTextColor,
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            IconlyBroken.search,
                            color: AppTheme.subTextColor,
                          ),
                        ),
                        onChanged: controller.fetchSuggestions,
                        onSubmitted: controller.searchLocation,
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
                                  color: Colors.black.withValues(alpha: 0.1),
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
                                  title: Text(
                                    suggestion['description'],
                                    style: const TextStyle(
                                      color: AppTheme.textColor,
                                    ),
                                  ),
                                  leading: const Icon(
                                    IconlyBroken.location,
                                    color: AppTheme.subTextColor,
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

          // Control Buttons (Map Type, My Location) - Tự động trượt lên khi mở sheet SOS
          Obx(() {
            final isEmergencyRegistered =
                Get.isRegistered<EmergencyController>();
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
                    child: const Icon(
                      Icons.layers_rounded,
                      color: AppTheme.textColor,
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
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : const Icon(
                              IconlyBold.location,
                              color: AppTheme.primaryColor,
                            ),
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
