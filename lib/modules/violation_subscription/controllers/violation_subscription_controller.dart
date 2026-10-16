import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../data/models/violation_subscription_model.dart';
import '../../../data/repositories/violation_subscription_repository.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dialog.dart';

class ViolationSubscriptionController extends GetxController {
  final ViolationSubscriptionRepository _repository;

  ViolationSubscriptionController({
    ViolationSubscriptionRepository? repository,
  }) : _repository = repository ?? ViolationSubscriptionRepository();

  final plateController = TextEditingController();
  final receiveNotificationsForBoth = true.obs;

  // Trạng thái theo yêu cầu: loading, loaded, submitting, error
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final subscriptions = <ViolationSubscription>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Tự động tải danh sách biển số đang theo dõi khi mở màn hình
    loadSubscriptions();
  }

  /// Tải danh sách biển số đang theo dõi từ GET /violations/subscription
  Future<void> loadSubscriptions() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final list = await _repository.getSubscriptions();
      subscriptions.assignAll(list);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Đăng ký theo dõi biển số mới qua POST /violations/subscription
  Future<void> registerSubscription() async {
    final rawInput = plateController.text.trim();
    if (rawInput.isEmpty) {
      _showSnackbar(
        title: 'Lỗi',
        message: 'violation_sub_plate_empty'.tr,
        isError: true,
      );
      return;
    }

    final normalized = ViolationSubscription.normalizePlate(rawInput);
    if (!ViolationSubscription.isValidPlate(normalized)) {
      _showSnackbar(
        title: 'Lỗi',
        message: 'violation_sub_plate_invalid'.tr,
        isError: true,
      );
      return;
    }

    if (isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      final message = await _repository.subscribe(
        licensePlate: normalized,
        receiveNotificationsForBoth: receiveNotificationsForBoth.value,
      );

      plateController.clear();
      FocusManager.instance.primaryFocus?.unfocus();

      _showSnackbar(
        title: 'Thành công',
        message: message.isNotEmpty ? message : 'violation_sub_success_register'.tr,
        isError: false,
      );

      // Cập nhật lại danh sách biển số đang theo dõi
      await loadSubscriptions();
    } catch (e) {
      _showSnackbar(
        title: 'Không thể đăng ký',
        message: e.toString(),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Bật/tắt trạng thái nhận thông báo cho biển số xe
  Future<void> toggleNotificationStatus(
    ViolationSubscription item,
    bool newValue,
  ) async {
    // Lưu lại trạng thái cũ để rollback nếu gọi API thất bại
    final index = subscriptions.indexWhere((e) => e.licensePlate == item.licensePlate);
    if (index == -1) return;

    final oldItem = subscriptions[index];
    subscriptions[index] = oldItem.copyWith(enabled: newValue);

    try {
      await _repository.subscribe(
        licensePlate: item.licensePlate,
        receiveNotificationsForBoth: newValue,
      );

      _showSnackbar(
        title: 'Thành công',
        message: 'violation_sub_success_update'.tr,
        isError: false,
      );
    } catch (e) {
      // Rollback nếu thất bại
      subscriptions[index] = oldItem;
      _showSnackbar(
        title: 'Thất bại',
        message: e.toString(),
        isError: true,
      );
    }
  }

  /// Xác nhận và hủy theo dõi một biển số xe DELETE /violations/subscription/{licensePlate}
  void confirmDeleteSubscription(ViolationSubscription item) {
    Get.dialog(
      CustomDialog(
        title: 'violation_sub_delete_confirm_title'.tr,
        message: 'violation_sub_delete_confirm_msg'.trParams({'plate': item.formattedPlate}),
        type: DialogType.warning,
        buttonText: 'violation_sub_delete_action'.tr,
        cancelText: 'violation_sub_cancel'.tr,
        onPressed: () {
          Get.back();
          _executeDeleteSubscription(item.licensePlate);
        },
        onCancel: () => Get.back(),
      ),
    );
  }

  Future<void> _executeDeleteSubscription(String licensePlate) async {
    isSubmitting.value = true;
    try {
      final message = await _repository.unsubscribe(licensePlate);
      subscriptions.removeWhere(
        (e) =>
            ViolationSubscription.normalizePlate(e.licensePlate) ==
            ViolationSubscription.normalizePlate(licensePlate),
      );

      _showSnackbar(
        title: 'Thành công',
        message: message.isNotEmpty
            ? message
            : 'violation_sub_success_delete'.trParams({'plate': licensePlate}),
        isError: false,
      );
    } catch (e) {
      _showSnackbar(
        title: 'Thất bại',
        message: e.toString(),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Xác nhận và hủy toàn bộ danh sách đăng ký theo dõi DELETE /violations/subscription
  void confirmDeleteAllSubscriptions() {
    if (subscriptions.isEmpty) return;

    Get.dialog(
      CustomDialog(
        title: 'violation_sub_delete_all_confirm_title'.tr,
        message: 'violation_sub_delete_all_confirm_msg'.tr,
        type: DialogType.error,
        buttonText: 'violation_sub_delete_all_action'.tr,
        cancelText: 'violation_sub_cancel'.tr,
        onPressed: () {
          Get.back();
          _executeDeleteAllSubscriptions();
        },
        onCancel: () => Get.back(),
      ),
    );
  }

  Future<void> _executeDeleteAllSubscriptions() async {
    isSubmitting.value = true;
    try {
      final message = await _repository.unsubscribeAll();
      subscriptions.clear();

      _showSnackbar(
        title: 'Thành công',
        message: message.isNotEmpty ? message : 'violation_sub_success_delete_all'.tr,
        isError: false,
      );
    } catch (e) {
      _showSnackbar(
        title: 'Thất bại',
        message: e.toString(),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  void _showSnackbar({
    required String title,
    required String message,
    required bool isError,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: EdgeInsets.all(16.r),
      borderRadius: 12.r,
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
    );
  }

  @override
  void onClose() {
    plateController.dispose();
    super.onClose();
  }
}
