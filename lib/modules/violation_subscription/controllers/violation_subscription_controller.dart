import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';

import '../../../data/models/violation_subscription_model.dart';
import '../../../data/repositories/violation_subscription_repository.dart';
import '../../../services/storage_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/custom_dialog.dart';
import '../../../widgets/custom_text_field.dart';

class ViolationSubscriptionController extends GetxController {
  final ViolationSubscriptionRepository _repository;
  final StorageService? _storageService;

  ViolationSubscriptionController({
    ViolationSubscriptionRepository? repository,
    StorageService? storageService,
  })  : _repository = repository ?? ViolationSubscriptionRepository(),
        _storageService = storageService;

  StorageService get storageService {
    if (_storageService != null) return _storageService;
    if (Get.isRegistered<StorageService>()) {
      return StorageService.to;
    }
    return StorageService();
  }

  final plateController = TextEditingController();
  final receiveNotificationsForBoth = true.obs;

  // Trạng thái theo dõi: loading, loaded, submitting, error
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final subscriptions = <ViolationSubscription>[].obs;

  bool get hasSubscription => subscriptions.isNotEmpty;
  ViolationSubscription? get currentSubscription =>
      subscriptions.isNotEmpty ? subscriptions.first : null;

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

      // Kiểm tra biển số vừa được user chủ động hủy theo dõi (lưu trong local storage)
      String? unsubscribed;
      try {
        unsubscribed = storageService.getUnsubscribedPlate();
      } catch (_) {}

      var filteredList = list;
      if (unsubscribed != null && unsubscribed.trim().isNotEmpty) {
        final normUnsub = ViolationSubscription.normalizePlate(unsubscribed);
        filteredList = list
            .where((e) =>
                ViolationSubscription.normalizePlate(e.licensePlate) != normUnsub)
            .toList();
      }

      // Quy tắc duy nhất 1 biển số:
      // Nếu server trả về nhiều hơn 1 biển số (dữ liệu cũ từ trước):
      // Ưu tiên chọn biển số đang hoạt động (enabled == true), hoặc biển số mới nhất
      if (filteredList.length > 1) {
        final active = filteredList.where((e) => e.enabled).toList();
        if (active.isNotEmpty) {
          filteredList = [active.last];
        } else {
          filteredList = [filteredList.last];
        }
      }

      subscriptions.assignAll(filteredList);
      if (subscriptions.isNotEmpty) {
        receiveNotificationsForBoth.value = subscriptions.first.enabled;
      }
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// Đăng ký theo dõi biển số mới qua POST /violations/subscription
  /// Quy tắc: Mỗi tài khoản chỉ được đăng ký tối đa 1 biển số duy nhất.
  Future<void> registerSubscription() async {
    final rawInput = plateController.text.trim();
    if (rawInput.isEmpty) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: 'violation_sub_plate_empty'.tr,
        isError: true,
      );
      return;
    }

    final normalized = ViolationSubscription.normalizePlate(rawInput);
    if (!ViolationSubscription.isValidPlate(normalized)) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: 'violation_sub_plate_invalid'.tr,
        isError: true,
      );
      return;
    }

    // Nếu đã đăng ký 1 biển số rồi
    if (hasSubscription) {
      final current = currentSubscription!;
      if (current.licensePlate == normalized) {
        // Cùng biển số: cập nhật trạng thái thông báo nếu cần
        if (current.enabled != receiveNotificationsForBoth.value) {
          await toggleNotificationStatus(current, receiveNotificationsForBoth.value);
        } else {
          _showSnackbar(
            title: 'violation_sub_notice_title'.tr,
            message: 'violation_sub_plate_same'.tr,
            isError: false,
          );
        }
        plateController.clear();
        try {
          FocusManager.instance.primaryFocus?.unfocus();
        } catch (_) {}
        return;
      }

      // Khác biển số: Xác nhận đổi sang biển số mới (chỉ được 1 biển số duy nhất)
      confirmReplacePlate(
        oldPlate: current.licensePlate,
        newPlate: normalized,
        receiveNotifications: receiveNotificationsForBoth.value,
      );
      return;
    }

    if (isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      try {
        await storageService.clearUnsubscribedPlate();
      } catch (_) {}

      final message = await _repository.subscribe(
        licensePlate: normalized,
        receiveNotificationsForBoth: receiveNotificationsForBoth.value,
      );

      plateController.clear();
      try {
        FocusManager.instance.primaryFocus?.unfocus();
      } catch (_) {}

      _showSnackbar(
        title: 'signup_success_title'.tr,
        message: message.isNotEmpty ? message : 'violation_sub_success_register'.tr,
        isError: false,
      );

      // Cập nhật lại danh sách biển số đang theo dõi
      await loadSubscriptions();
    } catch (e) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: e.toString(),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Đổi sang biển số mới (thay thế biển số hiện tại để đảm bảo duy nhất 1 biển số)
  Future<void> changeSubscriptionPlate({
    required String newPlate,
    required bool receiveNotifications,
  }) async {
    final rawInput = newPlate.trim();
    if (rawInput.isEmpty) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: 'violation_sub_plate_empty'.tr,
        isError: true,
      );
      return;
    }

    final normalized = ViolationSubscription.normalizePlate(rawInput);
    if (!ViolationSubscription.isValidPlate(normalized)) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: 'violation_sub_plate_invalid'.tr,
        isError: true,
      );
      return;
    }

    final current = currentSubscription;
    if (current != null && current.licensePlate == normalized) {
      if (current.enabled != receiveNotifications) {
        await toggleNotificationStatus(current, receiveNotifications);
      } else {
        _showSnackbar(
          title: 'violation_sub_notice_title'.tr,
          message: 'violation_sub_plate_same'.tr,
          isError: false,
        );
      }
      return;
    }

    if (isSubmitting.value) return;

    isSubmitting.value = true;
    try {
      try {
        await storageService.clearUnsubscribedPlate();
      } catch (_) {}

      final message = await _repository.changePlate(
        oldPlate: current?.licensePlate ?? '',
        newPlate: normalized,
        receiveNotificationsForBoth: receiveNotifications,
      );

      plateController.clear();
      try {
        FocusManager.instance.primaryFocus?.unfocus();
      } catch (_) {}

      _showSnackbar(
        title: 'signup_success_title'.tr,
        message: message.isNotEmpty ? message : 'violation_sub_change_success'.tr,
        isError: false,
      );

      await loadSubscriptions();
    } catch (e) {
      _showSnackbar(
        title: 'error_title'.tr,
        message: e.toString(),
        isError: true,
      );
      await loadSubscriptions();
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Xác nhận đổi sang biển số mới khi người dùng đã có biển số đăng ký
  void confirmReplacePlate({
    required String oldPlate,
    required String newPlate,
    required bool receiveNotifications,
  }) {
    final oldModel = ViolationSubscription(licensePlate: oldPlate);
    final newModel = ViolationSubscription(licensePlate: newPlate);

    Get.dialog(
      CustomDialog(
        title: 'violation_sub_replace_confirm_title'.tr,
        message: 'violation_sub_replace_confirm_msg'.trParams({
          'oldPlate': oldModel.formattedPlate,
          'newPlate': newModel.formattedPlate,
        }),
        type: DialogType.warning,
        buttonText: 'violation_sub_replace_action'.tr,
        cancelText: 'violation_sub_cancel'.tr,
        onPressed: () {
          Get.back();
          changeSubscriptionPlate(
            newPlate: newPlate,
            receiveNotifications: receiveNotifications,
          );
        },
        onCancel: () => Get.back(),
      ),
    );
  }

  /// Mở dialog để người dùng đổi biển số xe theo dõi
  void showChangePlateDialog(BuildContext context) {
    final current = currentSubscription;
    if (current == null) return;

    final editController = TextEditingController(text: current.licensePlate);
    final editNotify = current.enabled.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        backgroundColor: Colors.white,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      IconlyBroken.edit,
                      color: AppTheme.primaryColor,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'violation_sub_change_plate_title'.tr,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'violation_sub_change_plate_desc'.trParams({'oldPlate': current.formattedPlate}),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: AppTheme.subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              CustomTextField(
                hintText: 'violation_sub_plate_hint'.tr,
                prefixIcon: IconlyBroken.edit,
                controller: editController,
                textCapitalization: TextCapitalization.characters,
                height: 48.h,
              ),
              SizedBox(height: 12.h),
              Obx(
                () => Row(
                  children: [
                    Icon(
                      IconlyBroken.notification,
                      size: 16.sp,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'violation_sub_notify_toggle'.tr,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppTheme.textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: editNotify.value,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => editNotify.value = val,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppTheme.dividerColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'violation_sub_cancel'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.subTextColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final newPlate = editController.text.trim();
                        if (newPlate.isEmpty) {
                          _showSnackbar(
                            title: 'error_title'.tr,
                            message: 'violation_sub_plate_empty'.tr,
                            isError: true,
                          );
                          return;
                        }
                        Get.back();
                        await changeSubscriptionPlate(
                          newPlate: newPlate,
                          receiveNotifications: editNotify.value,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        'violation_sub_change_plate_confirm'.tr,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bật/tắt trạng thái nhận thông báo cho biển số xe
  Future<void> toggleNotificationStatus(
    ViolationSubscription item,
    bool newValue,
  ) async {
    final cleanPlate = ViolationSubscription.normalizePlate(item.licensePlate);
    final index = subscriptions.indexWhere(
        (e) => ViolationSubscription.normalizePlate(e.licensePlate) == cleanPlate);
    if (index == -1) return;

    final oldItem = subscriptions[index];
    subscriptions[index] = oldItem.copyWith(enabled: newValue);
    receiveNotificationsForBoth.value = newValue;

    try {
      if (newValue) {
        // Bật thông báo: POST /violations/subscription (kích hoạt enabled = true)
        await _repository.subscribe(
          licensePlate: cleanPlate,
          receiveNotificationsForBoth: true,
        );
        try {
          await storageService.clearUnsubscribedPlate();
        } catch (_) {}
      } else {
        // Tắt thông báo: DELETE /violations/subscription/{plate} (backend soft-disable: enabled = false)
        await _repository.unsubscribe(cleanPlate);
      }

      _showSnackbar(
        title: 'signup_success_title'.tr,
        message: 'violation_sub_success_update'.tr,
        isError: false,
      );
    } catch (e) {
      subscriptions[index] = oldItem;
      receiveNotificationsForBoth.value = oldItem.enabled;
      _showSnackbar(
        title: 'error_title'.tr,
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
    final cleanPlate = ViolationSubscription.normalizePlate(licensePlate);
    try {
      final message = await _repository.unsubscribe(cleanPlate);

      // Lưu lại biển số vừa hủy vào StorageService để khi loadSubscriptions() (hoặc pull-to-refresh)
      // không bị hiển thị lại biển số đã soft-disable từ backend
      try {
        await storageService.setUnsubscribedPlate(cleanPlate);
      } catch (_) {}

      subscriptions.removeWhere(
        (e) =>
            ViolationSubscription.normalizePlate(e.licensePlate) == cleanPlate,
      );

      _showSnackbar(
        title: 'signup_success_title'.tr,
        message: message.isNotEmpty
            ? message
            : 'violation_sub_success_delete'.trParams({'plate': licensePlate}),
        isError: false,
      );
    } catch (e) {
      _showSnackbar(
        title: 'error_title'.tr,
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
      if (subscriptions.isNotEmpty) {
        try {
          await storageService.setUnsubscribedPlate(
              ViolationSubscription.normalizePlate(subscriptions.first.licensePlate));
        } catch (_) {}
      }
      subscriptions.clear();

      _showSnackbar(
        title: 'signup_success_title'.tr,
        message: message.isNotEmpty ? message : 'violation_sub_success_delete_all'.tr,
        isError: false,
      );
    } catch (e) {
      _showSnackbar(
        title: 'error_title'.tr,
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
    if (Get.testMode) return;
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
