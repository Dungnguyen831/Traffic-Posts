import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traffic_app/widgets/custom_alert.dart';
import 'package:traffic_app/widgets/custom_dialog.dart';

import '../../../data/models/profile_request.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/api_service.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';
import '../../emergency/controllers/emergency_controller.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../login/controllers/login_controller.dart';
import '../../home/controllers/home_controller.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepository = UserRepository();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final relativePhoneController = TextEditingController();

  var isLoading = false.obs;

  var selectedImagePath = ''.obs;
  var currentAvatarUrl = ''.obs;

  // Provinces data
  var provinces = <Map<String, dynamic>>[].obs;
  var selectedProvince = Rxn<Map<String, dynamic>>();

  final ImagePicker _picker = ImagePicker();

  // Flag để kiểm tra dữ liệu đã được load chưa
  var isDataLoaded = false.obs;
  var isProvincesLoaded = false.obs;

  // Điểm uy tín và huy hiệu
  var reputationScore = StorageService.to.getReputationScore().obs;
  var badge = StorageService.to.getBadge().obs;
  var canCreatePost = StorageService.to.canCreatePost().obs;

  @override
  void onInit() {
    super.onInit();
    // Load provinces và profile song song, không block UI
    _initData();
  }

  Future<void> _initData() async {
    // Load cả 2 song song để tối ưu thời gian
    await Future.wait([loadProvinces(), loadUserProfile()]);
  }

  Future<void> loadProvinces() async {
    if (isProvincesLoaded.value) return;

    try {
      final String response = await rootBundle.loadString(
        'assets/json/provinces.json',
      );
      final List<dynamic> data = json.decode(response);
      final List<Map<String, dynamic>> mappedData = data
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      provinces.assignAll(mappedData);
      isProvincesLoaded.value = true;
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    relativePhoneController.dispose();
    super.onClose();
  }

  /// Load thông tin người dùng từ API
  /// [forceRefresh] = true sẽ bắt buộc call API lại
  Future<void> loadUserProfile({bool forceRefresh = false}) async {
    // Nếu đã load dữ liệu và không yêu cầu refresh thì không call API nữa
    if (isDataLoaded.value && !forceRefresh) {
      return;
    }

    try {
      isLoading.value = true;

      final user = await _userRepository.getProfile();

      nameController.text = user.fullname ?? "";
      emailController.text = user.email ?? "";
      phoneController.text = user.phoneNumber ?? "";
      addressController.text = user.province ?? "";
      relativePhoneController.text = user.relativePhone ?? "";

      final score = user.reputationScore ?? 100;
      final badgeName = user.badge ?? 'Người dẫn đường';
      final canPost = user.canCreatePost ?? (score >= 80);

      reputationScore.value = score;
      badge.value = badgeName;
      canCreatePost.value = canPost;

      StorageService.to.saveUserInfo(
        fullname: user.fullname,
        province: user.province,
        relativePhone: user.relativePhone,
        phoneNumber: user.phoneNumber,
        reputationScore: score,
        badge: badgeName,
        canCreatePost: canPost,
      );

      // Set selected province
      if (user.province != null && user.province!.isNotEmpty) {
        // Wait for provinces to load if empty
        if (!isProvincesLoaded.value) {
          await loadProvinces();
        }

        final province = provinces.firstWhere(
          (element) => element['name'] == user.province?.trim(),
          orElse: () => {},
        );

        if (province.isNotEmpty) {
          selectedProvince.value = province;
        }
      }

      if (user.avatarUrl != null && user.avatarUrl!.isNotEmpty) {
        currentAvatarUrl.value =
            "${user.avatarUrl}?t=${DateTime.now().millisecondsSinceEpoch}";
      } else {
        currentAvatarUrl.value = "";
      }

      // Đánh dấu đã load dữ liệu thành công
      isDataLoaded.value = true;
    } catch (e) {
      CustomDialog.show(
        title: 'error_title'.tr,
        message: '${'profile_load_error_message'.tr}: $e',
        type: DialogType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveProfile() async {
    FocusManager.instance.primaryFocus?.unfocus();

    if (emailController.text.isEmpty) {
      CustomDialog.show(
        title: 'notice_title'.tr,
        message: 'profile_email_empty'.tr,
        type: DialogType.warning,
      );
      return;
    }

    if (nameController.text.isEmpty) {
      CustomDialog.show(
        title: 'notice_title'.tr,
        message: 'profile_name_empty'.tr,
        type: DialogType.warning,
      );
      return;
    }

    if (selectedProvince.value == null) {
      CustomDialog.show(
        title: 'notice_title'.tr,
        message: 'profile_province_empty'.tr,
        type: DialogType.warning,
      );
      return;
    }
    try {
      final homeController = Get.find<HomeController>();
      homeController.startUpload(label: 'profile_upload_label'.tr);
      Get.back(); // Quay về home ngay lập tức, không đợi API

      final updatedUser = ProfileRequest(
        fullname: nameController.text.trim(),
        email: emailController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        province: selectedProvince.value!['name'],
        relativePhone: relativePhoneController.text.trim(),
      );
      File? imageFile;
      if (selectedImagePath.value.isNotEmpty) {
        imageFile = File(selectedImagePath.value);
      }

      await _userRepository.updateProfile(
        updatedUser,
        imageFile,
        onSendProgress: (sent, total) {
          if (total > 0) homeController.updateUploadProgress(sent / total);
        },
      );

      await StorageService.to.saveUserInfo(
        fullname: updatedUser.fullname,
        province: updatedUser.province,
        relativePhone: updatedUser.relativePhone,
        phoneNumber: updatedUser.phoneNumber,
        reputationScore: reputationScore.value,
        badge: badge.value,
        canCreatePost: canCreatePost.value,
      );

      homeController.completeUpload();
      selectedImagePath.value = '';

      CustomAlert.showSuccess('profile_update_success'.tr);

      // Sau khi update profile, force refresh để lấy dữ liệu mới
      loadUserProfile(forceRefresh: true);
    } catch (e) {
      Get.find<HomeController>().cancelUpload();
      CustomAlert.showError('${'profile_update_error'.tr}: $e');
    }
  }

  Future<void> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 800,
      );
      if (image != null) {
        selectedImagePath.value = image.path;
      }
    } catch (e) {
      CustomDialog.show(
        title: 'error_title'.tr,
        message: '${'cannot_pick_image'.tr}: $e',
        type: DialogType.error,
      );
    }
  }

  void logout() {
    CustomDialog.showConfirm(
      context: Get.context!,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất không?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      type: DialogType.warning,
      onConfirm: () async {
        final storage = StorageService.to;
        await storage.removeToken();
        await storage.clearCredentials();
        await storage.clearUserInfo();
        await storage.clearActiveSos();
        ApiService().clearToken();

        // Xóa các controller cache / permanent để tránh rò rỉ dữ liệu hoặc dùng lại controller đã đóng
        if (Get.isRegistered<EmergencyController>()) {
          Get.find<EmergencyController>().resetSosState();
          Get.delete<EmergencyController>(force: true);
        }
        if (Get.isRegistered<LoginController>()) {
          Get.delete<LoginController>(force: true);
        }
        if (Get.isRegistered<ProfileController>()) {
          Get.delete<ProfileController>(force: true);
        }
        if (Get.isRegistered<SosStreamService>()) {
          Get.delete<SosStreamService>(force: true);
        }

        Get.offAllNamed(Routes.LOGIN);
      },
    );
  }
}
