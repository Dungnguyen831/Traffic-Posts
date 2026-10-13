import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:traffic_app/config/demo_config.dart';
import 'package:traffic_app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:traffic_app/modules/map/controllers/map_controller.dart';
import 'package:traffic_app/routes/app_pages.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  // Bottom Navigation State
  var currentIndex = 0.obs;
  // final bool _mapTabVisited = false;

  // Upload Progress State
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;
  var uploadLabel = 'Đăng bài viết'.obs;

  // Location Permission / Service State
  var isLocationServiceDisabled = false.obs;
  var isLocationPermissionDenied = false.obs;
  var locationBannerDismissed = false.obs;

  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _initLocationMonitoring();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (DemoConfig.isDemoMode) return;
    if (state == AppLifecycleState.resumed) {
      // Re-check when user returns from Settings after granting permission
      checkLocationStatus();
    }
  }

  Future<void> _initLocationMonitoring() async {
    if (DemoConfig.isDemoMode) {
      isLocationServiceDisabled.value = false;
      isLocationPermissionDenied.value = false;
      locationBannerDismissed.value = true;
      return;
    }
    await checkLocationStatus();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      isLocationServiceDisabled.value = status == ServiceStatus.disabled;
      if (status == ServiceStatus.enabled) {
        // Re-check permission when GPS is re-enabled
        locationBannerDismissed.value = false;
        checkLocationStatus();
      }
    });
  }

  Future<void> checkLocationStatus() async {
    if (DemoConfig.isDemoMode) {
      isLocationServiceDisabled.value = false;
      isLocationPermissionDenied.value = false;
      locationBannerDismissed.value = true;
      return;
    }
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      isLocationServiceDisabled.value = !serviceEnabled;
      if (!serviceEnabled) {
        isLocationPermissionDenied.value = false;
        return;
      }
      final permission = await Geolocator.checkPermission();
      final denied =
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;
      isLocationPermissionDenied.value = denied;
      // Auto-hide banner if permission is now granted
      if (!denied) {
        locationBannerDismissed.value = false;
      }
    } catch (e) {
      debugPrint('HomeController checkLocationStatus error: $e');
    }
  }

  Future<void> requestLocationPermission() async {
    try {
      if (isLocationServiceDisabled.value) {
        await Geolocator.openLocationSettings();
        return;
      }
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
        return;
      }
      final result = await Geolocator.requestPermission();
      if (result == LocationPermission.always ||
          result == LocationPermission.whileInUse) {
        isLocationPermissionDenied.value = false;
        locationBannerDismissed.value = false;
      }
    } catch (e) {
      debugPrint('HomeController requestLocationPermission error: $e');
    }
  }

  void dismissLocationBanner() {
    locationBannerDismissed.value = true;
  }

  void changeTab(int index) {
    if (index == 0 && currentIndex.value == 0) {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().scrollToTop();
      }
      return;
    }
    currentIndex.value = index;
    // if (index == 1 && !_mapTabVisited) {
    //   _mapTabVisited = true;
    //   Future.delayed(const Duration(milliseconds: 200), () {
    //     if (Get.isRegistered<MapController>()) {
    //       Get.find<MapController>().toggleMapType();
    //     }
    //   });
    // }
  }

  void goToEditProfile() {
    Get.toNamed(Routes.PROFILE);
  }

  // Upload Progress Methods
  void startUpload({String label = 'Đăng bài viết'}) {
    uploadLabel.value = label;
    isUploading.value = true;
    uploadProgress.value = 0.0;
  }

  void updateUploadProgress(double progress) {
    uploadProgress.value = progress;
  }

  void completeUpload() {
    uploadProgress.value = 1.0;
    // Delay để hiển thị 100% trước khi ẩn
    Future.delayed(const Duration(milliseconds: 500), () {
      isUploading.value = false;
      uploadProgress.value = 0.0;
      // Reload map markers sau khi đăng bài thành công
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().loadTaggedPosts();
      }
    });
  }

  void cancelUpload() {
    isUploading.value = false;
    uploadProgress.value = 0.0;
  }
}
