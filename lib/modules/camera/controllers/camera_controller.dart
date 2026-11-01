import 'dart:io';

import 'package:dio/dio.dart';
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

enum ImageModerationStatus { none, checking, valid, invalid, error }

class CameraController extends GetxController {
  ImagePicker get _picker => ImagePickerService.to.picker;
  final TrafficPostRepository _repository = TrafficPostRepository();

  final hasImage = false.obs;
  final imagePath = ''.obs;
  final contentController = TextEditingController();

  final moderationStatus = ImageModerationStatus.none.obs;
  final moderationMessage = ''.obs;
  CancelToken? _moderationCancelToken;

  bool get isImageValid =>
      hasImage.value && moderationStatus.value == ImageModerationStatus.valid;

  final availableHashtags = ['ketxe', 'tainan', 'ngaplutnuoc', 'baocaotainan'];
  final selectedHashtags = <String>[].obs;

  void toggleHashtag(String tag) {
    if (selectedHashtags.contains(tag)) {
      selectedHashtags.remove(tag);
    } else {
      selectedHashtags.add(tag);
    }
  }

  void clearImage() {
    _moderationCancelToken?.cancel('Image cleared by user');
    _moderationCancelToken = null;
    hasImage.value = false;
    imagePath.value = '';
    moderationStatus.value = ImageModerationStatus.none;
    moderationMessage.value = '';
  }

  final time = ''.obs;
  final location = 'camera_loading_location'.tr.obs;
  final currentLat = 0.0.obs;
  final currentLng = 0.0.obs;
  final isLoadingLocation = false.obs;
  Future<void>? _locationLoadFuture;

  final canCreatePost = true.obs;

  @override
  void onInit() {
    super.onInit();
    refreshLocationAndTime();
  }

  /// Làm mới thời gian và tải lại vị trí GPS hiện tại (xóa vị trí cũ để tránh dùng lại tọa độ cũ)
  Future<void> refreshLocationAndTime() {
    checkCanCreatePost();
    _updateTime();
    currentLat.value = 0.0;
    currentLng.value = 0.0;
    location.value = 'camera_loading_location'.tr;

    final future = _getCurrentLocation();
    _locationLoadFuture = future;
    return future;
  }

  void checkCanCreatePost() {
    canCreatePost.value = StorageService.to.canCreatePost();
  }

  @override
  void onClose() {
    _moderationCancelToken?.cancel('Controller disposed');
    contentController.dispose();
    super.onClose();
  }

  void _updateTime() {
    final now = DateTime.now();
    time.value = DateFormat('HH:mm dd/MM/yyyy').format(now);
  }

  Future<void> _getCurrentLocation() async {
    isLoadingLocation.value = true;
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

      // Lấy vị trí hiện tại mới nhất từ GPS
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
    } finally {
      isLoadingLocation.value = false;
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
        refreshLocationAndTime(); // Cập nhật lại thời gian và vị trí mới khi chụp ảnh
        await validateSelectedImage();
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
        refreshLocationAndTime(); // Cập nhật lại thời gian và vị trí mới khi chọn ảnh
        await validateSelectedImage();
      }
    } catch (e) {
      CustomAlert.showError('${'cannot_pick_image'.tr}: $e');
    }
  }

  /// Kiểm duyệt hình ảnh ngay sau khi chụp hoặc chọn từ thư viện
  Future<void> validateSelectedImage() async {
    final currentPath = imagePath.value;
    if (currentPath.isEmpty || !hasImage.value) return;

    _moderationCancelToken?.cancel('New image moderation started');
    final cancelToken = CancelToken();
    _moderationCancelToken = cancelToken;

    moderationStatus.value = ImageModerationStatus.checking;
    moderationMessage.value = '';

    try {
      final isValid = await _repository.verifyTrafficImage(
        currentPath,
        cancelToken: cancelToken,
      );

      if (cancelToken.isCancelled || imagePath.value != currentPath) return;

      if (isValid) {
        moderationStatus.value = ImageModerationStatus.valid;
        moderationMessage.value = '';
      } else {
        moderationStatus.value = ImageModerationStatus.invalid;
        moderationMessage.value = 'camera_image_invalid_message'.tr;
        CustomAlert.showError('camera_image_invalid_alert'.tr);
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) || imagePath.value != currentPath) return;
      moderationStatus.value = ImageModerationStatus.error;
      moderationMessage.value = 'camera_image_moderation_error'.tr;
      CustomAlert.showError('camera_image_moderation_error'.tr);
    } catch (e) {
      if (imagePath.value != currentPath) return;
      moderationStatus.value = ImageModerationStatus.error;
      moderationMessage.value = 'camera_image_moderation_error'.tr;
      CustomAlert.showError('camera_image_moderation_error'.tr);
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
      if (moderationStatus.value == ImageModerationStatus.checking) {
        return;
      }
      if (moderationStatus.value == ImageModerationStatus.invalid) {
        CustomAlert.showError('camera_image_invalid_alert'.tr);
        return;
      }
      if (moderationStatus.value == ImageModerationStatus.error) {
        validateSelectedImage();
        return;
      }
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

    if (moderationStatus.value != ImageModerationStatus.valid) {
      CustomAlert.showError('camera_image_invalid_alert'.tr);
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

    // Nếu tiến trình tải vị trí mới đang diễn ra thì chờ hoàn tất trước khi kiểm tra
    if (isLoadingLocation.value && _locationLoadFuture != null) {
      await _locationLoadFuture;
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

    final uploadCancelToken = CancelToken();

    // Bắt đầu hiển thị progress kèm callback hủy request thực sự
    homeController.startUpload(
      onCancel: () {
        if (!uploadCancelToken.isCancelled) {
          uploadCancelToken.cancel('Upload cancelled by user');
        }
      },
    );

    // Reset form và xóa tọa độ cũ
    final imagePathTemp = imagePath.value;
    hasImage.value = false;
    imagePath.value = '';
    moderationStatus.value = ImageModerationStatus.none;
    moderationMessage.value = '';
    contentController.clear();
    selectedHashtags.clear();
    currentLat.value = 0.0;
    currentLng.value = 0.0;
    location.value = 'camera_loading_location'.tr;

    // Upload
    _uploadInIsolate(
      postData,
      homeController,
      imagePathTemp,
      uploadCancelToken,
    );
  }

  void _uploadInIsolate(
    Map<String, dynamic> postData,
    HomeController homeController,
    String imagePathTemp,
    CancelToken cancelToken,
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
          cancelToken: cancelToken,
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
          if (error is DioException && CancelToken.isCancel(error)) {
            return;
          }
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
