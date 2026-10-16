import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/storage_service.dart';
import '../../../widgets/custom_alert.dart';
import '../../../data/models/sos_model.dart';
import '../../../data/repositories/sos_repository.dart';
import '../../../data/services/sos_stream_service.dart';
import '../../../routes/app_pages.dart';
import '../../home/controllers/home_controller.dart';
import '../../map/controllers/map_controller.dart';

class EmergencyController extends GetxController {
  static EmergencyController get to => Get.find<EmergencyController>();

  var selectedOption = 0.obs;
  var isLoading = false.obs;

  // Trạng thái phát tín hiệu SOS
  var activeSosId = ''.obs;
  var isSosActive = false.obs;
  var isSheetMinimized = false.obs;
  var activeSosLat = 0.0.obs;
  var activeSosLng = 0.0.obs;
  var activeSosNote = ''.obs;

  final TextEditingController noteController = TextEditingController();
  final SosRepository _sosRepo = SosRepository();

  void selectOption(int index) {
    selectedOption.value = index;
  }

  @override
  void onInit() {
    super.onInit();
    // Vừa mở app lên là kiểm tra phiên SOS cục bộ & trên server
    _checkAndRestoreActiveSos();
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

  /// Reset toàn bộ trạng thái SOS (khi logout hoặc chuyển đổi tài khoản)
  void resetSosState() {
    activeSosId.value = '';
    isSosActive.value = false;
    isSheetMinimized.value = false;
    activeSosLat.value = 0.0;
    activeSosLng.value = 0.0;
    activeSosNote.value = '';
  }

  /// Tự động kiểm tra và khôi phục lượt SOS NẾU CHÍNH TÀI KHOẢN NÀY đang phát tín hiệu
  Future<void> _checkAndRestoreActiveSos() async {
    try {
      final currentUserId = StorageService.to.getUserId();
      final currentPhone = (StorageService.to.getPhoneNumber() ?? '').trim();
      final currentUsername = (StorageService.to.getUsername() ?? '').trim();

      // Nếu chưa có thông tin đăng nhập, không thể có active SOS của tài khoản
      if (currentUserId == null && currentPhone.isEmpty && currentUsername.isEmpty) {
        resetSosState();
        return;
      }

      final cached = StorageService.to.getActiveSos();

      // Kiểm tra xem dữ liệu trong cache có thực sự thuộc về tài khoản hiện tại không
      bool isCacheOwnedByMe = false;
      if (cached != null) {
        if (currentUserId != null && cached['userId'] != null) {
          isCacheOwnedByMe = (currentUserId == cached['userId']);
        } else if (currentPhone.isNotEmpty && cached['userPhone'] != null) {
          isCacheOwnedByMe = (currentPhone == cached['userPhone']);
        } else if (currentUsername.isNotEmpty && cached['username'] != null) {
          isCacheOwnedByMe = (currentUsername == cached['username']);
        }
      }

      // Nếu cache tồn tại nhưng thuộc về tài khoản khác (do đăng xuất trước đó), dọn dẹp ngay
      if (cached != null && !isCacheOwnedByMe) {
        await StorageService.to.clearActiveSos();
      }

      final actives = await _sosRepo.getActiveSosAlerts();

      SosResponseDTO? matched;
      for (final sos in actives) {
        bool isMyAlert = false;

        // 1. So khớp ID người dùng (nếu backend trả về)
        if (currentUserId != null && sos.userId != null && sos.userId == currentUserId) {
          isMyAlert = true;
        }
        // 2. So khớp Username (nếu backend trả về)
        else if (currentUsername.isNotEmpty && sos.username != null && sos.username!.isNotEmpty && sos.username == currentUsername) {
          isMyAlert = true;
        }
        // 3. So khớp Số điện thoại / Username gửi kèm (phoneNumber lưu SĐT hoặc username lúc tạo)
        else if (sos.phoneNumber != null && sos.phoneNumber!.isNotEmpty) {
          final sosPhone = sos.phoneNumber!.trim();
          if (currentPhone.isNotEmpty && sosPhone == currentPhone) {
            isMyAlert = true;
          } else if (currentUsername.isNotEmpty && sosPhone == currentUsername) {
            isMyAlert = true;
          }
        }
        // 4. So khớp theo ID lượt SOS NẾU cache đó đã được xác thực thuộc về chính tài khoản này
        else if (isCacheOwnedByMe && cached != null && sos.sosId == cached['sosId']) {
          isMyAlert = true;
        }

        if (isMyAlert) {
          matched = sos;
          break;
        }
      }

      if (matched != null) {
        activeSosId.value = matched.sosId;
        activeSosLat.value = matched.latitude ?? (isCacheOwnedByMe && cached != null ? (cached['lat'] as double) : 0.0);
        activeSosLng.value = matched.longitude ?? (isCacheOwnedByMe && cached != null ? (cached['lng'] as double) : 0.0);
        activeSosNote.value = matched.note ?? (isCacheOwnedByMe && cached != null ? (cached['note'] as String) : '');
        isSosActive.value = true;
        isSheetMinimized.value = true;

        await StorageService.to.saveActiveSos(
          sosId: matched.sosId,
          lat: activeSosLat.value,
          lng: activeSosLng.value,
          note: activeSosNote.value,
          userId: currentUserId,
          phoneNumber: currentPhone,
          username: currentUsername,
        );

        debugPrint('🔄 Đã khôi phục thành công lượt SOS của tài khoản: ${matched.sosId} tại (${activeSosLat.value}, ${activeSosLng.value})');
      } else {
        // Tài khoản hiện tại không có SOS nào đang hoạt động
        resetSosState();
        if (isCacheOwnedByMe) {
          await StorageService.to.clearActiveSos();
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra khôi phục SOS: $e');
    }
  }

  /// Hàm chạy khi người dùng bấm "Phát tín hiệu"
  Future<void> sendSosAlert() async {
    final note = noteController.text.trim();
    if (note.isEmpty) {
      CustomAlert.showWarning('Vui lòng nhập chi tiết sự cố');
      return;
    }

    try {
      isLoading.value = true;
      
      // 1. Lấy tọa độ GPS chính xác
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      // 2. Lấy thông tin tài khoản hiện tại từ Storage
      final currentPhone = StorageService.to.getPhoneNumber() ?? '';
      final currentUsername = StorageService.to.getUsername() ?? '';
      final currentUserId = StorageService.to.getUserId();
      final phoneNumber = currentPhone.isNotEmpty ? currentPhone : currentUsername;

      // 3. Gửi lên Server
      final result = await _sosRepo.createSosAlert(
        lat: position.latitude,
        lng: position.longitude,
        note: note,
        phoneNumber: phoneNumber,
      );

      // 4. Cập nhật state & lưu Storage gắn với tài khoản của người dùng
      activeSosId.value = result.sosId;
      activeSosLat.value = position.latitude;
      activeSosLng.value = position.longitude;
      activeSosNote.value = note;
      isSosActive.value = true;
      isSheetMinimized.value = false;

      await StorageService.to.saveActiveSos(
        sosId: result.sosId,
        lat: position.latitude,
        lng: position.longitude,
        note: note,
        userId: currentUserId,
        phoneNumber: currentPhone,
        username: currentUsername,
      );

      // 5. Đóng dialog nhập ghi chú
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // 6. Quay về Home nếu đang ở màn hình khác
      if (Get.currentRoute != Routes.HOME) {
        Get.until((route) => Get.currentRoute == Routes.HOME || route.isFirst);
      }

      // 7. Chuyển ngay sang tab Bản đồ (Map)
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().changeTab(1);
      }

      // 8. Di chuyển camera bản đồ đến đúng tọa độ GPS của người dùng
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().moveToLocation(
          LatLng(position.latitude, position.longitude),
          zoom: 16.0,
        );
      }
    } catch (e) {
      CustomAlert.showError('Không thể phát tín hiệu: $e');
    } finally {
      isLoading.value = false;
      noteController.clear(); 
    }
  }

  /// Đóng tín hiệu SOS (Duy nhất 1 nút bấm đóng/kết thúc SOS)
  Future<void> closeActiveSos() async {
    try {
      isLoading.value = true;
      final id = activeSosId.value;
      if (id.isNotEmpty) {
        await _sosRepo.cancelSosAlert(id);
      }

      SosStreamService.to.sosList.removeWhere((sos) => sos.sosId == id);
      await StorageService.to.clearActiveSos();

      isSosActive.value = false;
      isSheetMinimized.value = false;
      activeSosId.value = '';
      activeSosLat.value = 0.0;
      activeSosLng.value = 0.0;
      activeSosNote.value = '';

      CustomAlert.showSuccess('Đã đóng tín hiệu cứu hộ');
    } catch (e) {
      CustomAlert.showError('Lỗi khi đóng tín hiệu: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Tương thích ngược nếu còn lời gọi cũ
  Future<void> cancelActiveSos() => closeActiveSos();
  Future<void> resolveActiveSos() => closeActiveSos();

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
