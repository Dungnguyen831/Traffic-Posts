import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/login_request.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_pages.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_dialog.dart';
import '../../emergency/controllers/emergency_controller.dart';

class LoginController extends GetxController {
  var rememberMe = false.obs;
  var isLoading = false.obs;
  var isPasswordHidden = true.obs;

  final AuthRepository _authRepository = Get.find<AuthRepository>();
  final StorageService _storageService = Get.find<StorageService>();

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  FocusNode usernameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    _initControllers();

    // Clear focus and keyboard state on init to prevent keyboard event issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      usernameFocusNode.unfocus();
      passwordFocusNode.unfocus();
    });
  }

  void _initControllers() {
    usernameController = TextEditingController();
    passwordController = TextEditingController();
    usernameFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
  }

  void clearControllers() {
    usernameController.clear();
    passwordController.clear();
  }

  @override
  void onClose() {
    // Unfocus before closing to clear keyboard state
    usernameFocusNode.unfocus();
    passwordFocusNode.unfocus();
    // Do not call dispose() on text controllers here to prevent
    // 'TextEditingController was used after being disposed' crash
    // if LoginController is reused across navigation/logout cycles.
    super.onClose();
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  Future<void> login() async {
    // Unfocus all text fields to hide keyboard and clear keyboard state
    usernameFocusNode.unfocus();
    passwordFocusNode.unfocus();

    if (usernameController.text.isEmpty || passwordController.text.isEmpty) {
      CustomDialog.show(
        title: 'notice_title'.tr,
        message: 'login_fill_info'.tr,
        type: DialogType.warning,
      );
      return;
    }

    isLoading.value = true;

    try {
      final loginResponse = await _authRepository.login(
        LoginRequest(
          username: usernameController.text.trim(),
          password: passwordController.text,
        ),
      );

      // Save user information
      await _storageService.saveUserInfo(
        userId: loginResponse.id,
        username: loginResponse.username,
        fullname: loginResponse.fullname,
        province: loginResponse.province,
        relativePhone: loginResponse.relativePhone,
        phoneNumber: loginResponse.phoneNumber,
        reputationScore: loginResponse.reputationScore,
        badge: loginResponse.badge,
        canCreatePost: loginResponse.canCreatePost,
      );

      debugPrint('==== 🕵️ KIỂM TRA KHO LƯU TRỮ SAU KHI ĐĂNG NHẬP ====');
      debugPrint('ID: ${StorageService.to.getUserId()}');
      debugPrint('Username: ${StorageService.to.getUsername()}');
      debugPrint('Họ và tên: ${StorageService.to.getFullName()}');
      debugPrint('SĐT Người thân: ${StorageService.to.getRelativePhone()}');
      debugPrint('👉 SĐT CỦA TÔI: ${StorageService.to.getPhoneNumber()}');
      debugPrint('===================================================');

      // Save credentials for auto-login if rememberMe is checked
      if (rememberMe.value) {
        await _storageService.saveCredentials(
          usernameController.text.trim(),
          passwordController.text,
        );
      } else {
        await _storageService.clearCredentials();
      }

      // Kiểm tra và khôi phục ngay phiên SOS của userId vừa đăng nhập (nếu EmergencyController đã đăng ký)
      if (Get.isRegistered<EmergencyController>()) {
        await Get.find<EmergencyController>().checkAndRestoreActiveSos(
          targetUserId: loginResponse.id,
        );
      }

      // Navigate to home page on successful login
      Get.offAllNamed(Routes.HOME);
    } catch (e) {
      CustomDialog.show(
        title: 'login_failed_title'.tr,
        message: e.toString(),
        type: DialogType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }
}