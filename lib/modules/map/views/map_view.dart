import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:traffic_app/theme/app_theme.dart';

import '../controllers/map_controller.dart';

class MapView extends GetView<MapController> {
  const MapView({super.key});

  @override
  Widget build(BuildContext context) {
    // Đảm bảo không gian hiển thị toàn màn hình, không bị co lại chiều cao 0
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // flutter_map Engine - Đảm bảo kích thước toàn màn hình với Positioned.fill
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
                // Tile Layer với OpenStreetMap, fallback mirror, và User Agent chuẩn
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

                // Marker Layer cho Search result, Bài viết tagged, và Sự cố SOS
                Obx(
                  () => fm.MarkerLayer(
                    markers: controller.markers.toList(),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar with Suggestions
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
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
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
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
          ),

          // Control Buttons
          Positioned(
            right: 10,
            bottom: 90,
            child: Column(
              children: [
                // Map Type Toggle
                FloatingActionButton(
                  heroTag: 'map_type',
                  onPressed: controller.toggleMapType,
                  backgroundColor: AppTheme.backgroundColor,
                  child: const Icon(Icons.layers, color: Colors.black87),
                ),
                const SizedBox(height: 10),

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
                const SizedBox(height: 10),

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
          ),
        ],
      ),
    );
  }
}
