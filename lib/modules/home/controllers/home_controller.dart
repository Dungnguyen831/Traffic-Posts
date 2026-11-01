import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:traffic_app/modules/camera/controllers/camera_controller.dart';
import 'package:traffic_app/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:traffic_app/modules/map/controllers/map_controller.dart';
import 'package:traffic_app/routes/app_pages.dart';

class HomeController extends GetxController with WidgetsBindingObserver {
  // Bottom Navigation State
  var currentIndex = 0.obs;
  final visitedTabs = <int>{0, 1}.obs;

  // Upload Progress State
  var isUploading = false.obs;
  var uploadProgress = 0.0.obs;
  var uploadLabel = 'Đăng bài viết'.obs;
  VoidCallback? _onCancelUpload;

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
    if (state == AppLifecycleState.resumed) {
      // Re-check when user returns from Settings after granting permission
      checkLocationStatus();
      if (currentIndex.value == 2 &&
          visitedTabs.contains(2) &&
          Get.isRegistered<CameraController>()) {
        Get.find<CameraController>().refreshLocationAndTime();
      }
    }
  }

  Future<void> _initLocationMonitoring() async {
    await checkLocationStatus();
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((
      status,
    ) {
      isLocationServiceDisabled.value = status == ServiceStatus.disabled;
      if (status == ServiceStatus.enabled) {
        // Re-check permission when GPS is re-enabled
        locationBannerDismissed.value = false;
        checkLocationStatus();
        if (currentIndex.value == 2 &&
            visitedTabs.contains(2) &&
            Get.isRegistered<CameraController>()) {
          Get.find<CameraController>().refreshLocationAndTime();
        }
      }
    });
  }

  Future<void> checkLocationStatus() async {
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
        if (currentIndex.value == 2 &&
            visitedTabs.contains(2) &&
            Get.isRegistered<CameraController>()) {
          Get.find<CameraController>().refreshLocationAndTime();
        }
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
    final wasVisited = visitedTabs.contains(index);
    visitedTabs.add(index);
    currentIndex.value = index;

    // Mỗi khi người dùng bấm chọn chức năng đăng bài (Tab Camera - index 2),
    // bắt buộc xóa vị trí cũ và load lại vị trí GPS hiện tại mới nhất
    if (index == 2 && wasVisited && Get.isRegistered<CameraController>()) {
      Get.find<CameraController>().refreshLocationAndTime();
    }
  }

  void goToEditProfile() {
    Get.toNamed(Routes.PROFILE);
  }

  // Upload Progress Methods
  void startUpload({
    String label = 'Đăng bài viết',
    VoidCallback? onCancel,
  }) {
    _onCancelUpload = onCancel;
    uploadLabel.value = label;
    isUploading.value = true;
    uploadProgress.value = 0.0;
  }

  void updateUploadProgress(double progress) {
    uploadProgress.value = progress;
  }

  void completeUpload() {
    _onCancelUpload = null;
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
    final cancelCallback = _onCancelUpload;
    _onCancelUpload = null;
    isUploading.value = false;
    uploadProgress.value = 0.0;
    cancelCallback?.call();
  }
}
