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
import '../../dashboard/controllers/dashboard_controller.dart';
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
    checkAndRestoreActiveSos();
  }

  Future<void> onContinue() async {
    if (selectedOption.value == 0) {
      final String relativePhone = (StorageService.to.getRelativePhone() ?? '')
          .trim();

      if (relativePhone.isEmpty) {
        CustomAlert.showWarning('emergency_notification_mesg_1'.tr);
        return;
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
  Future<void> checkAndRestoreActiveSos({int? targetUserId}) async {
    try {
      final currentUserId = targetUserId ?? StorageService.to.getUserId();
      final currentPhone = (StorageService.to.getPhoneNumber() ?? '').trim();
      final currentUsername = (StorageService.to.getUsername() ?? '').trim();

      // Nếu chưa có ID tài khoản đăng nhập, dứt khoát không có active SOS của tài khoản
      if (currentUserId == null) {
        resetSosState();
        return;
      }

      // 1. Đọc cache phiên SOS gắn chặt theo currentUserId
      final cached = StorageService.to.getActiveSos(userId: currentUserId);

      // 2. Lấy danh sách SOS từ server
      List<SosResponseDTO> actives = [];
      bool serverSuccess = false;
      try {
        actives = await _sosRepo.getActiveSosAlerts();
        serverSuccess = true;
      } catch (e) {
        debugPrint('[SOS] Lỗi khi lấy danh sách SOS active từ server: $e');
      }

      SosResponseDTO? matched;
      if (serverSuccess) {
        for (final sos in actives) {
          bool isMyAlert = false;

          // 1. So khớp ID người dùng (Ưu tiên cao nhất)
          if (sos.userId != null) {
            if (sos.userId == currentUserId) {
              isMyAlert = true;
            } else {
              // Nếu sos có userId rõ ràng và khác currentUserId -> Chắc chắn của người khác!
              continue;
            }
          }
          // 2. So khớp theo ID lượt SOS NẾU cache thuộc về chính tài khoản này
          else if (cached != null &&
              cached['sosId'] != null &&
              sos.sosId == cached['sosId']) {
            isMyAlert = true;
          }
          // 3. So khớp Username (chỉ khi sos không có userId)
          else if (currentUsername.isNotEmpty &&
              sos.username != null &&
              sos.username!.isNotEmpty &&
              sos.username == currentUsername) {
            isMyAlert = true;
          }
          // 4. So khớp Số điện thoại gửi kèm
          else if (currentPhone.isNotEmpty &&
              sos.phoneNumber != null &&
              sos.phoneNumber!.trim().isNotEmpty &&
              sos.phoneNumber!.trim() == currentPhone) {
            isMyAlert = true;
          }

          if (isMyAlert) {
            matched = sos;
            break;
          }
        }
      }

      if (matched != null) {
        activeSosId.value = matched.sosId;
        activeSosLat.value = matched.latitude ??
            (cached != null ? (cached['lat'] as num).toDouble() : 0.0);
        activeSosLng.value = matched.longitude ??
            (cached != null ? (cached['lng'] as num).toDouble() : 0.0);
        activeSosNote.value = matched.note ??
            (cached != null ? (cached['note'] as String) : '');
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

        debugPrint(
          '🔄 Đã khôi phục thành công lượt SOS của tài khoản $currentUserId: ${matched.sosId} tại (${activeSosLat.value}, ${activeSosLng.value})',
        );
      } else if (serverSuccess) {
        // Server phản hồi thành công và tài khoản hiện tại KHÔNG có SOS nào đang hoạt động
        resetSosState();
        if (cached != null) {
          await StorageService.to.clearActiveSos(userId: currentUserId);
        }
      } else if (cached != null) {
        // Mạng lỗi nhưng trong cache của chính currentUserId có SOS hợp lệ
        activeSosId.value = cached['sosId'] ?? '';
        activeSosLat.value = (cached['lat'] as num?)?.toDouble() ?? 0.0;
        activeSosLng.value = (cached['lng'] as num?)?.toDouble() ?? 0.0;
        activeSosNote.value = cached['note'] ?? '';
        isSosActive.value = activeSosId.value.isNotEmpty;
        isSheetMinimized.value = true;
        debugPrint(
          '🔄 Khôi phục tạm từ cache cho tài khoản $currentUserId: ${activeSosId.value}',
        );
      } else {
        // Tài khoản hiện tại không có SOS nào
        resetSosState();
      }
    } catch (e) {
      debugPrint('Lỗi khi kiểm tra khôi phục SOS: $e');
      resetSosState();
    }
  }

  /// Kiểm tra dịch vụ vị trí, xin quyền và lấy tọa độ GPS an toàn kèm các lớp dự phòng
  Future<LatLng?> _resolveSosLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      CustomAlert.showError('map_location_service_disabled'.tr);
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        CustomAlert.showError('map_location_permission_denied'.tr);
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      CustomAlert.showError('map_location_permission_denied_forever'.tr);
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('[SOS] getCurrentPosition thất bại/timeout: $e');
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return LatLng(lastKnown.latitude, lastKnown.longitude);
      }
    } catch (e) {
      debugPrint('[SOS] getLastKnownPosition thất bại: $e');
    }

    if (Get.isRegistered<MapController>()) {
      final mapLoc = Get.find<MapController>().userLocation.value;
      if (mapLoc != null) {
        return mapLoc;
      }
    }

    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      final lat = dash.userLat.value;
      final lng = dash.userLng.value;
      if (dash.hasUserLocation && lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    CustomAlert.showError('cannot_get_location'.tr);
    return null;
  }

  /// Hàm chạy khi người dùng bấm "Phát tín hiệu"
  Future<void> sendSosAlert() async {
    if (isLoading.value) return;

    final note = noteController.text.trim();
    if (note.isEmpty) {
      CustomAlert.showWarning('emergency_note_empty_warning'.tr);
      return;
    }

    try {
      isLoading.value = true;

      // 1. Lấy tọa độ GPS an toàn (có kiểm tra quyền, timeout và fallback)
      final coords = await _resolveSosLocation();
      if (coords == null) return;

      // 2. Lấy thông tin tài khoản hiện tại từ Storage (chỉ gửi SĐT thật, không dùng username thay thế)
      final currentPhone = (StorageService.to.getPhoneNumber() ?? '').trim();
      final currentUsername = (StorageService.to.getUsername() ?? '').trim();
      final currentUserId = StorageService.to.getUserId();
      final String? phoneNumber = currentPhone.isNotEmpty ? currentPhone : null;

      // 3. Gửi lên Server
      final result = await _sosRepo.createSosAlert(
        lat: coords.latitude,
        lng: coords.longitude,
        note: note,
        phoneNumber: phoneNumber,
      );

      // 4. Cập nhật state & đồng bộ vào stream/storage
      activeSosId.value = result.sosId;
      activeSosLat.value = coords.latitude;
      activeSosLng.value = coords.longitude;
      activeSosNote.value = note;
      isSheetMinimized.value = false;
      isSosActive.value = true;

      if (Get.isRegistered<SosStreamService>() && result.sosId.isNotEmpty) {
        final streamList = SosStreamService.to.sosList;
        final existingIdx = streamList.indexWhere(
          (s) => s.sosId == result.sosId,
        );
        if (existingIdx >= 0) {
          streamList[existingIdx] = result;
        } else {
          streamList.insert(0, result);
        }
      }

      await StorageService.to.saveActiveSos(
        sosId: result.sosId,
        lat: coords.latitude,
        lng: coords.longitude,
        note: note,
        userId: currentUserId,
        phoneNumber: currentPhone,
        username: currentUsername,
      );

      // Chỉ xóa ô nhập ghi chú sau khi phát tín hiệu thành công
      noteController.clear();

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

      // 8. Căn chỉnh camera bản đồ theo tọa độ SOS kèm offset của sheet
      if (Get.isRegistered<MapController>()) {
        Get.find<MapController>().centerOnActiveSos(
          isOffsetForSheet: true,
          zoom: 16.0,
          animated: true,
        );
      }
    } catch (e) {
      CustomAlert.showError('emergency_send_error'.trParams({'error': e.toString()}));
    } finally {
      isLoading.value = false;
    }
  }

  /// Đóng tín hiệu SOS (Duy nhất 1 nút bấm đóng/kết thúc SOS)
  Future<void> closeActiveSos() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      final id = activeSosId.value;
      if (id.isNotEmpty) {
        await _sosRepo.cancelSosAlert(id);
      }

      final currentUserId = StorageService.to.getUserId();
      if (Get.isRegistered<SosStreamService>()) {
        SosStreamService.to.sosList.removeWhere((sos) => sos.sosId == id);
      }
      await StorageService.to.clearActiveSos(userId: currentUserId);

      resetSosState();

      CustomAlert.showSuccess('emergency_closed_success'.tr);
    } catch (e) {
      CustomAlert.showError('emergency_close_error'.trParams({'error': e.toString()}));
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    noteController.dispose();
    super.onClose();
  }
}
