import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/traffic_post_repository.dart';
import '../../../services/image_picker_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_alert.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class CameraController extends GetxController {
  ImagePicker get _picker => ImagePickerService.to.picker;
  final TrafficPostRepository _repository = TrafficPostRepository();

  final hasImage = false.obs;
  final imagePath = ''.obs;
  final contentController = TextEditingController();

  final availableHashtags = ['ketxe', 'tainan', 'ngaplutnuoc', 'baocaotainan', 'sos'];
  final selectedHashtags = <String>[].obs;

  void toggleHashtag(String tag) {
    if (selectedHashtags.contains(tag)) {
      selectedHashtags.remove(tag);
    } else {
      selectedHashtags.add(tag);
    }
  }

  void clearImage() {
    hasImage.value = false;
    imagePath.value = '';
  }

  final time = ''.obs;
  final location = 'camera_loading_location'.tr.obs;
  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;

  final canCreatePost = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkCanCreatePost();
    _updateTime();
    _getCurrentLocation();
  }

  void checkCanCreatePost() {
    canCreatePost.value = StorageService.to.canCreatePost();
  }

  @override
  void onClose() {
    contentController.dispose();
    super.onClose();
  }

  void _updateTime() {
    final now = DateTime.now();
    time.value = DateFormat('HH:mm dd/MM/yyyy').format(now);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra dịch vụ vị trí có được bật không
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        location.value = 'map_location_service_disabled'.tr;
        return;
      }

      // Kiểm tra permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          location.value = 'camera_no_location_permission'.tr;
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        location.value = 'camera_no_location_permission'.tr;
        return;
      }

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      currentLat.value = position.latitude;
      currentLng.value = position.longitude;

      // Lấy địa chỉ từ tọa độ
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final address = [
            place.street,
            place.subAdministrativeArea,
            place.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');

          location.value = address.isNotEmpty
              ? address
              : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        location.value =
            '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
      }
    } catch (e) {
      location.value = 'cannot_get_location'.tr;
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        imagePath.value = image.path;
        hasImage.value = true;
        _updateTime(); // Cập nhật thời gian khi chụp ảnh
      }
    } catch (e) {
      CustomAlert.showError('${'camera_cannot_capture'.tr}: $e');
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        imagePath.value = image.path;
        hasImage.value = true;
        _updateTime();
      }
    } catch (e) {
      CustomAlert.showError('${'cannot_pick_image'.tr}: $e');
    }
  }

  void onActionTap() {
    checkCanCreatePost();
    if (!canCreatePost.value) {
      CustomAlert.showWarning(
        'reputation_cannot_post_alert'.tr,
        duration: const Duration(seconds: 4),
      );
      return;
    }
    if (hasImage.value) {
      _sendPost();
    } else {
      captureImage();
    }
  }

  Future<void> _sendPost() async {
    if (!StorageService.to.canCreatePost()) {
      CustomAlert.showWarning(
        'reputation_cannot_post_alert'.tr,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (contentController.text.trim().isEmpty) {
      CustomAlert.showWarning('camera_please_enter_content'.tr);
      return;
    }

    if (selectedHashtags.isEmpty) {
      CustomAlert.showWarning('camera_please_select_hashtag'.tr);
      return;
    }

    if (currentLat.value == 0.0 || currentLng.value == 0.0) {
      // Trigger the location banner in HomeView so user can grant permission
      final homeController = Get.find<HomeController>();
      homeController.locationBannerDismissed.value = false;
      homeController.checkLocationStatus();
      CustomAlert.showError('camera_cannot_get_current_location'.tr);
      return;
    }

    // Lấy HomeController để hiển thị progress
    final homeController = Get.find<HomeController>();

    // Chuẩn bị data
    final postData = {
      'type': 'TRAFFIC_JAM', // Có thể customize
      'content': contentController.text.trim(),
      'lat': currentLat.value,
      'lng': currentLng.value,
      'address': location.value,
      'hashtags': List<String>.from(selectedHashtags),
      'status': 'TRAFFIC_REPORT',
      'filePath': imagePath.value,
    };

    // Chuyển về tab home
    homeController.changeTab(0);

    // Bắt đầu hiển thị progress
    homeController.startUpload();

    // Reset form
    final imagePathTemp = imagePath.value;
    hasImage.value = false;
    imagePath.value = '';
    contentController.clear();
    selectedHashtags.clear();

    // Upload trong isolate
    _uploadInIsolate(postData, homeController, imagePathTemp);
  }

  void _uploadInIsolate(
    Map<String, dynamic> postData,
    HomeController homeController,
    String imagePathTemp,
  ) {
    _repository
        .createPost(
          type: postData['type'] as String,
          content: postData['content'] as String,
          lat: postData['lat'] as double,
          lng: postData['lng'] as double,
          address: postData['address'] as String,
          hashtags: postData['hashtags'] as List<String>,
          status: postData['status'] as String,
          filePath: imagePathTemp,
          onSendProgress: (sent, total) {
            if (total > 0) {
              final progress = sent / total;
              homeController.updateUploadProgress(progress);
            }
          },
        )
        .then((post) {
          homeController.completeUpload();
          // Nếu đang ở tab home (index 0), chèn bài viết vừa đăng lên đầu danh sách
          // mà không rebuild lại toàn bộ trang — chỉ RxList thay đổi → chỉ ListView rebuild
          final dashboardController = Get.find<DashboardController>();
          if (homeController.currentIndex.value == 0) {
            dashboardController.prependPost(post);
          }
          // Refresh profile để cập nhật điểm mới nhất sau khi đăng bài
          if (Get.isRegistered<ProfileController>()) {
            Get.find<ProfileController>().loadUserProfile(forceRefresh: true);
          }
          CustomAlert.showSuccess('camera_post_success'.tr);
        })
        .catchError((error) {
          homeController.cancelUpload();
          CustomAlert.showError(
            '${'camera_cannot_post'.tr}: $error',
            duration: const Duration(seconds: 3),
          );
        });
  }

  File? get imageFile {
    if (imagePath.value.isEmpty) return null;
    return File(imagePath.value);
  }
}
