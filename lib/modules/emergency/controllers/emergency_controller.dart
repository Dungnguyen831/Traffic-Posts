import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../../config/demo_config.dart';
import '../../../data/repositories/sos_repository.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../services/storage_service.dart';
import '../../../widgets/custom_alert.dart';
import '../views/sos_active_screen.dart';

class EmergencyController extends GetxController {
  var selectedOption = 0.obs;
  var isLoading = false.obs;
  var activeSosId = ''.obs;

  final TextEditingController noteController = TextEditingController();
  final SosRepository _sosRepo = SosRepository();

  void selectOption(int index) {
    selectedOption.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    // Vừa mở app lên là đi tìm xem mình có SOS nào đang chạy trên Server không
    _checkMyActiveSosFromServer();
  }

  Future<void> onContinue() async {
    if (selectedOption.value == 0) {
      final String relativePhone = (StorageService.to.getRelativePhone() ?? '')
          .trim();

      if (relativePhone.isEmpty) {
        CustomAlert.showWarning('emergency_notification_mesg_1'.tr);
        await _makePhoneCall(''); 
      } else {
        await _makePhoneCall(relativePhone);
      }
    } else if (selectedOption.value == 1) {
      // 2. GỌI CỨU THƯƠNG (Mặc định là 115)
      await _makePhoneCall('115');
    }
  }

  // Hàm xử lý gọi điện dùng chung
  Future<void> _makePhoneCall(String phoneNumber) async {
    if (DemoConfig.isDemoMode) {
      CustomAlert.showSuccess('Mô phỏng cuộc gọi khẩn cấp đến: $phoneNumber');
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      } else {
        CustomAlert.showError('emergency_notification_mesg_2'.tr);
      }
    } catch (e) {
      CustomAlert.showError('emergency_notification_mesg_3'.tr);
    }
  }

  // Hàm tự động check SOS của chính mình từ Server
  Future<void> _checkMyActiveSosFromServer() async {
    try {
      final myPhone = StorageService.to.getPhoneNumber() ?? 
                      StorageService.to.getUsername() ?? '';
      
      if (myPhone.isEmpty) return;

      final actives = await _sosRepo.getActiveSosAlerts();

      for (final sos in actives) {
        // So sánh chính xác với số điện thoại đã lưu
        if (sos.phoneNumber == myPhone) {
          activeSosId.value = sos.sosId; 
          debugPrint('🔄 Đã khớp SOS của tôi: ${sos.sosId}');
          break;
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra SOS: $e');
    }
  }

  /// Hàm chạy khi người dùng bấm "Phát tín hiệu" trong Dialog nhập ghi chú
  Future<void> sendSosAlert() async {
    final note = noteController.text.trim();
    if (note.isEmpty) {
      CustomAlert.showWarning('Vui lòng nhập chi tiết sự cố');
      return;
    }

    try {
      isLoading.value = true;
      
      // Lấy tọa độ (Demo Mode không yêu cầu quyền GPS)
      double lat = DemoConfig.currentSimulatedPosition.latitude;
      double lng = DemoConfig.currentSimulatedPosition.longitude;

      if (!DemoConfig.isDemoMode) {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        lat = position.latitude;
        lng = position.longitude;
      }

      // Lấy số điện thoại chuẩn từ Storage
      final phoneNumber = StorageService.to.getPhoneNumber() ?? 
                          StorageService.to.getUsername() ?? '';

      final result = await _sosRepo.createSosAlert(
        lat: lat,
        lng: lng,
        note: note,
        phoneNumber: phoneNumber,
      );

      activeSosId.value = result.sosId;
      
      // Đóng dialog trước khi chuyển màn hình
      if (Get.isDialogOpen!) Get.back(); 
      
      Get.to(() => SosActiveScreen());
      CustomAlert.showSuccess('Đã phát tín hiệu cứu hộ!');

    } catch (e) {
      CustomAlert.showError('Không thể phát tín hiệu: $e');
    } finally {
      isLoading.value = false;
      noteController.clear(); 
    }
  }

  /// Hàm Hủy và Hoàn thành (Cũng không cần dọn Cache nữa)
  Future<void> cancelActiveSos() async {
    try {
      isLoading.value = true;
      if (activeSosId.value.isNotEmpty) {
        await _sosRepo.cancelSosAlert(activeSosId.value);
      }

      SosStreamService.to.sosList.removeWhere((sos) => sos.sosId == activeSosId.value);
      CustomAlert.showSuccess('Đã hủy tín hiệu cứu hộ');
    } catch (e) {
      CustomAlert.showError('Lỗi: $e');
    } finally {
      activeSosId.value = ''; 
      isLoading.value = false;
      Get.back();
    }
  }

  /// Hàm chạy khi người dùng báo cáo Đã giải quyết (Nút chữ V)
  Future<void> resolveActiveSos() async {
    try {
      isLoading.value = true;
      if (activeSosId.value.isNotEmpty) {
        await _sosRepo.resolveSosAlert(activeSosId.value);
      }

      SosStreamService.to.sosList.removeWhere((sos) => sos.sosId == activeSosId.value);
      CustomAlert.showSuccess('Sự cố của bạn đã được giải quyết!');
    } catch (e) {
      CustomAlert.showError('Lỗi khi cập nhật trạng thái : $e');
    } finally {
      activeSosId.value = '';
      isLoading.value = false;
      Get.back(); 
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
